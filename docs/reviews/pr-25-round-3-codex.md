# Review: PR #25 CI SHA pins and Dependabot

Date: 2026-07-28
Reviewed: PR #25 as a whole at `950394ae896e6fe967f821f0956ba0e8d7190e1e`, with focus on the round-3 correction in `.github/dependabot.yml` and `docs/ci-pin-maintenance.md`
Round: 3
Label applied: `approved-by-codex-agent`

## What Is Correct

The round-2 blocker is resolved. `.github/dependabot.yml` no longer claims
Dependabot will maintain the `PerlToolsTeam/github_workflows` SHA pins. The
replacement text is accurate: Dependabot can still scan GitHub Actions
dependencies in this repository, but the untagged path-based SHA pins in
`.github/workflows/ci.yml` require manual review.

I rechecked the relevant Dependabot behavior against the current
dependabot-core source. `github_actions/lib/dependabot/github_actions/update_checker.rb`
still has `latest_commit_sha` return early unless `latest_version_tag` exists,
and `PerlToolsTeam/github_workflows` currently has zero tags. That matches the
new comment and the maintenance doc.

Keeping Dependabot enabled is sensible rather than misleading. It remains able
to cover tagged GitHub Actions refs that appear directly in this repository's
workflows, while the comment explicitly excludes the pinned
`PerlToolsTeam/github_workflows` refs.

`docs/ci-pin-maintenance.md` now documents the important operational boundary:
the pin freezes the selected upstream repository files, not the tag-based
actions and container images those pinned files invoke. It also gives a
practical manual audit path and explicitly requires a green CI run before
advancing the shared pin.

The PR-wide workflow change still looks correct. The test job calls the pinned
`cpan-test` composite action directly so this repository can own
`strategy.fail-fast: false`, and the current PR head reports all CI cells green:
12 test matrix jobs plus coverage and perlcritic, with macOS and Windows cells
included.

## Blockers

None.

## What Needs Attention

The maintenance doc's "Not frozen" examples omit the two `actions/checkout@v7`
refs used by the pinned coverage and perlcritic workflows. The surrounding
statement is already correct because it says actions invoked inside the pinned
upstream files can drift, so this is not blocking, but adding `actions/checkout@v7`
to the example list would make the inventory complete.

The quarterly cadence is a human process, not an enforced control. That is an
acceptable tradeoff here because the PR now says so plainly, but whoever owns
these distributions should put the cadence somewhere actionable outside this
repository if they want it to happen reliably.

## Bloat / Non-Functional

None. The added maintenance documentation is proportionate to the operational
burden introduced by SHA-pinning an untagged third-party workflow repository.

## Recommendations

Optionally add `actions/checkout@v7` to the "Not frozen" example list in
`docs/ci-pin-maintenance.md` in a follow-up cleanup.

Keep the cross-repository SHA consistency rule. I verified the documented
`gh api` commands execute as written against `PerlToolsTeam/github_workflows`;
because upstream `main` is still the pinned `b4ba4e55` commit dated
2026-06-23, the "commits since" command currently returns no rows, which is the
expected result.

## Bottom Line

Approve. The false Dependabot-maintenance claim has been removed, the new docs
accurately explain both the manual upkeep requirement and the limits of the
pin, and the current CI evidence supports the workflow change.
