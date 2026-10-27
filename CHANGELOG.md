# Changelog

## 0.2.6 - 2026-10-27

- Installs with the `pubspec.yaml` line only. Android and iOS need no setup: remove the Abrova Maven repository from `android/build.gradle` and the `AbrovaTrace` line from `ios/Podfile` if you added them for an earlier version.
- Fix: `initWithZone()` no longer prints "Failed to initialize offline storage: Binding has not yet been initialized" at start. Offline storage now sets itself up once the app has started.
- Fix: errors stored offline at the same moment are all kept (before, one could be lost).

## 0.2.5 - 2026-10-06

- Uses native SDKs Android 0.2.3 and iOS 0.2.4: crashes on the Android main thread are reported, app launch on iOS never waits for a crash report, and crash reports are kept when the server or network fails.
- Android: one hang is one ANR report, and no false ANR reports after a crash.
- A report that is sent again is counted once: every error carries an `event_id` that stays the same on each attempt.
- With `initWithZone()`, errors kept while offline are sent on the next start.
- Minimum Android version is API 19.

## 0.2.2 - 2026-10-05

First public release.

- Automatic capture of uncaught Flutter and async Dart errors.
- Native crash capture on Android and iOS, reported on the next app start.
- Manual `captureException` and `captureMessage`, with user id, tags and extra data.
- Breadcrumbs: manual, navigation (`AbrovaTraceNavigatorObserver`), taps and HTTP requests.
- Batched app logging with levels from trace to fatal.
- Performance monitoring: HTTP request tracing for the `http` package and `trackOperation` for your own code.
- Device, OS and app details attached to events, and offline storage of errors on Android and iOS.
