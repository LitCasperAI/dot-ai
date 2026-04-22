# React Native Build and Release

How the app is built, signed, and shipped. This is a bare React
Native project — no Expo, no EAS. Stack-specific expansion of
`global/05-version-control.md` and `global/07-dependencies.md`.

---

## Build system

- **Native projects `ios/` and `android/` are committed to the
  repo** and reviewed like any other code. There is no
  regenerate-from-config step.
- **Release builds are produced by CI**, not on developer
  machines. Local `xcodebuild` / `gradlew` builds are for
  development and debugging only.
- **CI lives in `.github/workflows/`** (or the project's
  declared CI tool). Build, test, and release pipelines are
  reviewed through the same PR process as application code.

## Native changes

- **Podfile, Gemfile, Gradle files, manifests, and
  `Info.plist` are edited deliberately.** A change to any of
  these is called out in the PR description with the reason.
- **`pod install` is run when `Podfile` or a native dependency
  changes.** The resulting `Podfile.lock` is committed.
- **Do not bump Xcode, CocoaPods, Gradle, or the Android SDK
  incidentally.** Toolchain bumps are their own PR, with a note
  on what required the bump.

## Signing and credentials

- **iOS signing uses the team's managed certificates and
  provisioning profiles**, handled through the CI signing
  mechanism (Fastlane Match, or the project's declared
  equivalent). Certificates and `.p12` files are never committed,
  per `global/08-secrets-and-data.md`.
- **Android signing keystores live outside the repo**, pulled
  into CI from secret storage at build time.
- **No credentials in `android/gradle.properties`, `ios/` build
  settings, or any committed file.**

## Versioning

- **App version (marketing version) is bumped deliberately** in
  `ios/<App>/Info.plist` (`CFBundleShortVersionString`) and
  `android/app/build.gradle` (`versionName`). Both are updated
  in the same commit and kept in sync.
- **Build number (`CFBundleVersion`, `versionCode`) is
  incremented by CI** at release time, not by developers in
  feature PRs.
- **Version bumps follow semver.** Breaking changes to public
  surfaces require an ADR, per `global/01-principles.md`.

## Environment configuration

- **Environment-specific config** (API base URLs, Sentry DSN,
  analytics keys) comes from `.env` files consumed by
  `react-native-config` (or the project's declared mechanism),
  loaded through `src/core/` — never read in feature code.
- **`.env` files with real values are not committed**, per
  `global/08-secrets-and-data.md`. An `.env.example` with
  placeholders is committed.
- **Schemes (iOS) and build variants (Android)** map to
  environments — `Debug`, `Staging`, `Release`. A new environment
  is a coordinated change across both platforms plus CI.

## Submissions

- **Store submissions go through CI** using Fastlane (`deliver`
  for App Store Connect, `supply` for Google Play), or the
  project's declared submission tool. Manual Transporter or
  Play Console uploads are an escalation, not a workflow.
- **Release notes are written before submission** and committed
  with the version bump, not pasted ad-hoc into the store
  listing.

## Over-the-air updates

- **This project does not ship OTA JavaScript updates.**
  Adopting an OTA mechanism (CodePush successor, custom bundle
  host, etc.) requires an ADR that covers security review, bundle
  signing, and rollback.
- **Native code changes always require a new store binary.**

## Crash and error reporting

- **Every production build ships with crash reporting wired**
  (Sentry, Bugsnag, or the project's declared provider). A build
  without it is not production.
- **Source maps and dSYMs are uploaded at build time**,
  automated through CI. A build whose symbols did not upload is
  treated as a failed build.
