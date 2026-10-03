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

1. Update `Everfrost.toc`, `package.json`, and lockfile versions together.
2. Update `addon/Everfrost/CHANGELOG.md` for the release.
3. Run `npm ci` and `npm test`. Report actual client testing separately.
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

The first new tagged build must be checked on CurseForge before calling this
pipeline verified end to end. Project moderation can delay file availability.
