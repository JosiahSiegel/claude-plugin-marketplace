# SECURITY canon

The canonical structure for `SECURITY.md`. The file lives at the repo root (GitHub also accepts `.github/SECURITY.md`). It tells a **security researcher** how to responsibly disclose a vulnerability — and what to expect after they do.

## What SECURITY.md is, and is not

| It is                                                          | It is not                                                  |
|----------------------------------------------------------------|-------------------------------------------------------------|
| A **private** vulnerability-reporting policy.                  | A public bug-reporting guide. (That's the issue tracker.)   |
| A statement of which versions get fixes.                       | A security manual.                                          |
| A commitment to a response window.                             | A guarantee of a fix.                                       |
| The published part of the security program.                    | The internal incident-response playbook.                    |

## Required sections

A doc-master `SECURITY.md` has these sections:

1. **Supported Versions** — a small table naming which versions receive security fixes. Reporters need to know whether their finding is in scope.
2. **Reporting a Vulnerability** — the **private channel**. Strongly preferred:
   - **GitHub Security Advisories** (`https://github.com/<org>/<repo>/security/advisories/new`) — built-in, supports coordinated disclosure, no infrastructure to maintain.
   - **A named shared alias** (`security@example.org`, `psirt@…`).
   - **A coordinated-disclosure program** (HackerOne, Bugcrowd, an internal program with a public page).
   - **Refuse a single-maintainer email** as the contact. Bus factor of one is unacceptable for security reports.
3. **Expected Response Window** — concrete numbers. doc-master's **floor is one human-week** (five business days) for open-source projects. If the team cannot meet that, the project's security posture is the problem; either staff it or be honest about the longer window.
4. **Scope** — what is in scope (the codebase, the deployed service, specific components) and what is out (third-party dependencies that should be reported upstream, social engineering, denial of service, etc.).
5. **Attribution & Disclosure** — how researchers are credited (CVE, advisory acknowledgments, a public hall of fame), the embargo window, the disclosure-timing policy (e.g., "we publish 30 days after a fix ships or 90 days from report, whichever is earlier").

Optional:

- **Safe harbor** — a public commitment not to pursue legal action against good-faith researchers acting within the policy.
- **Reward program** — bounty amounts, scope, exclusions. Most small projects do not have one and that is fine.
- **PGP key / Signal contact** — for the very small number of reporters who need it.

## Hard rules

- **Single-maintainer email is refused.** doc-master will not draft a SECURITY.md whose contact line resolves to one individual's personal inbox. Use GitHub Security Advisories or a shared alias.
- **The response-window floor is one human-week.** Cannot make that? Then the SECURITY.md needs to be honest about a longer window, not omit the window entirely.
- **Public issues are forbidden for vulnerabilities.** State this explicitly. Reporters following responsible disclosure norms still need a reminder.
- **No "best effort" weasel words on response.** Either commit to a window or don't publish one. Reporters interpret "best effort" as "ignore."

## Canonical skeleton

```md
# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.x     | yes       |
| 0.x     | no        |

## Reporting a Vulnerability

Please **do not open a public GitHub issue** for security vulnerabilities.

Use one of these channels:

- **Preferred:** [open a security advisory](https://github.com/example-org/example-repo/security/advisories/new) on GitHub.
- **Alternative:** email `security@example.org`. This alias is monitored by the security team; replies are confidential.

Please include:

- A description of the issue and the affected component / version.
- Steps to reproduce, including a proof-of-concept where safe.
- The impact you observed and the impact you believe is possible.
- Any preliminary mitigations.

## Response Window

We acknowledge security reports within **five business days**. We aim to publish a fix and advisory within **30 days** of a confirmed report; complex issues may take longer, and we will communicate ETA updates if so.

## Scope

In scope:

- This codebase and its released artifacts.
- The official deployed service at `example.com`.

Out of scope:

- Third-party dependencies -- please report upstream. We will track the fix.
- Social-engineering and physical-security testing.
- Denial-of-service findings without a novel vector.

## Disclosure

We follow coordinated disclosure. Public disclosure happens after a fix ships or 90 days from the original report, whichever is earlier. Reporters are credited in the advisory unless they request otherwise.

## Safe Harbor

We will not pursue legal action against researchers acting in good faith within this policy.
```

## Common failure modes

| Failure                                                      | Symptom                                                                       | Remedy                                                                            |
|--------------------------------------------------------------|-------------------------------------------------------------------------------|-----------------------------------------------------------------------------------|
| No SECURITY.md                                               | Reporters open public issues; vulnerabilities get disclosed by accident.       | Add the file. Even a five-line stub is better than nothing.                       |
| Single-maintainer email                                       | Inbox unattended; reports stall.                                              | Shared alias or GitHub Security Advisories.                                       |
| "Best effort" / "we'll get to it"                            | No commitment; researchers feel ignored.                                       | Commit to a window. Or be honest about a longer one.                              |
| Supported Versions absent or stale                            | Reports about EOL versions; wasted cycles.                                    | Maintain the table. Update on every major release.                                |
| Public scope hidden                                           | Researchers test the live service; legal team objects.                        | State scope explicitly. Include safe harbor if you want bug-bounty behavior.      |
| Embargo / disclosure timing missing                           | Researchers publish before a fix ships.                                       | State the embargo window. Honor it on both sides.                                 |
| SECURITY.md *is* the incident-response playbook               | Public file leaks internal procedure.                                         | Keep internal runbooks internal. Public file is the contract; not the procedure.  |

## Routing — when this is not the answer

- Behavioral norms → `CODE_OF_CONDUCT.md`.
- Support / how-to-get-help → `SUPPORT.md` (`support-canon.md`).
- A specific vulnerability advisory → GitHub Security Advisory or equivalent. SECURITY.md is the *policy*; advisories are the *events*.
- Postmortem of a security incident → `../../doc-diagnostic/references/postmortem-canon.md`, with blameless framing.
- A decision to adopt a coordinated-disclosure program → may be an **ADR** if the program imposes architectural constraints (logging, rate-limiting, audit trails).
