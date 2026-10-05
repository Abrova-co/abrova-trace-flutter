# Changelog

## 0.2.2 - 2026-10-05

First public release.

- Automatic capture of uncaught Flutter and async Dart errors.
- Native crash capture on Android and iOS, reported on the next app start.
- Manual `captureException` and `captureMessage`, with user id, tags and extra data.
- Breadcrumbs: manual, navigation (`AbrovaTraceNavigatorObserver`), taps and HTTP requests.
- Batched app logging with levels from trace to fatal.
- Performance monitoring: HTTP request tracing for the `http` package and `trackOperation` for your own code.
- Device, OS and app details attached to events, and offline storage of errors on Android and iOS.
