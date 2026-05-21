# Changelog canon — Keep a Changelog 1.1 + SemVer 2.0

The canonical reference for the `CHANGELOG.md` file. Load this when the user asks "where do I document this user-visible change?", "do we need a changelog?", or "what version should we bump to?"

A changelog is **for humans, not machines**. It records what changed in each release, grouped by intent, in reverse-chronological order. It is not a commit log, not a release-notes blog post, and not a marketing summary.

Upstream specs:

- [keepachangelog.com/en/1.1.0](https://keepachangelog.com/en/1.1.0/) — Keep a Changelog 1.1 (the file format).
- [semver.org/spec/v2.0.0.html](https://semver.org/spec/v2.0.0.html) — Semantic Versioning 2.0.0 (the version-number contract that the changelog reports against).

## File location and shape

- Single file, at the repo root: `CHANGELOG.md`.
- Reverse-chronological — the newest release appears at the top, immediately below the `## [Unreleased]` block.
- An `## [Unreleased]` section is **always present at the top**, even when empty. It accumulates entries between releases; on release, it is renamed to the version being shipped and a fresh empty `## [Unreleased]` is created above it.
- Every released version block carries an ISO 8601 date in the heading: `## [1.4.0] - 2026-05-21`.
- Released sections are **never edited** — fix mistakes by adding a follow-up entry in the next release, not by rewriting history.

## The six categories — and only six

Keep a Changelog defines exactly six entry categories. Do not invent new ones, do not split them, do not rename them.

| Category       | Use for                                                                       |
|----------------|-------------------------------------------------------------------------------|
| `Added`        | New features visible to a user of the API / CLI / UI.                         |
| `Changed`      | Changes in existing functionality (behavior, output, signature).              |
| `Deprecated`   | Soon-to-be-removed features. Still works, but flagged for users to migrate.   |
| `Removed`      | Features removed in this release.                                             |
| `Fixed`        | Bug fixes.                                                                    |
| `Security`     | Vulnerabilities addressed. Note the CVE / advisory ID if one exists.          |

If an entry does not fit one of these six, it is probably not a changelog entry — it is internal refactoring, a tooling change, or a developer-process note, none of which belong here.

## SemVer cross-reference

The category an entry lands in determines the version bump:

| Changelog category    | SemVer bump                                                                                |
|-----------------------|--------------------------------------------------------------------------------------------|
| `Added`               | MINOR — backwards-compatible feature.                                                      |
| `Changed` (breaking)  | MAJOR — backwards-incompatible behavior change.                                            |
| `Changed` (non-breaking) | MINOR — typically — when behavior changes but the contract holds.                       |
| `Deprecated`          | MINOR — the feature still works; deprecation flags a future MAJOR removal.                 |
| `Removed`             | MAJOR — anything removed is a breaking change.                                             |
| `Fixed`               | PATCH — typically — unless the fix changes a documented contract (then MINOR or MAJOR).    |
| `Security`            | PATCH — typically — but escalate if the fix breaks the contract.                           |

The rule of thumb: **MAJOR for breaking, MINOR for new, PATCH for fixes.** When in doubt, ask "does an existing caller need to change anything?" If yes, MAJOR. If they can just upgrade, MINOR or PATCH.

## Canonical example

```md
# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog 1.1](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Retry budget on the queue consumer.

## [1.4.0] - 2026-05-21

### Added
- `--dry-run` flag on the migrate command.

### Changed
- Logging now emits structured JSON by default.

### Deprecated
- The `--legacy-output` flag. Removal scheduled for 2.0.0.

### Fixed
- Race condition in the cache warmer (#412).

## [1.3.1] - 2026-04-30

### Security
- Upgraded dependency X to address GHSA-xxxx-yyyy-zzzz.
```

## Common failure modes

| Failure                                                          | Why it breaks the changelog                                                                                       | Remedy                                                                       |
|------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------|
| Commit-log-as-changelog                                          | A diff of commit messages mixes internal refactors with user-visible changes; readers cannot scan for impact.     | Curate entries on each release. The commit log is the source; not the doc.   |
| No `## [Unreleased]` at the top                                  | Contributors have nowhere to put in-flight entries; on release day someone re-derives the list from `git log`.    | Always keep `## [Unreleased]` at the top, even when empty.                   |
| Ad-hoc dates / no dates / non-ISO dates                          | Cannot sort, cannot reason about release cadence, breaks tooling that parses the file.                            | ISO 8601 (`YYYY-MM-DD`), heading format `## [X.Y.Z] - YYYY-MM-DD`.           |
| Rewriting released versions                                      | Destroys the audit trail that downstream consumers rely on.                                                       | Add a fix-up entry in the next release. Released blocks are immutable.       |
| Invented categories (`Refactored`, `Docs`, `Internal`, `Build`)  | Defeats the six-category contract; readers cannot filter by impact.                                               | If it's not user-visible, it doesn't belong in the changelog at all.         |
| Marketing prose in entries (`Massive improvements to ...`)       | Readers cannot tell what actually changed.                                                                        | One line per entry, factual, link to the PR / issue for detail.              |
| Version bump that disagrees with changelog category              | Breaks the SemVer contract — downstream lockfiles trust the version number.                                       | Either move the entry to the right category or bump the right segment.       |

## Routing — when this is not the answer

- A user-visible API change that requires migration steps → **changelog entry** + a separate **migration guide** (Diátaxis how-to). The changelog says *what* changed; the migration guide says *how to adapt*.
- An internal refactor that doesn't affect users → **commit message + PR description**, not the changelog.
- A security advisory with embargo / coordinated-disclosure framing → **`SECURITY.md` advisory** + a `Security` entry referencing the advisory ID.
- A choice between two implementation options that was decided during the release cycle → **ADR**, not a changelog entry. The changelog reports the outcome; the ADR records the rationale.
