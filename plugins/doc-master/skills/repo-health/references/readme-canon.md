# README canon — Standard Readme

The canonical structure for `README.md`. doc-master's reference is the **Standard Readme** spec (currently v1.3.0), [github.com/RichardLitt/standard-readme](https://github.com/RichardLitt/standard-readme). It collects the converged community structure for README files in open-source software projects.

A README is the **front door**. The single most common failure is that it forgets it has a job: someone unfamiliar with the project arrives, has a question, and either finds the answer in the first thirty seconds or leaves.

## Required and optional sections (Standard Readme)

The spec defines nine canonical sections. They appear in this order. Required unless marked optional.

1. **Title** — exactly the project name, as a single H1 at the top. No marketing strapline in the H1 itself; put the strapline in a one-line "short description" immediately below.
2. **Badges (optional)** — build status, version, license, coverage. Place above the long description or just below the short one. Avoid badge soup; pick three or four that earn their pixel cost.
3. **Short description** — one or two sentences immediately under the title. The reader who reads no further still knows what this is.
4. **Long description (optional)** — Background. The "why does this exist" paragraph. Skip if the short description is sufficient.
5. **Table of Contents (optional)** — required for any README that exceeds one screen of laptop scroll. Auto-generate where the renderer supports `[TOC]`; otherwise hand-maintain.
6. **Install** — exactly how to install / build / set up. Copy-pasteable commands. Cover the common case in the body; link out to detailed installation guides if any.
7. **Usage** — minimal example that does something useful. The "your first ten minutes" demo. Not a manual.
8. **API (optional)** — only when the project is a library / SDK and the README is the documentation of last resort. Otherwise link to a separate API reference.
9. **Maintainers** — named humans (or aliases). Without this, contributors do not know whom to talk to.
10. **Contributing** — short paragraph that links to `CONTRIBUTING.md`. Names the Code of Conduct.
11. **License** — short section that names the license (e.g., "MIT © 2026 Project Authors") and **links to the `LICENSE` file**. The license section in the README does not replace the `LICENSE` file; it points to it.

Sections may be empty or absent if the four-question diagnostic explains why. (A repo with no installable artifact does not need an Install section, for example — but should have a one-line "How to use this repo" note instead.)

## Common failure modes

| Failure                                                            | Symptom                                                                                 | Remedy                                                                                  |
|--------------------------------------------------------------------|-----------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------|
| Missing Install section                                            | Reader has to scrape the CI config to learn how to build.                              | Add an Install section with the exact commands. Test them on a clean machine.           |
| Missing Maintainers                                                | Drive-by contributors have no idea whom to ping.                                       | Name a small set of humans or an alias. Update when ownership changes.                  |
| Missing License section linking to `LICENSE`                       | License visible in `LICENSE` but not from the README; harder to scan.                  | Add a one-line License section with `[MIT](LICENSE)` or equivalent.                     |
| Badge soup                                                         | Ten badges, half broken, half irrelevant.                                              | Keep three to four high-signal badges. Remove broken ones in the next sweep.            |
| Marketing tone                                                     | "Revolutionary." "Game-changing." Reader cannot tell what it does.                     | Strip adjectives. State what the project does in one sentence.                          |
| Out-of-sync Usage block                                            | Example uses an API that was renamed two releases ago.                                 | Lint the README as part of CI. At minimum, copy from a tested example.                  |
| README is the docs                                                 | README is 3,000 lines and the reference manual is buried in it.                        | Split: short README, long docs in `docs/`. The README links to the docs.                |
| Setup instructions split across README and a wiki                  | Reader follows one, fails, finds the other.                                            | One source of truth. The README links; it does not duplicate.                           |

## Canonical skeleton

````md
# project-name

[![CI](badge-url)](ci-url) [![License: MIT](badge-url)](LICENSE)

> One- or two-sentence description of what this project does.

(Optional longer Background paragraph.)

## Table of Contents

- [Install](#install)
- [Usage](#usage)
- [API](#api)
- [Maintainers](#maintainers)
- [Contributing](#contributing)
- [License](#license)

## Install

```sh
git clone https://example.com/org/project.git
cd project
make install
```

## Usage

```sh
project --help
```

A minimal end-to-end example here.

## API

(Optional. Link to detailed reference under `docs/`.)

## Maintainers

- @alice
- @bob
- maintainers@example.org

## Contributing

PRs welcome. See [CONTRIBUTING.md](CONTRIBUTING.md). All participants are bound by the [Code of Conduct](CODE_OF_CONDUCT.md).

## License

[MIT](LICENSE) © 2026 The Project Authors.
````

## Routing -- when this is not enough

- A long manual, multi-language SDK, deep operational docs → link out to a documentation site (Diátaxis-organized) from the README; do not stuff it all here.
- Compliance / regulatory documentation → separate `/docs/compliance/` directory; README links to it.
- Per-file licensing metadata → `reuse-spdx-canon.md` (REUSE 3.3).
- Security disclosure policy → `security-canon.md` (`SECURITY.md`).
