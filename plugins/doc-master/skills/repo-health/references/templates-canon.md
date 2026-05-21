# Templates canon — `.github/` files

Repository templates that GitHub (and most equivalent forges) recognize. Each is **optional** and earns its place via the four-question diagnostic. Cargo-culting a `.github/` directory full of empty templates is documentation padding.

## Issue templates — `.github/ISSUE_TEMPLATE/`

Two formats are supported:

- **Markdown templates** (`.github/ISSUE_TEMPLATE/<name>.md`) — older format, free-form Markdown with a YAML front matter. Still supported but largely superseded.
- **Issue-form templates** (`.github/ISSUE_TEMPLATE/<name>.yml`) — **preferred**. Structured form with typed inputs (text, dropdown, checkboxes, textarea). Produces better-formatted issues and lets the project enforce required fields.

### Recommended set

Most projects benefit from two or three templates:

- **Bug report** — fields: summary, version, reproduction steps, expected vs actual, environment.
- **Feature request** — fields: problem, proposed solution, alternatives, additional context.
- **Question** — only if Discussions are not enabled. With Discussions on, redirect questions there via `config.yml`.

Add a `.github/ISSUE_TEMPLATE/config.yml` to control "blank issue" behavior and link to non-issue channels (Discussions, security, chat):

```yaml
blank_issues_enabled: false
contact_links:
  - name: Question / discussion
    url: https://github.com/example-org/repo/discussions
    about: Ask usage questions in Discussions.
  - name: Security vulnerability
    url: https://github.com/example-org/repo/security/advisories/new
    about: Report a security issue privately. Do not open a public issue.
```

### Common failures

- **No templates** → contributors free-form, maintainers re-ask the same questions.
- **Too many templates** → triage cost; contributors pick wrong.
- **Form fields without `required: true`** → key info still missing.
- **Markdown templates that pretend to be forms** → migrate to issue-form `.yml`.

## Pull-request template — `.github/PULL_REQUEST_TEMPLATE.md`

A single file at `.github/PULL_REQUEST_TEMPLATE.md` (multiple templates are supported via `.github/PULL_REQUEST_TEMPLATE/` directory, but most projects use one).

Keep it short. The template should mirror the PR checklist in `CONTRIBUTING.md`:

```md
## Summary

(One paragraph: what does this change and why.)

## Type of change

- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation
- [ ] Refactor / internal

## Checklist

- [ ] Tests added / updated.
- [ ] Documentation updated.
- [ ] `CHANGELOG.md` entry added under `## [Unreleased]`.
- [ ] `make lint` passes locally.
- [ ] Conventional Commits message (`feat:`, `fix:`, `docs:`, ...).
- [ ] Signed off (`git commit -s`).

## Related issues / ADRs

(Link issues this resolves and any ADRs touched.)
```

A bloated PR template is itself a failure mode — every field is a tax on the contributor.

## CODEOWNERS — `.github/CODEOWNERS` or `CODEOWNERS` at repo root

A small file that maps path patterns to reviewers (users or teams). GitHub uses it to auto-request reviews when a PR touches a path.

```text
# Default
*                       @example-org/maintainers

# Per-area
/docs/                  @example-org/docs-team
/security/              @example-org/security-team
/services/payments/     @example-org/payments-team
```

Hard rules:

- **Owners must be teams or aliases**, not single users (bus factor).
- **Patterns are evaluated last-match-wins** — order matters.
- **The file is itself a decision record** of who owns what. Audit it on every team change.

## FUNDING.yml — `.github/FUNDING.yml`

Tells GitHub to render a "Sponsor" button. Only useful when the project actually accepts donations.

```yaml
github: [example-org]
patreon: example
open_collective: example
custom: ["https://example.org/donate"]
```

Most projects do not need this. Add only when the project has a real funding channel, not aspirationally.

## CITATION.cff — `CITATION.cff` at repo root

The **converged format for academic citation** of software. CFF (Citation File Format) is YAML; GitHub renders a "Cite this repository" button from it.

Required for **research software, academic-cited tools, datasets-as-code, and anything used in published work** that benefits from a canonical citation. Not needed for most application code.

```yaml
cff-version: 1.2.0
message: "If you use this software, please cite it as below."
title: "Example Project"
version: 1.4.0
date-released: 2026-05-21
authors:
  - family-names: Doe
    given-names: Jane
    orcid: https://orcid.org/0000-0000-0000-0000
repository-code: "https://github.com/example-org/repo"
license: MIT
```

The schema lives at [citation-file-format.github.io](https://citation-file-format.github.io/).

## Discussions, wiki, Pages — out of scope here

These are GitHub features, not files in the repo. The repo-health skill names them as **routing targets** (`SUPPORT.md`, README), not as files to author.

## Common failure modes across templates

| Failure                                                  | Symptom                                                                          | Remedy                                                                          |
|----------------------------------------------------------|----------------------------------------------------------------------------------|---------------------------------------------------------------------------------|
| Cargo-culted `.github/` directory                        | Every template type present, none actually used.                                 | Delete unused. Each file passes the four-question diagnostic.                   |
| CODEOWNERS lists single users                             | Reviews stall when the named human is unavailable.                              | Teams or aliases, never individuals.                                            |
| PR template is a 40-item checklist                        | Contributors skip the checklist entirely.                                       | Six items maximum. Mirror `CONTRIBUTING.md`.                                    |
| Issue templates without required fields                   | Submissions still missing the version, the repro, the env.                      | Mark critical fields `required: true` in the issue-form schema.                |
| FUNDING.yml with aspirational links                       | "Sponsor" button leads to nothing.                                              | Either real channel or remove.                                                  |
| CITATION.cff out of sync with releases                    | Version field stuck at 0.1.0; citations are wrong.                              | Bump as part of release tooling. Tag the repo to match.                         |

## Routing — what each template points to

- Issue template `config.yml` → SECURITY.md (vulnerabilities), Discussions (questions), SUPPORT.md (help).
- PR template → CONTRIBUTING.md (checklist source of truth).
- CODEOWNERS → no public doc; internal team / alias list.
- FUNDING.yml → no public doc; just the funding URL.
- CITATION.cff → optional inclusion in README ("How to cite") with a short summary.
