# Move Mark plan

## Scope and architecture
Flutter stable single Dart codebase: Windows, Android, iOS (phones and tablets). `com.infinityball.movemark` on Android and iOS. Separate pure-Dart move/box/status validation from platform UI; local persistence on each device, explicit JSON backup and CSV manifest. Imported backups validate IDs, statuses, bounds and schema version before replacing any data; preview conflicts and retain previous data on failure. No background network access.

## UX choice: A — platform-native adaptive
Use a small adaptive widget layer: Cupertino on iOS/iPadOS, Material 3 on Android, Fluent on Windows. Never show Material on iOS, Cupertino on Android or phone-style UI on Windows. Native back behavior, keyboard shortcuts, hover/context menus and window resize; screen reader labels, scalable text, high contrast, keyboard navigation. Phone: stacked list/detail; tablet/desktop: list/detail panes. Use native file pickers and safe areas. Golden/widget tests under TargetPlatform.iOS, TargetPlatform.android and TargetPlatform.windows; interaction tests for touch and keyboard.

## Dependency order
1. Flutter CI workflow on GitHub Actions (`flutter test`, `flutter build windows --release`), Linux Docker test and Android debug build. iPad support enabled. Inspect already generated `AppStore/icon.png` wired into Windows `.ico`, Android and iOS icon assets.
2. Pure Dart move, room, carton, event/history model and ID uniqueness; deterministic tests.
3. Local store and complete packing, arrival, searching, priority and reversible unpacking workflow.
4. Adaptive platform-authentic UI with width, input, accessibility and platform screenshot tests.
5. Validated import/export, backup recovery and privacy controls.
6. Integration tests; verify `AppStore/description.txt` matches implemented features; release Windows ZIP via `.github/workflows/release.yml` on `windows-latest`, `v*` tags/manual dispatch.

## Distribution
Windows portable ZIP attached to GitHub release. Android Play and iOS TestFlight later opt-in milestones. Secret names ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8, ASC_TEAM_ID already configured, values never logged. App Store Connect bundle-ID registration blocked by `FORBIDDEN_ERROR.PLA_NOT_ACCEPTED`; manual agreement acceptance required. `com.infinityball.movemark` remains required across Android and iOS and any Windows/MSIX identity.

## Risks and limits
No cross-device synchronization, so concurrent edits after export need deliberate reconciliation; don't overwrite without preview. Local data lost if user deletes app without backup. Box status is manual, not location evidence. No QR reader, cloud account, household collaboration, carrier tracking, item valuation or moving services. Store copy must not imply planned features exist. Windows build and UI behavior require real runner evidence; Linux-only checks do not prove them.
