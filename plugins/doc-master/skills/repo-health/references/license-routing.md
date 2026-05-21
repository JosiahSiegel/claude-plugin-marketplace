# LICENSE — routing, not picking

doc-master **does not pick a license for users.** Licensing is a legal decision with downstream consequences (compatibility, patent grants, copyleft propagation, contributor expectations); the right answer depends on the project, the contributors, the consumers, and sometimes legal counsel.

The skill's job is to **route** the user to:

1. [choosealicense.com](https://choosealicense.com/) — the GitHub-maintained guide, intentionally narrow but high-quality.
2. The full SPDX license catalog — [spdx.org/licenses/](https://spdx.org/licenses/) — when the project needs a license not covered by choosealicense.

## Common defaults — naming only, not recommending

doc-master will name these in conversation, with one-line summaries. The human picks.

| SPDX identifier   | One-line summary                                                                                   |
|-------------------|----------------------------------------------------------------------------------------------------|
| `MIT`             | Short, permissive. No patent grant. Allows proprietary derivatives. Most common in JS / Ruby / Go ecosystems. |
| `Apache-2.0`      | Permissive. Explicit patent grant. Patent retaliation clause. Allows proprietary derivatives. Common in JVM / cloud-native ecosystems. |
| `BSD-3-Clause`    | Permissive, similar in spirit to MIT. Adds a non-endorsement clause.                               |
| `GPL-3.0-or-later`| Strong copyleft. Derivative works must be GPL-licensed. Patent grant. Anti-tivoization clauses.   |
| `LGPL-3.0-or-later`| Weak copyleft. Library can be linked into proprietary code; modifications to the library itself must be LGPL. |
| `MPL-2.0`         | File-level copyleft. Modifications to MPL-licensed files must be MPL; combinations with proprietary code are allowed. |
| `AGPL-3.0-or-later`| Strong copyleft including network use. Derivative works served over a network must offer source. |
| `CC0-1.0`         | Public-domain dedication. For documentation, datasets, configuration — **not for source code**.    |
| `Unlicense`       | Public-domain-style. Not recognized in all jurisdictions; prefer CC0 or 0BSD for similar effect.   |
| `0BSD`            | Public-domain-equivalent BSD variant; recognized in more jurisdictions than Unlicense.             |

This list is **descriptive, not prescriptive**. The skill names options; the human picks based on goals, ecosystem expectations, contributor base, and legal advice.

## What goes in the repo

- A top-level `LICENSE` (or `LICENSE.md`, or `LICENSE.txt`) file with the **verbatim** license text. Do not summarize; do not paraphrase. GitHub's licensee tool and most compliance scanners depend on the exact text matching the SPDX-listed canonical form.
- A short License section in `README.md` that names the license and links to the `LICENSE` file (see `readme-canon.md`).
- For per-file licensing metadata (multi-license repos, third-party imports): an `SPDX-License-Identifier:` header on each source file. See `reuse-spdx-canon.md` for the REUSE 3.3 convention.

## When the choice is not obvious — escalate

- **Mixed licensing across the codebase** (vendored third-party libraries with their own licenses): the project picks its **own** license for its **own** code; vendored code retains its license. Track the combination via REUSE / SBOM.
- **Patents are a concern** (cryptography, ML models, specific algorithms): prefer Apache-2.0 over MIT for the explicit patent grant.
- **Strong-copyleft ecosystem expectations** (Linux kernel modules, GNU tools): pick within the GPL family.
- **Compliance regimes** (GPL-only enterprise, MIT-only consumer): match the regime.
- **Datasets, documentation, configuration** (not source code): consider CC0 for public domain or CC-BY-4.0 for attribution. These are not OSI-approved for software.

When the choice is unclear, doc-master surfaces the question to the architect / project owner and **declines to guess.**

## What this file does not cover

- **Choosing for the user.** Choosealicense.com is the public guide; legal counsel is the private one.
- **Drafting custom licenses.** Avoid. Use an SPDX-listed license.
- **License compatibility analysis** (can I combine GPL-2.0 and Apache-2.0?). Refer to FSF / OSI / SPDX compatibility documentation.
- **Trademark policy.** Trademarks are separate from copyright. Some projects publish a `TRADEMARKS.md` alongside `LICENSE`.

## Routing — what to load next

- Per-file SPDX headers / REUSE compliance → `reuse-spdx-canon.md`.
- README license section → `readme-canon.md`.
- A decision to **change** the project's license → almost certainly an **ADR**, because relicensing affects every downstream consumer and contributor.
