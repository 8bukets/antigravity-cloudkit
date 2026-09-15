---
name: daily-launch-prep
description: Daily autonomous pass over this repo to keep CI green and the codebase healthy. Runs unattended once a day via a scheduled Routine.
---

# Daily Launch Prep — antigravity-cloudkit

You are running unattended, once a day, with no memory of previous runs
beyond what is committed in this repository. `LAUNCH_CHECKLIST.md` at the
repo root is your memory — read it first, update it every run.

## What this repo is

An example Xcode project (Swift) demonstrating Core Data +
`NSPersistentCloudKitContainer`, `NSUbiquitousKeyValueStore`, and
`UIDocument` iCloud sync. It's a reference/template, not a monetizable
product — there is no "Product/business" category to track here, unlike
this org's other repos. Project generation uses XcodeGen (`project.yml`,
no committed `.xcodeproj`).

**This environment cannot build or run Swift/Xcode at all** — it's a
Linux sandbox with no `swift`/`swiftc`/`xcodebuild` toolchain. Anything
touching Swift source can only be validated by pushing and reading back
the GitHub Actions CI result (`Run tests` check) — never claim a Swift
change is verified without doing that.

## Hard guardrails — never cross these

1. **Never merge your own PRs, never push to the default branch
   directly.**
2. **Never commit secrets.**
3. **Don't blind-guess at CI infrastructure fixes.** A 2026-09-13/14 CI
   failure ("Test crashed with signal trap/abrt before establishing
   connection") went through 5+ rounds of speculative fixes before the
   real root cause was found (a `@FetchRequest` built against the
   abstract `NSManagedObject.entity()` instead of `Note.entity()` in
   `ContentView.swift`, fixed in commit `8012308`, confirmed green). If
   CI goes red again, root-cause it from the actual error/log — don't
   repeat the earlier blind-guessing pattern.

## Each run, in order

1. **Orient**: check the status of the most recent open PR (if any) and
   its latest CI run via the GitHub REST API (no MCP connector here —
   plain `curl` with `$GITHUB_TOKEN`). Read `LAUNCH_CHECKLIST.md`.
2. **If CI is red**: read the actual failure output
   (`GET /repos/8bukets/antigravity-cloudkit/actions/runs/{id}/jobs` then
   the job's logs) before touching anything. Fix the specific, evidenced
   cause. Push and re-check the resulting run before declaring it fixed.
3. **If CI is green**: do a light adversarial read of one Swift file for
   a genuine correctness bug (not a style nit) — this repo has had a real
   history of subtle bugs (invalid key-path syntax, wrong entity
   references, `Notification`/`.userInfo` misuse) that a careful read can
   still catch. If nothing concrete turns up, say so — don't manufacture
   a change.
4. **Update `LAUNCH_CHECKLIST.md`** with today's date.
5. **Ship it**: only for a real, evidenced fix — branch
   `daily-launch-prep/YYYY-MM-DD`, commit, push, open a PR via direct
   REST API (`https://api.github.com/repos/8bukets/antigravity-cloudkit/pulls`),
   base `main`. Note in the PR body that this environment can't run a
   local Swift build and the fix is validated only via the pushed CI run
   — link to it once available. End the PR body with
   `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.
6. **If there's nothing actionable, say so plainly** rather than forcing
   a change — for a small reference repo, most days will have nothing
   to do once CI is stable.

## Launch readiness categories (track in LAUNCH_CHECKLIST.md)

- **Reliability**: CI (`Run tests` GitHub Actions check) green on the
  default branch and on any open PR.
- **Security**: n/a beyond "no secrets committed" — no user data, no
  deployed service.
- **Infra**: XcodeGen-based project generation stays in sync with
  `project.yml`; no committed `.xcodeproj` drift.
