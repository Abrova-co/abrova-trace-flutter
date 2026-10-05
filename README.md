# Abrova Trace for Flutter

Flutter plugin for Abrova Trace: it reports Dart errors, native Android and iOS crashes, messages, logs and performance data from your app to your Abrova Trace project.

## Requirements

- Dart 3.8.1 or later
- Android: minSdk 19 or later
- iOS: 12.0 or later
- Web: Dart errors, messages, logs and performance work; native crash capture is Android and iOS only

## Install

1. Add the package to `pubspec.yaml`:

```yaml
# pubspec.yaml
dependencies:
  abrova_trace_flutter_sdk:
    hosted: https://center.abrova.ir/api/packages/abrova/pub
    version: ^0.2.5
```

2. Android: the plugin uses the native Android SDK. Add the repository in `android/build.gradle` (or `android/settings.gradle`, wherever your project lists repositories):

```groovy
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url "https://center.abrova.ir/api/packages/abrova/maven" }
    }
}
```

3. iOS: the plugin uses the native iOS SDK. Add this inside the app target in `ios/Podfile`:

```ruby
pod 'AbrovaTrace', :git => 'https://github.com/Abrova-co/abrova-trace-ios-sdk.git', :tag => '0.2.4'
```

Then run `flutter pub get`.

## Quick start

Get your API key from the Abrova console, then wrap your app start in `initWithZone`. Call it before `WidgetsFlutterBinding.ensureInitialized()`.

```dart
import 'package:flutter/material.dart';
import 'package:abrova_trace_flutter_sdk/abrova_trace_flutter_sdk.dart';

Future<void> main() async {
  await AbrovaTrace.initWithZone(
    AbrovaTraceConfig(
      apiKey: 'ab_live_your_api_key',
      environment: 'production',
      release: '1.0.0',
    ),
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      runApp(const MyApp());
    },
  );
}
```

Uncaught Flutter and async errors are now reported as they happen, and native Android and iOS crashes on the next app start.

## Usage

Capture an exception:

```dart
try {
  await checkout();
} catch (e, stackTrace) {
  await AbrovaTrace.captureException(e, stackTrace: stackTrace, extra: {'cart_items': 3});
}
```

Capture a message:

```dart
await AbrovaTrace.captureMessage('Checkout finished', level: MessageLevel.info, tags: {'plan': 'pro'});
```

Set the user and tags sent with every event:

```dart
AbrovaTrace.setUserId('user-123');
AbrovaTrace.setTag('app_variant', 'full');
```

Add a breadcrumb, record taps as breadcrumbs, and track navigation (each route change becomes a breadcrumb):

```dart
AbrovaTrace.addBreadcrumb('Opened cart', type: BreadcrumbType.user, data: {'items': 3});
AbrovaTrace.enableGestureBreadcrumbs(); // call once after init

MaterialApp(navigatorObservers: [AbrovaTraceNavigatorObserver()], home: const HomePage());
```

Send logs (batched; levels: `trace`, `debug`, `info`, `warn`, `logError`, `fatal`):

```dart
AbrovaTrace.enableLogging(sourceId: 'my-flutter-app', sourceName: 'My Flutter App');
AbrovaTrace.info('Order created', metadata: {'order_id': 123});
```

Trace HTTP requests made with the `http` package, and time your own operations:

```dart
final client = AbrovaTrace.createPerformanceClient();
final response = await client.get(Uri.parse('https://api.example.com/data'));
final profile = await AbrovaTrace.trackOperation('fetchUserProfile', () => api.fetchProfile());
```

## Configuration

Options of `AbrovaTraceConfig`:

| Option | Default | Description |
|--------|---------|-------------|
| `apiKey` | required | API key from the Abrova console (`ab_live_...` or `ab_test_...`) |
| `environment` | `'production'` | Environment name |
| `release` | `null` | Your app version |
| `enabled` | `true` | Set to `false` to send nothing |
| `captureUncaughtErrors` | `true` | Report uncaught errors automatically |
| `sampleRate` | `1.0` | Share of errors to send, from 0.0 to 1.0 |
| `maxBreadcrumbs` | `20` | Number of breadcrumbs kept |
| `enableOfflineStorage` | `true` | Store errors while offline and send them later (Android and iOS) |
| `collectDeviceInfo` | `true` | Attach device, OS and app details to events |
| `timeout` | `30` | Request timeout in seconds |
| `debug` | `false` | Print SDK debug logs |
| `apiUrl` | `https://trace.abrova.ir` | Abrova Trace API address |

## License

MIT, see [LICENSE](LICENSE).
