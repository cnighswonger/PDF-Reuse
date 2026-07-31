# Review: PR 36 reuseComponent_pl ASCII escape

Date: 2026-07-31
Reviewed: `lib/PDF/Util/reuseComponent_pl` and PR rationale at `5b62f4df99a47ea56f55c35b2e11aec396ce8b86`
Round: 1
Label applied: `changes-requested`

## What Is Correct

The one-line source edit in `lib/PDF/Util/reuseComponent_pl:168` is the right narrow scope for issue #33. It changes only the literal source spelling of the final `0xb4` byte to `\264`, keeps the existing neighbouring octal-escape style, and does not introduce unrelated modernization or cleanup.

I independently verified the behavioural path:

- Perl does not interpolate `\264` in a single-quoted string; the new argument reaching `prText()` contains literal bytes `5c 32 36 34`.
- `PDF::Reuse::prText()` escapes only `(` and `)` on the normal literal-string path, so the backslash reaches the PDF content stream.
- Decoding the old and new PDF literal-string operands using PDF string escape rules yields identical bytes:
  `6162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7ec5c4d6e5e4f65b5d5e5fb460`.
- The `[\]^_` run is unchanged. In Perl single-quoted strings, `\]` remains two bytes, `5c 5d`; it is not consumed by Perl.
- Generated old and new PDFs have valid xref tables and valid stream `/Length` values. The size delta is explained by emitting `\264` as four content-stream bytes instead of raw `0xb4`.
- `perl Makefile.PL && make test` passes: 3 test files, 40 tests.
- A repository byte scan found no remaining Latin-1 source file. The remaining high bytes are UTF-8 in docs/review artifacts and `t/Reuse.t` test data, consistent with the PR's stated scope.

## Blockers

The rationale currently makes a false layer-boundary claim: it says the old and new string literals are byte-identical when Perl evaluates them, and says the literal reaching `prText()` is unchanged. That is not correct for this exact line. The old evaluated Perl string contains raw `0xb4`; the new evaluated Perl string contains literal `\264` bytes. They become equivalent only later, when a PDF reader resolves the PDF literal-string octal escape.

This is blocking because the correctness of the PR rests on that layer distinction. The code change is good, but the durable rationale should not record the wrong proof. Update the PR-facing rationale and, if the commit message will be preserved in merge history, correct that too before merge.

## What Needs Attention

None beyond the blocker.

## Bloat / Non-Functional

None. The diff is `+1/-1`, with no abstraction or cleanup churn.

## Recommendations

Replace the verification/rationale wording with the precise claim: Perl leaves `\264` literal in the single-quoted string, `prText()` passes that backslash sequence through, and PDF literal-string decoding renders it as byte `0xb4`. Avoid saying the evaluated Perl strings are byte-identical.

## Bottom Line

Revise the rationale, then this should be approvable. The source edit itself is narrow and behaviour-preserving, and the generated PDF structure checks out.
