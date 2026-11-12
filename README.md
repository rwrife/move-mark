# Move Mark

Offline move-day box tracker: label cartons, assign destination rooms, locate essentials, and reconcile unpacking on phone, tablet, and Windows.

## Why and who
Households moving between homes lose track of cartons and unpack the wrong box first. Move Mark gives movers a private, searchable manifest and clear room destinations. Unlike general home inventories, records have a move-specific box lifecycle: packed, loaded, delivered, opened, reconciled.

## Intended workflow
Create a move and destination rooms; number a carton, record short contents and priority, optionally attach a local photo, then write or print its number on the box. Search the manifest at the destination; mark arrival and unpacking, flag a missing carton without implying a shipping carrier has tracked it. Export a JSON backup and CSV manifest to user-chosen files. There is no live cross-device sync: transfer an exported file explicitly.

## MVP and non-goals
MVP: local moves/rooms/cartons, numbered IDs unique within a move, status history, essential-box filter, quick search, reversible check-off, and import/export. No automatic object recognition, QR scanner, GPS, carrier integration, cloud account, multi-user live collaboration, or insurance valuation. No inferred proof of delivery.

## Platforms and privacy
Flutter stable, one Dart app for Windows, Android phones/tablets and iOS/iPadOS. Touch, keyboard and mouse; responsive phone/tablet/desktop layout. User data stays locally on each device; optional photos require explicit picker selection, no camera or location permission by default. Export only on request. Screen readers, contrast, text scaling and full keyboard navigation are release requirements. `com.infinityball.movemark` is Android applicationId and iOS bundle identifier. Native iPad support enabled.

## Status and milestones
Flutter stock counter skeleton exists with Windows, Android and iOS platform folders. OpenAI Images generated `AppStore/icon.png`; resized icon variants are wired into Windows, Android and iOS. CI checks pinned Flutter, analysis, tests, Windows release build and Android debug build on PRs and main. Move/room/carton domain, adaptive UI and release remain unbuilt. `AppStore/description.txt` is draft planned-feature listing copy. `.github/workflows/release.yml` must build a Windows portable ZIP on `windows-latest` for `v*` tags/manual dispatch and attach it to a GitHub release. Android Play and iOS TestFlight releases are later opt-in milestones using ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8, ASC_TEAM_ID secret names; never log values.

## Development quickstart
Flutter skeleton already created for Windows, Android and iOS. Use stable Flutter pinned in `docs/toolchain.json`; run `flutter pub get --enforce-lockfile && flutter test && flutter analyze --fatal-infos`. On Linux, run from the repository root:

```sh
docker run --rm -v "$PWD:/work" -w /work -e PUB_CACHE=/work/.pub-cache ghcr.io/project516/flutter:3.47.7 bash -c 'dart run tool/check_toolchain.dart && flutter pub get --enforce-lockfile && flutter analyze --fatal-infos && flutter test'
```

`PUB_CACHE` is isolated and ignored by Git. Windows release and Android debug builds run in `.github/workflows/ci.yml`; Linux host checks do not prove those builds. Current stock counter is Flutter's generated smoke skeleton, not Move Mark functionality.

## Manual setup required
App Store Connect registration of `com.infinityball.movemark` failed: `FAILED bundleId lookup rejected: FORBIDDEN_ERROR.PLA_NOT_ACCEPTED`. Account owner must accept current Apple Program License Agreement, then rerun `/home/rwrife/workspaces/tool-lab/asc_create_bundle_id.py move-mark`. Identifier is not registered yet.

MIT licensed; see LICENSE.
