# Releasing Everfrost

CurseForge project: 1723700
Source: https://github.com/mckenna654/Everfrost

## Tag-only automatic packaging

The root `.pkgmeta` stages the repository as `Everfrost-Source`, excludes
project tooling and artwork, and moves `addon/Everfrost` into the final
`Everfrost` folder. The manual changelog and MIT license live inside the addon.
Dotfiles are automatically excluded by CurseForge.

The CurseForge Source setting must be set to package new tagged commits only.
A GitHub push webhook must notify the CurseForge package endpoint using a
CurseForge API token. Never put that token or the full webhook URL in this
repository, screenshots, release notes, or logs.

## Before pushing a new tag

1. Update `addon/Everfrost/Everfrost.toc`, the metadata-only root
   `Everfrost-Source.toc`, `package.json`, and lockfile versions together.
2. Update `addon/Everfrost/CHANGELOG.md` for the release.
3. Run `npm ci`, `npm test`, and `npm run build`. Node packages only
   `addon/Everfrost` on Windows, macOS and Linux. Verify the archive against
   source files. Report actual client testing separately.
4. Commit the release files and push the commit.
5. Push an annotated version tag. For example, `v0.4.1-beta.1` is a beta;
   `v0.4.1` is a release. CurseForge recognizes `alpha` and `beta` in tag names.
6. Check CurseForge processing and inspect the generated ZIP. It must contain
   `Everfrost/Everfrost.toc`, with no repository wrapper, tests, or artwork.
7. Confirm the resulting file targets WoW Forever 1.60.1 (interface 16001),
   not Retail or Classic. Do not assume the packager infers this correctly.

Normal branch commits must not create CurseForge files. Do not move existing
release tags to trigger packaging. The existing manually uploaded 0.4.0 ZIP is
unchanged. Native CurseForge packaging does not run `npm test`; tests must be
run before releasing.

## Setup verification

Verified on October 15, 2026 with tag `v0.4.2`, commit `03ba40a`,
CurseForge build #362675 and file #9189652. The new revision completed and
created a Release for WoW Forever 1.60.1. The downloaded ZIP contains all ten
addon files under `Everfrost/`, matching the release source (allowing newline
normalization). The excluded metadata TOC is absent. An empty
`Everfrost-Source/addon/` directory remains, containing no files.

The file was initially Processing; moderation is separate from successful
packaging and may delay public availability.

The root `Everfrost-Source.toc` supplies version/interface metadata for native
CurseForge detection before folder relocation. It is excluded from packages.
The installable source of truth remains `addon/Everfrost`.
