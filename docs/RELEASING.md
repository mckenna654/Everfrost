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

Normal branch commits must not create CurseForge files. For ordinary new
releases, do not move existing release tags to trigger packaging. When the user
explicitly requests a same-version replacement, refresh the existing release
asset and its source tag together, check the old tag ID with force-with-lease,
and verify the newly generated CurseForge file. The existing manually uploaded 0.4.0 ZIP is
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

October 20, 2026: `v0.5.0` generated CurseForge file #9262577
(`Everfrost-Source-v0.5.0.zip`) as a Release for Forever 1.60.1.
Downloaded and verified all 13 addon files, including GearProfiles.lua,
Gear.lua and GearUI.lua, against release commit 875a5f5 (allowing newline
normalization). Initial status: Processing. GitHub latest release, project
description, README heading and the public CurseForge name/description now
include gear upgrades and Need/Greed hints.

User-requested same-version guide-selector refresh: kept 0.5.0, refreshed the
existing GitHub release (ID 417916471) and v0.5.0 source tag to commit ec01835.
CurseForge generated file #9262809 for Forever 1.60.1. Downloaded and checked
all 13 files against the source, including the new title-button menu. Initial
status: Processing. The previous approved 0.5.0 file remains available while
the replacement is reviewed.

October 20, 2026: published v0.5.1 as the latest GitHub release (commit
5bfbb27), superseding the same-version refresh. CurseForge automatically
created Release file #9262832 for Forever 1.60.1. All 13 downloaded files
match the release source after newline normalization. Status: Under Review.

October 20, 2026: published v0.5.2 as the latest GitHub release (commit
5bfe11d) with complete one-hand/off-hand pair comparisons against equipped
two-handers. CurseForge automatically created Release file #9263868
(`Everfrost-Source-v0.5.2.zip`) for Forever 1.60.1. Downloaded and verified
all 13 addon files against the release source, allowing newline normalization.
Initial status: Under Review. The public project description now includes
pair comparisons and the requirement to equip both companion items.

## October 20 release consolidation

The user requested restoring the original 0.5.0 (875a5f5), consolidating the
second 0.5.0, original 0.5.1 and former 0.5.2 into 0.5.1, then publishing the
settings, gear presentation and native talent-detection fixes as 0.6.0.
Older verification entries above describe the pre-consolidation history.
Restore the original 0.5.0 asset/tag without creating a duplicate CurseForge
package, retain its first file #9262577, archive superseded files, and
re-enable tag-only packaging for the rebuilt 0.5.1 and new 0.6.0 tags.
The current CurseForge project description is maintained in docs/CURSEFORGE.md.
