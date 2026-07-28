# Review: PR #25 CI SHA pins and Dependabot

Date: 2026-07-28
Reviewed: PR #25 as a whole, with focus on `.github/dependabot.yml` and the second commit `3b9a72bf7d637826971ab6309348029664d68b04`
Round: 2
Label applied: `changes-requested`

## What Is Correct

The first commit's matrix change still looks sound. The direct call to the `cpan-test` composite action is the only way this PR gets `strategy.fail-fast: false`, and the current head run passed all 12 matrix cells plus coverage and perlcritic.

`directory: "/"` is the right Dependabot location for workflow scanning. Dependabot-core special-cases `/` to scan `.github/workflows/` ([file_fetcher.rb](https://github.com/dependabot/dependabot-core/blob/main/github_actions/lib/dependabot/github_actions/file_fetcher.rb#L67-L84)), and its parser explicitly recognizes reusable workflow paths under `.github/workflows/*.yml` ([file_parser.rb](https://github.com/dependabot/dependabot-core/blob/main/github_actions/lib/dependabot/github_actions/file_parser.rb#L106-L111)). GitHub's docs also state that Dependabot can keep both actions and reusable workflows up to date.

Pinning `PerlToolsTeam/github_workflows` to the measured-good commit is a real improvement over `@main` for the direct upstream workflow/action source. It prevents a future change in that repository from silently changing this repository's CI behavior.

## Blockers

The Dependabot maintenance claim is not reliable for these pins. `.github/dependabot.yml:4` says Dependabot keeps the SHA pins current, but all three refs in `.github/workflows/ci.yml:24`, `.github/workflows/ci.yml:30`, and `.github/workflows/ci.yml:33` point to path-based dependencies in `PerlToolsTeam/github_workflows`, and that upstream repository has no tags. Current Dependabot-core first looks for a latest tag before returning a replacement commit for a SHA-pinned GitHub Actions dependency ([update_checker.rb](https://github.com/dependabot/dependabot-core/blob/main/github_actions/lib/dependabot/github_actions/update_checker.rb#L157-L167)); if there is no tag, it returns no update. A current upstream issue reproduces the same failure shape for an untagged SHA-pinned path-based action: Dependabot opens no PR ([dependabot-core#15577](https://github.com/dependabot/dependabot-core/issues/15577)). Because `PerlToolsTeam/github_workflows` has zero tags, the added Dependabot config is likely inert for the exact dependency form this PR introduces. That defeats the stated "pin but keep current" rationale.

## What Needs Attention

The inline `# main @ 2026-06-23` comments will not be maintained in the way the PR implies. GitHub documents same-line comment updates for action version documentation, and Dependabot-core only rewrites a comment when it can match a previous semver tag for the old SHA and a new semver tag for the new SHA ([file_updater.rb](https://github.com/dependabot/dependabot-core/blob/main/github_actions/lib/dependabot/github_actions/file_updater.rb#L71-L115)). These comments are custom branch/date notes, and the upstream repository has no tags, so they would either remain unchanged if a SHA rewrite somehow happened or be ignored because no rewrite is produced. That makes them easy to turn into stale misinformation.

Pinning `cpan-coverage.yml` and `cpan-perlcritic.yml` does not make those jobs reproducible end-to-end. The pinned workflows currently run `davorg/perl-coveralls:latest` and `davorg/perl-perlcritic` containers, and Dependabot-core does not update Docker container action references in GitHub Actions workflows. The pin still freezes the workflow file itself, but the container image behind the job can drift independently of this repo. The PR/commit rationale should narrow the claim, or the upstream workflows should pin image digests if true reproducibility is the requirement.

The composite action pin freezes the action file at `b4ba4e55`, but not every action it invokes. At that commit the composite action still uses `actions/checkout@v5`, `shogo82148/actions-setup-perl@v1`, `ilammy/msvc-dev-cmd@v1`, and `actions/upload-artifact@v5`. Those refs remain tag-based and can move if their maintainers move tags. That is not a regression from `@main`, but it means the pin is a boundary around `PerlToolsTeam/github_workflows`, not a full CI dependency lock.

## Bloat / Non-Functional

None. The change is small. The issue is not over-engineering; it is that the automation chosen to avoid stale pins likely does not operate on this untagged upstream dependency.

## Recommendations

Do not merge the second commit as-is. Pick one of these before approval: have `PerlToolsTeam/github_workflows` publish semver tags and pin to tag-associated SHAs so Dependabot can advance them; replace Dependabot with a tool/workflow proven to update untagged path-based SHA refs; or keep the SHA pins but remove the "Dependabot keeps these current" claim and accept/manual-document that the pins must be audited periodically.

If the intended guarantee is only "freeze the shared workflow repo, not every transitive CI input," say that explicitly in the commit/PR rationale. If the intended guarantee is stronger reproducibility, also address the Docker `latest` containers and tag-based actions inside the pinned upstream files.

## Bottom Line

Request changes. The first commit remains approvable, but the unreviewed second commit adds a maintenance mechanism that likely does not update the newly pinned untagged path-based refs. That leaves these five repositories with silently rotting CI pins while the comments imply automated freshness.
