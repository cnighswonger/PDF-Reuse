# Review: PR #32 stale source-derived cache invalidation

Date: 2026-07-29
Reviewed: PR #32 branch `fix/stale-form-caches` at `d6fa46907993bc6a76eb4639bc28ca354b6e5744`
Round: 2
Label applied: approved-by-codex-agent

## What Is Correct

The round-1 blocker is resolved. `dropSourceCaches()` now matches source-derived keys with `qr/\A\Q$fil\E_\d+(?:_|\z)/`, which preserves entries for sibling filenames such as `t.pdf_backup_1` when rewriting `t.pdf`, while still sweeping the rewritten file's own `t.pdf_1` and `t.pdf_1_2` entries.

The anchor is correct for the cache shapes this PR sweeps. `%form` and `%intAct` use `$file_$page`; `%image` uses `$file_$page_$image`; `%fontSource` stores `$file_$page` in `foSOURCE`; and `%knownToFile` stores both `$file_$page` and `Ig:$file_$page_$image` for these form/image paths. I did not find a swept source-derived key where the page component is followed by anything other than an underscore or end-of-string.

The `%fontSource` handling now avoids the user-visible failure from round 1. Deleting only entries whose `foSOURCE` belongs to the rewritten file keeps embedded-font provenance for sibling files intact, so `findFont()` can still re-extract those fonts after `prFile()` clears `%font`.

The new cache-level collision regression is sufficient for this fix. It directly pins the ownership invariant that caused the blocker: a rewrite of the shorter filename sweeps the shorter file's cached `%form` entries and preserves the sibling filename's entries. A behavioral embedded-font fixture would add confidence for the downstream symptom, but it is not necessary to prove this matcher fix.

Local verification passed with the requested command:

```text
PERL5LIB=~/perl5/lib/perl5 perl Makefile.PL && PERL5LIB=~/perl5/lib/perl5 make && PERL5LIB=~/perl5/lib/perl5 make test
Files=3, Tests=40, Result: PASS
```

GitHub CI at `d6fa46907993bc6a76eb4639bc28ca354b6e5744` shows the 14 expected CI jobs successful.

## Blockers

None.

## What Needs Attention

The `%knownToFile` `Ig:` prefix remains an ambiguous legacy key shape: a form source literally named with an `Ig:` prefix can resemble the image-cache variant for the same spelling without `Ig:`. The current prefix-stripping approach does not introduce a new class of practical failure for this PR, because `%knownToFile` false positives only lose a name mapping while `%form`, `%image`, and `%fontSource` use the anchored owned-source test directly. A future structural cleanup could make the key type explicit, but that is outside this fix.

The comments added around `dropSourceCaches()` are longer than this code usually needs, but they document the non-obvious cache lifetime and font failure mode that caused the blocker. I would keep them for this load-bearing cache invalidation path.

## Bloat / Non-Functional

None. The implementation remains a single helper with direct scans over the affected package hashes. The added regression is narrow and targeted to the reviewed collision.

## Recommendations

Do not require the behavioral embedded-font test for this PR. If embedded-font fixtures are added later, they should cover the broader `%fontSource` reuse behavior rather than just re-proving the filename matcher.

If `%knownToFile` is revisited in a later cleanup, split form and image provenance into distinct keys or hashes instead of encoding the type as an `Ig:` string prefix.

## Bottom Line

Approve. The blocker is fixed, the anchored matcher is correct for the source-derived key shapes this PR invalidates, and the regression covers the cache ownership invariant without adding unnecessary fixture burden.
