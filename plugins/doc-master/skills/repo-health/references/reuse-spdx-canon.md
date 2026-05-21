# REUSE 3.3 + SPDX canon — per-file licensing metadata

The canonical reference for **REUSE 3.3** (the per-file licensing convention) and the **SPDX License List** (the canonical identifier catalog).

- REUSE 3.3 specification: [reuse.software/spec-3.3/](https://reuse.software/spec-3.3/).
- SPDX License List: [spdx.org/licenses/](https://spdx.org/licenses/).
- SPDX specification (REUSE depends on SPDX 2.3): [spdx.dev](https://spdx.dev/).

## What REUSE solves

A repository typically aggregates code under multiple licenses (own code, vendored libraries, third-party imports, configuration, documentation, assets). The single top-level `LICENSE` file cannot describe per-file reality. REUSE prescribes a convention that makes per-file licensing **machine-verifiable**:

1. **Every file has a license.** No "we forgot to think about this."
2. **The license is named with an SPDX identifier**, not a paraphrase.
3. **Copyright is attributed.** Not optional.
4. **The full license texts live in `LICENSES/`** — one file per license, SPDX-named.
5. **A `reuse lint` tool can verify the whole repo** mechanically.

## The four mechanisms (pick per file)

### 1. SPDX headers inside the file

For source files that support comments, add two lines near the top:

```c
// SPDX-FileCopyrightText: 2026 The Project Authors
// SPDX-License-Identifier: Apache-2.0
```

The exact comment syntax depends on the language. Both lines are required. The license identifier must be from the SPDX list.

Multiple copyright holders → multiple `SPDX-FileCopyrightText:` lines. Multi-license files → SPDX-license expression (`Apache-2.0 OR MIT`).

### 2. `.license` sidecar file

For files that **cannot** carry comments (binaries, images, fonts, generated artifacts, PDFs):

- Create a sidecar at `<file>.license` containing the same two SPDX lines.
- Example: `logo.png` plus `logo.png.license`.

### 3. `REUSE.toml` bulk declaration

For groups of files that all share the same copyright and license, add a `REUSE.toml` at the repo root:

```toml
version = 1

[[annotations]]
path = "docs/**"
SPDX-FileCopyrightText = "2026 The Project Authors"
SPDX-License-Identifier = "CC-BY-4.0"

[[annotations]]
path = "vendor/lib-foo/**"
SPDX-FileCopyrightText = "2024 The Foo Authors"
SPDX-License-Identifier = "BSD-3-Clause"
```

`REUSE.toml` is the modern format (REUSE 3.x); older `.reuse/dep5` (Debian DEP-5) is being phased out.

### 4. `LICENSES/` directory

The repo root contains a `LICENSES/` directory with one file per license used anywhere in the project, **SPDX-named**:

```text
LICENSES/
  Apache-2.0.txt
  MIT.txt
  CC-BY-4.0.txt
  BSD-3-Clause.txt
```

Each file contains the **verbatim** canonical license text. Do not paraphrase. Get the text from [spdx.org/licenses/](https://spdx.org/licenses/).

## When to adopt REUSE

The four-question diagnostic applies. doc-master recommends REUSE when:

- The repo **aggregates multi-license content** (project code + vendored libraries + assets under different licenses).
- The project **ships to environments requiring SBOM** (Software Bill of Materials) — government, healthcare, certain commercial customers.
- The project wants **machine-verifiable license compliance** in CI.
- The project is **funded** under terms that require explicit copyright attribution.

For a single-author hobby project with one license, REUSE is overkill. The top-level `LICENSE` plus an `SPDX-License-Identifier:` on each source file is plenty.

## The CI gate

```sh
pipx install reuse
reuse lint
```

This passes when every file in the repo is covered (via header, sidecar, or `REUSE.toml`) and every named license has a text in `LICENSES/`. Add it to CI to prevent license drift.

## Common failure modes

| Failure                                                  | Symptom                                                                            | Remedy                                                                          |
|----------------------------------------------------------|------------------------------------------------------------------------------------|---------------------------------------------------------------------------------|
| Inconsistent license naming                              | `MIT`, `MIT License`, `mit`, all in different files.                              | Use the exact SPDX identifier (`MIT`) everywhere.                               |
| Licenses missing from `LICENSES/`                        | Files claim a license whose text is not in the repo.                              | Add the canonical text from spdx.org/licenses to `LICENSES/<id>.txt`.            |
| Vendored code uncovered                                  | `vendor/` directories with no SPDX headers and no `REUSE.toml` entry.             | Bulk-declare via `REUSE.toml`; or add `.license` sidecars; or migrate upstream. |
| Paraphrased license text                                 | `LICENSES/MIT.txt` is "based on" the MIT text.                                    | Replace with the verbatim canonical text. Compliance scanners depend on exact match. |
| Binary assets uncovered                                  | Images, fonts, datasets with no `.license` sidecar.                               | Add `<file>.license` sidecars. Or bulk-cover in `REUSE.toml`.                   |
| REUSE-compliant but no top-level `LICENSE`               | The project itself has no primary license declared.                               | Keep a top-level `LICENSE` for the project's *own* code; REUSE handles per-file. |
| CI not gating                                             | Compliance drifts between releases.                                              | Add `reuse lint` to CI; fail on any uncovered file.                             |

## What this canon does not cover

- **Picking a license.** Routes to `license-routing.md`.
- **SPDX expression syntax** (`Apache-2.0 WITH LLVM-exception`, complex AND/OR/WITH). See [spdx.github.io/spdx-spec/SPDX-license-expressions/](https://spdx.github.io/spdx-spec/SPDX-license-expressions/).
- **SBOM generation.** SPDX 2.3 / 3.0 supports SBOM; REUSE adoption is a strong foundation for SBOM output, but generation is a separate tooling concern (CycloneDX, syft, etc.).
- **License compatibility analysis.** Different question; refer to OSI / FSF / SPDX guidance.

## Routing — when this is not the answer

- "Which license do we pick?" → `license-routing.md`.
- "How do we document our top-level project license?" → `readme-canon.md` + a top-level `LICENSE`.
- "We are adopting REUSE as a project-wide commitment" → potentially an **ADR**, because it imposes a CI gate and a per-file convention with operational cost.
