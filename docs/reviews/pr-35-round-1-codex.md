# Review: PR #35 Swedish source comment translation

Date: 2026-07-30
Reviewed: `lib/PDF/Reuse.pm` at `53a25b54aad54ada5896805f0a07932533a37dfa`
Round: 1
Label applied: `changes-requested`

## What Is Correct

The PR is limited to one file, `lib/PDF/Reuse.pm`, with a one-for-one comment translation shape: 103 added lines and 103 deleted lines.

I independently verified the no-code-change claim with a diff parser over `origin/master...HEAD`: for each changed line, the byte string before the first `#` is identical between the removed and added sides. The check reported 103 removed lines, 103 added lines, and 0 prefix mismatches.

The duplicated translations around the resource-dictionary reuse blocks are on parallel code paths. The `skrivSida` block at lines 927-934 and the `sidAnalys` block at lines 6636-6643 both check `%resurser`, reuse an existing identical resource object, and save the first 10 resource objects. A single rendering is appropriate in both places.

The duplicated tolerant-page comments in `prForm` and `prDocForm` also sit on parallel code paths. The same English rendering fits both contexts.

Leaving Swedish identifiers in place is the right scope call for this PR. Renaming identifiers in a 7000-line CPAN-shipped module would be a functional-risk change with little direct value for the comment-translation issue.

## Blockers

1. `lib/PDF/Reuse.pm:5072` translates the first half of the Swedish idiom incorrectly when read line-by-line. `Hängslen` is the braces/suspenders side, while `Svångrem` is the belt side. The current English split makes line 5072 say `# Belt`, which is the wrong word for that Swedish source line and is misleading as a standalone code comment. Prefer neutral comments such as `# Loop guard 1` and `# Loop guard 2, to avoid infinite loops`, or otherwise avoid splitting the English idiom across the two declarations.

## What Needs Attention

None beyond the blocker.

## Bloat / Non-Functional

None. The diff is 103 additions and 103 deletions, all in comment text, so it does not trigger the additive-change concern.

## Recommendations

Replace the split idiom at lines 5072-5073 with direct guard wording. That keeps the intent clear and avoids relying on an English idiom spread across two unrelated scalar declarations.

## Bottom Line

Revise before merge. The implementation is mechanically comment-only and the broad translation choices look sound, but the idiom at lines 5072-5073 should be corrected because this PR's core risk is a confidently wrong English comment.
