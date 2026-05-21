# SUPPORT canon

The canonical structure for `SUPPORT.md`. The file lives at the repo root (GitHub also accepts `.github/SUPPORT.md`). It tells a **user looking for help** where to go.

## Most small repos do not need this file

The four-question diagnostic applies bluntly:

- **Audience** — who specifically reads SUPPORT.md? Usually: a user who tried to file an issue and was redirected.
- **Does it exist already?** — yes, usually. The README's "support" or "community" section is sufficient for most projects.
- **Where does it go?** — `SUPPORT.md` at root, but only when it earns its own file.
- **Owner** — who keeps the list of channels current?

For a small repo with one issue tracker and no Discussions / chat / commercial offering, **a one-line "How to get help" link in the README is enough.** Adding `SUPPORT.md` to that repo is documentation padding.

doc-master recommends `SUPPORT.md` when:

- The repo has **multiple channels** (issues, Discussions, Discord / Slack / Matrix, mailing list, paid support) and routing matters.
- The issue tracker is being **misused for support questions** that should go elsewhere.
- The project has a **commercial support tier** worth naming.
- The project participates in **multiple communities** (Stack Overflow tag, language ecosystem chat) and wants to direct different question types to different homes.

If none of these apply, skip the file.

## Recommended structure (when the file is justified)

1. **What this file is for** — one line. "Looking for help? Here's where to go."
2. **The channel map** — a small table:
   - **Bug reports** → GitHub Issues with a link to the template.
   - **Feature requests** → GitHub Discussions / Issues with the right template, or a roadmap pointer.
   - **Usage questions** → Discussions / Stack Overflow tag / community chat.
   - **Real-time chat** → Discord / Slack / Matrix invite link.
   - **Security issues** → `SECURITY.md` (private channel, not here).
   - **Paid / commercial support** → vendor URL, if applicable.
3. **Expected cadence** — what response time, if any, is realistic per channel. Be honest. Community channels are best-effort.
4. **What we cannot help with** — out-of-scope questions, with a redirect (e.g., "we don't troubleshoot your specific build setup; ask in the language community").

## Canonical skeleton

```md
# Support

Looking for help? Pick the right channel.

| Need                          | Channel                                                                |
|-------------------------------|------------------------------------------------------------------------|
| Report a bug                  | [GitHub Issues](https://github.com/example-org/repo/issues) -- use the bug template. |
| Request a feature             | [GitHub Discussions → Ideas](https://github.com/example-org/repo/discussions/categories/ideas). |
| Ask a usage question          | [GitHub Discussions → Q&A](https://github.com/example-org/repo/discussions/categories/q-a). |
| Real-time chat                | [Project Discord](https://discord.gg/example).                          |
| Report a vulnerability        | See [SECURITY.md](SECURITY.md). Do not use any public channel for this. |
| Commercial support            | <vendor URL or "not available">                                         |

## Cadence

- Issues: a maintainer triages within five business days.
- Discussions: community-answered. Maintainers chime in when they can.
- Chat: best-effort, no SLA.

## What we cannot help with

- Custom build setups specific to your environment -- ask in the language community.
- Production-incident handholding without a commercial support tier.
```

## Common failure modes

| Failure                                          | Symptom                                                                              | Remedy                                                                          |
|--------------------------------------------------|--------------------------------------------------------------------------------------|---------------------------------------------------------------------------------|
| SUPPORT.md present for a one-channel project     | File adds nothing; readers learn no new routing.                                     | Delete. Put the one channel in the README.                                      |
| Channel map stale                                 | Discord invite expired; mailing list dead.                                           | Audit on every release. A dead channel listed is worse than no channel.         |
| SUPPORT.md becomes a FAQ                          | Question content creeps in.                                                          | Move FAQ to its own doc or Discussions. SUPPORT routes; it does not answer.     |
| SLA promises the team cannot keep                 | Users feel ignored.                                                                  | Be honest. "Best effort" is better than a broken promise.                       |
| Security channel listed alongside bug reports     | Reporters expose vulnerabilities in public issues.                                   | Security goes through SECURITY.md only. SUPPORT.md links *to* SECURITY.md.      |

## Routing — when this is not the answer

- Security disclosure → `security-canon.md`.
- Bug-report mechanics → `templates-canon.md` (issue templates).
- "What does this project do?" → README.
- "How do I contribute?" → CONTRIBUTING.md.
