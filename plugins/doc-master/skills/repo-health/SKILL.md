---
name: repo-health
description: |
  This skill should be used when bootstrapping, auditing, or reviewing the community-health and repository-cornerstone files in a code repository: README, LICENSE, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, SUPPORT, issue / PR templates, CODEOWNERS, FUNDING, CITATION, and REUSE / SPDX metadata.
  PROACTIVELY activate on "set up new repo docs", "community health files", "what should my README contain", "do I need a code of conduct", "audit repo bootstrap docs", "repository documentation cornerstones", "pick a license", "CONTRIBUTING.md", "SECURITY.md", "vulnerability reporting", "SUPPORT.md", "CODEOWNERS", "issue templates", "PR templates", "CITATION.cff", "REUSE", "SPDX headers", "Standard Readme", "Contributor Covenant".
  Provides: four-question diagnostic per cornerstone, Standard Readme structure, license routing (no picking), CONTRIBUTING / CODE_OF_CONDUCT / SECURITY / SUPPORT canons, template files, and REUSE 3.3 / SPDX routing.
---

# repo-health

The repository-cornerstone skill. Owns the canon for the **community-health files** that bootstrap any code repository:

- `README.md` — the front door (Standard Readme spec).
- `LICENSE` — the legal contract (routed to choosealicense.com; doc-master does not pick).
- `CONTRIBUTING.md` — how external contributors propose changes.
- `CODE_OF_CONDUCT.md` — behavioral norms (Contributor Covenant 3.0 default; 2.1 fallback).
- `SECURITY.md` — vulnerability reporting policy.
- `SUPPORT.md` — where users go for help (often optional for small repos).
- `.github/` templates — issue / PR / CODEOWNERS / FUNDING / CITATION.
- REUSE 3.3 + SPDX — per-file copyright and license metadata.

Each cornerstone has a reference file with the structure, common failure modes, and routing notes. This SKILL.md is the lean entry point — load the references on demand.

## Diagnostic first — do not auto-create

doc-master applies the **four-question diagnostic** to every cornerstone before recommending creation:

1. **Audience** — who reads this, in what situation? (Drive-by contributor? Security researcher? Confused user? Compliance auditor?)
2. **Does it exist already?** — many repos already have an equivalent under a different name or location. Find first, write second.
3. **Where does it go?** — top-level, `.github/`, `docs/`? Each cornerstone has a conventional home.
4. **Who owns it?** — a named human or alias. "The team" is not an owner. CODEOWNERS exists because ownership matters.

If any answer is "no" or "we don't know," **do not create the file yet.** Most small repos do not need `SUPPORT.md`, do not need `FUNDING.yml`, do not need a per-file REUSE header. Cargo-culting cornerstones produces docs nobody reads and nobody updates — the same anti-padding rule that governs ADRs.

## What to recommend by default

For any code repository visible outside the originating team:

