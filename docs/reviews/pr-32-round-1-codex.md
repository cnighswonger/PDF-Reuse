# Review: PR #32 stale source-derived cache invalidation

Date: 2026-07-29
Reviewed: PR #32 branch `fix/stale-form-caches` at `af09c6d63040d2a80da08a7e7cabbaad92ed3e17`
Round: 1
Label applied: changes-requested

## What Is Correct

The invalidation point is the right place for module-owned rewrites. `prFile()` has just opened the named output for write, and the per-document state reset follows immediately, so broadening the existing #26 invalidation there avoids deleting entries during an in-flight form/image/font emission path.

Sweeping `%form`, `%image`, and `%intAct` is necessary. Those hashes survive across `prFile()` calls and are keyed from `$infil . '_' . $sidnr` or `$iSource`, so keeping them after a same-name rewrite preserves stale BBox, image dimensions/object numbers, and interactive-form data.

Sweeping `%fontSource` is also directionally correct. `findFont()` uses `foSOURCE` to split back to a source filename/page and calls `extractObject()` when reusing a non-standard font, so a stale `foSOURCE` can point at bytes that no longer exist or now describe a different object.

I did not find another package-level source-derived cache that survives `prFile()` and needs this same treatment. `%knownToFile`, `%objRef`, the `%sid*` resource maps, `%resurser`, `%fields`, `%script`, `%initScript`, `%links`, `%prefs`, `%embedded`, `%dummy`, and `%nyaFunk` are either document-local and reset from `prFile()`/page emission paths or are not keyed by the source filename in a way that survives the boundary being fixed here.

Local verification passed with the requested command:

```text
PERL5LIB=~/perl5/lib/perl5 perl Makefile.PL && PERL5LIB=~/perl5/lib/perl5 make && PERL5LIB=~/perl5/lib/perl5 make test
Files=3, Tests=37, Result: PASS
```

## Blockers

1. `lib/PDF/Reuse.pm:4475` / `lib/PDF/Reuse.pm:4492` - The raw `$fil . '_'` prefix match can delete `%fontSource` entries for an unrelated source file, and for that cache the consequence is not limited to a needless re-parse. For example, rewriting `t.pdf` builds prefix `t.pdf_`, which also matches a cached `foSOURCE` value such as `t.pdf_backup_1`. If that entry is deleted, the next `prFile()` has already cleared `%font`, and a later `prFont($embedded_font_name)` no longer has the surviving `%fontSource` entry that `findFont()` needs to re-extract the embedded font. It can then fall through the "font not found" path and render with the standard/default font instead. Please anchor the scan on the page-number component, e.g. match `\A\Q$fil\E_\d+(?:_|$)` for the source-derived keys/values, with the existing `Ig:` prefix handled explicitly. That preserves regex-metacharacter safety while avoiding sibling filename collisions.

## What Needs Attention

The new regression covers the main stale BBox/mtime failure and confirms unchanged templates keep their cache. It does not cover the new `%fontSource` sweep. Once the prefix matching is anchored, add either a direct cache-level regression for the collision or a behavioral font reuse test if the fixture burden is acceptable.

## Bloat / Non-Functional

None. The helper is appropriately small for a load-bearing cache-lifetime change and replaces the previous inline deletes instead of duplicating them.

## Recommendations

Use one shared predicate for source-key matching so `%form`, `%intAct`, `%image`, `%knownToFile`, and `%fontSource` cannot drift. The important invariant is "filename exactly, then underscore, then page number, then either end-of-key or the next underscore-delimited component."

Keep deleting the full `%fontSource` entry once it is exactly matched. Preserving `foORIGINALNR` while clearing only `foSOURCE` would leave a half-valid record whose original object number still came from the old source.

Leaving ref-valued `$utfil` out of this sweep is correct. Ref outputs do not truncate a named file, and ref-valued inputs are materialized as temp files for parsing rather than invalidating a caller-visible source path.

## Bottom Line

Revise before merge. The invalidation site and cache set are right, but the unanchored prefix match is too broad for `%fontSource` and can silently change later font rendering for a different source file whose name collides with the rewritten filename prefix.
