# CONTRIBUTING canon

The canonical structure for `CONTRIBUTING.md`. The file lives at the repo root (GitHub also accepts `.github/CONTRIBUTING.md`). It is the **on-ramp for external contributors** — the document that answers "I want to propose a change; what do I do?"

## What CONTRIBUTING is, and is not

| It is                                                                | It is not                                                            |
|----------------------------------------------------------------------|----------------------------------------------------------------------|
| A short, scannable on-ramp for contributors.                         | A coding style guide. That lives in linter configs and is auto-enforced. |
| The PR checklist (tests, docs, changelog).                           | The behavioral norms. Those live in `CODE_OF_CONDUCT.md`.            |
| The local-dev quickstart, or a link to one.                          | The architecture documentation. That lives in `docs/` and ADRs.      |
| The signal of how the project accepts changes.                       | The legal contract. The `LICENSE` and DCO / CLA cover that.          |

## Recommended structure

1. **How to propose a change** — issue first vs PR first; whether RFCs are required for big changes; where discussions happen (issues, discussions, chat).
2. **Local development quickstart** — clone, install, run tests, run linter, run the project. Three to ten commands maximum. Link to deeper setup docs if needed.
3. **PR checklist** — what every PR must include before it gets reviewed:
   - Tests for new behavior.
   - Documentation update (README, docs, code comments).
   - Changelog entry under `## [Unreleased]` (see `../../doc-diagnostic/references/changelog-canon.md`).
   - Linter / formatter passes.
   - Conventional Commits message (if adopted; see below).
4. **Link to `CODE_OF_CONDUCT.md`** — explicit, by name. Contributors are bound by it.
5. **Link to `SECURITY.md`** — security issues do *not* go in public issue trackers; they go through the security channel.
6. **Commit-message convention** — adopt one and link to its spec. The default doc-master suggests is **Conventional Commits 1.0** ([conventionalcommits.org](https://www.conventionalcommits.org/en/v1.0.0/)) — `feat:`, `fix:`, `docs:`, `refactor:`, etc. The skill names this as a default and routes the human to the spec; it does not bundle the spec.
7. **DCO or CLA, if used**:
   - **DCO** (Developer Certificate of Origin) — `git commit -s` adds the `Signed-off-by:` trailer; the project enforces it via a bot. Lightweight, no separate signing event.
   - **CLA** (Contributor License Agreement) — separate signing flow; required by some large projects and corporate-stewarded foundations. Heavier; deters drive-by contributions; appropriate when patent / copyright assignment matters.
8. **Review and merge expectations** — who reviews, how long until a first response, how merges happen (squash, merge, rebase).
9. **Release cadence (optional)** — when releases happen, who cuts them.

## What does not belong here

- **Coding style and formatting** — these go in the linter / formatter config (`.eslintrc`, `pyproject.toml`, `rustfmt.toml`, `.editorconfig`). CONTRIBUTING.md says "run `npm run lint`" and links to the config; it does not enumerate rules.
- **Architecture documentation** — link to `docs/` and the decision log. Do not duplicate.
- **Marketing prose** — strip "Welcome! We're so excited to have you!" The contributor wants the procedure, not a greeting.
- **Behavioral norms** — those are in `CODE_OF_CONDUCT.md`. CONTRIBUTING links to it; does not restate.

## Canonical skeleton

````md
# Contributing

Thanks for your interest in contributing.

All participants are bound by the [Code of Conduct](CODE_OF_CONDUCT.md). Please read it before opening an issue or PR.

If you have found a security vulnerability, **do not open a public issue.** See [SECURITY.md](SECURITY.md) for the private reporting channel.

## How to propose a change

- **Small bug fix / typo:** open a PR directly.
- **New feature or behavior change:** open an issue first to discuss the scope.
- **Architectural change:** see [docs/adr/](docs/adr/) for our Architecture Decision Records and the proposal process there.

## Local development

```sh
git clone https://example.com/org/project.git
cd project
make install
make test
```

## Pull request checklist

Every PR must:

- Include tests for new behavior or a fix.
- Update documentation that the change affects.
- Add an entry to `CHANGELOG.md` under `## [Unreleased]`.
- Pass the linter (`make lint`).
- Use a [Conventional Commits 1.0](https://www.conventionalcommits.org/en/v1.0.0/) message: `feat:`, `fix:`, `docs:`, etc.
- Be signed off (`git commit -s`) -- we use the [Developer Certificate of Origin](https://developercertificate.org/).

## Review

- A maintainer will respond within five business days.
- Two approvals are required for merge.
- PRs are merged with squash; the squash message is the PR title (Conventional Commits format).
````

## Common failure modes

| Failure                                              | Symptom                                                                         | Remedy                                                                                |
|------------------------------------------------------|---------------------------------------------------------------------------------|---------------------------------------------------------------------------------------|
| Coding-style rules embedded in CONTRIBUTING          | 200-line CONTRIBUTING that drifts from the linter.                              | Move to linter config; CONTRIBUTING says "run `make lint`."                           |
| No PR checklist                                       | Contributors and reviewers re-derive the standard each PR.                      | Add a four- to six-item checklist. Keep it short.                                     |
| No commit-message convention                          | Squash commits are unscannable.                                                 | Adopt Conventional Commits 1.0 (or another spec) and enforce via commit-lint.         |
| CLA / DCO confusion                                   | Contributors fail to sign; PRs stall.                                           | Document which (one) is required; bot-enforce.                                        |
| CONTRIBUTING.md is a wall of welcome prose            | Procedure buried below marketing.                                               | Move greeting to one line. Procedure first.                                           |
| Duplicates `CODE_OF_CONDUCT.md`                       | Two sources of behavioral norms; they drift.                                    | CONTRIBUTING links; does not restate.                                                 |

## Routing — when this is not the answer

- Code of Conduct → `code-of-conduct-canon.md`.
- Security disclosure → `security-canon.md`.
- Per-file licensing → `reuse-spdx-canon.md`.
- An architectural-decision proposal flow → `../../doc-diagnostic` (ADR / RFC routing).