| Cornerstone               | Default                                                                                                                       |
|---------------------------|-------------------------------------------------------------------------------------------------------------------------------|
| `README.md`               | **Yes** — required. Use the Standard Readme structure. See `references/readme-canon.md`.                                      |
| `LICENSE`                 | **Yes** — required for any code that will be reused. doc-master routes to [choosealicense.com](https://choosealicense.com/); does not pick. See `references/license-routing.md`. |
| `CONTRIBUTING.md`         | **Yes** if external contribution is accepted. Skip if the repo is read-only. See `references/contributing-canon.md`.          |
| `CODE_OF_CONDUCT.md`      | **Yes** if any external participation. Default to **Contributor Covenant 3.0**; 2.1 is the still-valid older fallback. See `references/code-of-conduct-canon.md`. |
| `SECURITY.md`             | **Yes** if the code processes untrusted input, handles secrets, ships to production, or has any user-visible attack surface. See `references/security-canon.md`. |
| `SUPPORT.md`              | **Probably not** for most small repos. Add only when the issue tracker is being misused for support questions. See `references/support-canon.md`. |
| Issue / PR / CODEOWNERS / CITATION / FUNDING | **Case by case.** Each has a real trigger. See `references/templates-canon.md`.                                  |
| REUSE 3.3 / SPDX headers  | **Yes** for any repo that aggregates code under multiple licenses, ships to environments that require SBOM, or wants machine-verifiable license metadata. See `references/reuse-spdx-canon.md`. |

## How to run a bootstrap or audit

When the user asks to **set up** repository docs:

1. Inventory what already exists (`README*`, `LICENSE*`, `CONTRIBUTING*`, `CODE_OF_CONDUCT*`, `SECURITY*`, `SUPPORT*`, `.github/`).
2. For each cornerstone, run the four-question diagnostic.
3. Recommend create / merge / leave-alone, one file at a time. Do not bulk-generate.
4. For files that should be created, load the matching reference; produce a draft with placeholders the user fills in. Never invent maintainer names, contact aliases, license choices, or SLA windows.
5. License selection is **routed**, not made. The skill names common defaults (MIT, Apache-2.0, BSD-3-Clause, GPL-3.0, MPL-2.0) and points to [choosealicense.com](https://choosealicense.com/); the human decides.

When the user asks to **audit** repository docs:

1. Same inventory.
2. For each cornerstone present, compare to the canon and flag drift / missing sections / stale dates / single-maintainer contact lines.
3. For each cornerstone absent, ask whether the four-question diagnostic answers it into existence — most "missing" `SUPPORT.md` and `FUNDING.yml` cases should stay missing.
4. Produce a numbered KEEP / REWRITE / CREATE / DELETE list. Do not bulk-rewrite.

## Hard rules

- **doc-master does not pick a license.** Routing to [choosealicense.com](https://choosealicense.com/) is mandatory. The skill names common defaults; the human chooses.
- **Code of Conduct contact is a shared alias, never a single email.** `conduct@example.org`, `community@…`, a moderation team — never a personal inbox. Bus factor of one is a refusal condition.
- **SECURITY.md contact is a shared alias or coordinated channel** (GitHub Security Advisories, a named program, `security@…`). Refuse a single-maintainer email.
- **Anti-padding.** Every recommended file passes the four-question diagnostic. If the four questions cannot be answered, the file should not exist.
- **One finding per turn.** When auditing, the skill mirrors `adr-critique` / `markdown-style`: line-referenced, verbatim quote, named rule, proposed rewrite, per-finding approval.

## Routing — what this skill does not own

- **Markdown form** — once a cornerstone exists, lint it via `markdown-style` (`/doc-lint`).
- **ADRs for architectural decisions** — `doc-diagnostic` / `adr-drafting`. "We adopted REUSE" *may* be an ADR; the per-file REUSE headers themselves are not.
- **Changelog** — `../doc-diagnostic/references/changelog-canon.md`.
- **Runbooks / postmortems / open-questions register** — `../doc-diagnostic/references/{runbook,postmortem,open-questions}-canon.md`.
- **AGENTS.md** for AI-agent context — `../doc-diagnostic/references/agentic-docs-canon.md`.

## Examples

<example>
<user_query>I just started a new open-source project. What docs do I need at the repo root?</user_query>
<response>The opensource.guide four-file canon: README.md, LICENSE, CONTRIBUTING.md, CODE_OF_CONDUCT.md. Add SECURITY.md if the code processes untrusted input. SUPPORT.md is usually overkill for a new project. Loading `repo-health`; we'll go file by file with the four-question diagnostic. License selection routes to choosealicense.com — I do not pick.</response>
</example>

<example>
<user_query>Should I write an ADR for "we adopted the Contributor Covenant 3.0"?</user_query>
<response>No — that's a CODE_OF_CONDUCT.md adoption, not an ADR. Default to Contributor Covenant 3.0 (four-rung Enforcement Ladder); 2.1 is the older still-valid fallback. Contact line must be a shared alias, not a single maintainer. Loading `repo-health` reference `code-of-conduct-canon.md`.</response>
</example>

<example>
<user_query>Audit our community-health files.</user_query>
<response>Loading `repo-health`. Inventory first, then four-question diagnostic per file, then a numbered KEEP / REWRITE / CREATE / DELETE list. I'll flag single-maintainer contact lines in SECURITY.md / CODE_OF_CONDUCT.md as refusal conditions.</response>
</example>

<example>
<user_query>Do I need a CITATION.cff?</user_query>
<response>If the repo is research software or expects academic citation: yes — CITATION.cff is the converged format. Otherwise no. `references/templates-canon.md` for the schema.</response>
</example>

## References

- `references/readme-canon.md` — Standard Readme spec; nine canonical sections.
- `references/license-routing.md` — common license defaults and the routing rule (doc-master does not pick).
- `references/contributing-canon.md` — CONTRIBUTING.md structure, Conventional Commits 1.0, DCO.
- `references/code-of-conduct-canon.md` — Contributor Covenant 3.0 default with 2.1 fallback; Enforcement Ladder; shared-alias rule.
- `references/security-canon.md` — SECURITY.md sections; private-reporting channels; response-window floor.
- `references/support-canon.md` — SUPPORT.md channels; when most repos can skip it.
- `references/templates-canon.md` — `.github/ISSUE_TEMPLATE/*.yml`, `PULL_REQUEST_TEMPLATE.md`, CODEOWNERS, FUNDING.yml, CITATION.cff.
- `references/reuse-spdx-canon.md` — REUSE 3.3 per-file headers, `LICENSES/` folder, `REUSE.toml`, `.license` sidecars; SPDX identifier catalog.
