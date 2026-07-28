# Review: PR #25 CI re-enable Windows and macOS

Date: 2026-07-28
Reviewed: `.github/workflows/ci.yml`, PR #25, upstream `PerlToolsTeam/github_workflows` reusable workflow and composite action at `main` (`b4ba4e5553820e802da91d58eba295575945ad95`), PR run `30388392273`, at commit `bfe2a4f8792a713a27571c47a55efce289afc956`
Round: 1
Label applied: `approved-by-codex-agent`

## What Is Correct

The direct composite-action call is behaviorally equivalent to the reusable workflow for the tested path. The upstream reusable workflow only defines `workflow_call` inputs, builds the `os`/`perl` matrix from JSON, leaves `strategy.fail-fast` at GitHub's default, names the job, and then calls `PerlToolsTeam/github_workflows/.github/actions/cpan-test@main` with `perl_version`, `os`, and `testing_context`. The PR keeps the same action and same effective default `testing_context`, while adding the one thing the reusable workflow cannot expose: `fail-fast: false`.

Passing `os: ${{ matrix.os }}` is correct for the current upstream action. The action's conditionals use `startsWith(inputs.os, 'windows')`; the matrix value `windows-latest` matches that expectation, while `ubuntu-latest` and `macos-latest` correctly take the Unix branch.

Dropping an explicit `testing_context` does not change the effective behavior. The reusable workflow default is `'[ ]'`, and the composite action default is also `'[ ]'`.

The PR run is the right verification for this change. Run `30388392273` at commit `bfe2a4f8792a713a27571c47a55efce289afc956` passed all 12 `test` cells, plus `coverage` and `perlcritic`.

## Blockers

None.

## What Needs Attention

The green Windows run justifies saying the Windows failure is fixed upstream or no longer reproducible in the current upstream CI/toolchain path. It does not, by itself, prove which upstream commit fixed it. The PR body cites plausible matching `PerlToolsTeam/github_workflows` changes, but without bisecting or pin-testing the old/new upstream revisions, the exact-fix attribution remains an inference. That is acceptable for this CI re-enablement PR, but issue-closing language should avoid claiming more precision than was verified.

Calling the composite action directly is a small maintainability tradeoff. The reusable workflow is the public wrapper; the composite action is one layer lower and may be treated by upstream as a less stable interface. The comment in `.github/workflows/ci.yml` explains why the bypass exists, and current behavior is sound, so this is not a blocker. If upstream later adds a `fail_fast` input to `cpan-test.yml`, returning to the reusable workflow would reduce that coupling.

One inherited diagnostic weakness remains: the composite action names failure artifacts with `${{ github.run_id }}-${{ github.job }}`. In a matrix job, `${{ github.job }}` is the stable job id (`test` here), not the visible matrix name, so multiple failing cells in the same run may collide on artifact names. This is an upstream action issue already present through the reusable workflow, not a regression introduced by this PR.

## Bloat / Non-Functional

None. The workflow change is small and directly tied to the requirement to restore the full OS matrix while disabling fail-fast.

## Recommendations

Keep the workflow change as written.

When closing #9, phrase the conclusion as "verified fixed/no longer reproducible on the current upstream workflow path" unless someone bisects the upstream action history. The evidence supports re-enabling Windows; it does not require proving the exact upstream commit.

Consider opening an upstream issue or PR for matrix-unique artifact names in `PerlToolsTeam/github_workflows/.github/actions/cpan-test`, especially now that `fail-fast: false` can expose multiple simultaneous failures.

## Bottom Line

Approve. The direct composite-action call is a justified workaround for the reusable workflow's fixed `fail-fast` behavior, the inputs line up with the upstream action, default `testing_context` is preserved, and the full 12-cell CI run is the relevant verification. The remaining concerns are maintainability and diagnostic precision, not merge blockers.
