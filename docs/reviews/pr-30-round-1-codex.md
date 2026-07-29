# Review: PR #30 TrueType ToUnicode CMap

Date: 2026-07-29
Reviewed: PR #30 as a whole at `3ae8cdf2ebfb8ab64107eb5309ce0774f960e6ea`, with focus on `lib/PDF/Reuse.pm` and `t/regression.t`
Round: 1
Label applied: `approved-by-codex-agent`

## What Is Correct

The `prEnd()` placement is correct. `prEnd()` first flushes any pending content
stream via `skrivSida()`, writes the page tree via `skrivUtNoder()`, then runs
`PDF::Reuse::TTFont::attach_tounicode($docProxy)` before
`$docProxy->write_objects`. That is the first point where all calls to
`Text::PDF::TTFont0::out_text()` have marked the subset vector for placed text,
and it is still before `Text::PDF::TTFont0::outobjdeep()` freezes and writes the
font objects. I found no other call path that writes `DocProxy` objects outside
this block.

The idempotency guard is sufficient for the reachable lifecycle. A normal
`prEnd()` writes the `DocProxy` objects, releases the `Text::PDF::TTFont0`
instances, and undefines `$docProxy`, so a second `prEnd()` on the same completed
document cannot reattach anything. If `attach_tounicode()` were called twice
before writing, `next if $ttfont->{'ToUnicode'}` prevents allocating duplicate
CMap objects for already-attached fonts.

The mapping source matches the way this wrapper emits text. `out_text()` uses
`$font->{'cmap'}->ms_lookup($unicode)` to produce two-byte glyph IDs in the
content stream; `Font::TTF::Cmap::reverse()` reverses the same preferred
Microsoft Unicode cmap selected by `find_ms()`. The resulting `$rev[$gid]`
index is therefore the correct key for a Type0 `/Identity-H` font whose content
bytes are original glyph IDs. The implementation also correctly filters on the
completed `' subvec'` so the ToUnicode map covers used text glyphs rather than
the whole font.

The generated CMap shape is appropriate for a ToUnicode CMap. `/CIDSystemInfo`
uses the conventional Adobe/UCS identity for Unicode mapping, `/CMapType 2` is
present, the codespace range covers the two-byte codes emitted by this module,
and the trailer uses `currentdict`. The `beginbfchar` chunking arithmetic is
right: full 100-entry sections declare 100, and the final partial section
declares `$total % 100` when non-zero. The local sample emitted 13 entries with
a matching section count, and the PR author's 158-glyph verification exercises
the 100 + 58 case.

Leaving the CMap stream uncompressed is acceptable. PDF stream compression is
not required for validity, and keeping this small diagnostic stream readable is
a reasonable tradeoff. The existing `Text::PDF::Dict::outobjdeep()` path writes
the correct `/Length` for an unfiltered stream.

The tests are focused on the regression surface: TrueType output now contains a
`/ToUnicode` reference, a `beginbfchar` mapping, the corrected `currentdict`
trailer, and internally consistent section counts. The second commit fixes a
real CI blind spot by making those assertions execute on macOS and Windows when
a readable TTF is present, while keeping the test skippable on fontless systems.

## Blockers

None.

## What Needs Attention

The `eval { $cmap->read->reverse }` boundary deliberately degrades to "no
ToUnicode" if a font lacks a usable Unicode cmap or the cmap reader fails. That
matches the existing best-effort nature of optional font extraction support, but
it also means a malformed font can silently lose search/copy support rather
than failing document generation. I do not consider that blocking because
`prTTFont()` can already operate with externally supplied font files and the
old behavior was no ToUnicode at all.

The regression test proves CMap presence and section consistency, not actual
text extraction. The PR body and comment provide independent `pdftotext` and
`mutool` evidence, and I reproduced that locally, so this is acceptable for this
round. A future test that uses an installed extractor when available would make
the behavior check stronger, but it should remain optional to avoid adding a new
hard runtime dependency.

`Font::TTF::Cmap::reverse()` returns one Unicode code point per glyph unless
called with `array => 1`. That is consistent with the text path here, which does
not perform shaping or ligature substitution, but it means glyphs that are only
representable as multi-code-point Unicode sequences are outside this change's
scope.

## Bloat / Non-Functional

None. The implementation is a narrowly scoped helper in the existing
`PDF::Reuse::TTFont` wrapper, adds one object only for embedded TrueType fonts,
and avoids carrying a monkey-patched copy of upstream serialization code. The
new uncompressed CMap is small and proportional to the used subset.

## Recommendations

Keep the attachment in `prEnd()` immediately before `write_objects`; moving it
earlier risks an incomplete subset vector, and moving it later misses object
serialization.

Keep the `isa` guard defensive. `DocProxy` can cache multiple Text::PDF object
types, and this helper should only alter `Text::PDF::TTFont0` dictionaries.

Consider, as a future non-blocking hardening step, validating `utf16be_hex()`
against Unicode scalar bounds if a real-world font ever exposes cmap values
outside `0 .. 0x10FFFF` or surrogate code points. I found no evidence that the
selected Microsoft Unicode cmap path returns anything other than numeric code
point values for normal fonts.

## Bottom Line

Approve. The change is load-bearing, but the object lifecycle, glyph-to-Unicode
mapping, CMap syntax, idempotency guard, and regression coverage all line up
with the existing `prTTFont` architecture. I found no blocking defects.
