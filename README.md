# AnalyticsKit for Flutter

A provider-agnostic analytics layer for Flutter apps: one `AnalyticsService` that fans out to any number of analytics SDKs, plus a hashed, persistent user ID.

The Dart counterpart of [AnalyticsKit for Swift](https://github.com/alexosnach/AnalyticsKit) and [AnalyticsKit for Android](https://github.com/alexosnach/AnalyticsKit-Android) — same types, same names, same behaviour.

## Requirements

- Dart 3.6+, Flutter 3.27+ (built and tested with Flutter 3.47.9)
- Android and iOS (tested); other platforms that `shared_preferences` supports should work

## Installation

`pubspec.yaml`:

```yaml
dependencies:
  analytics_kit:
    git:
      url: https://github.com/alexosnach/AnalyticsKit-Flutter.git
      ref: 1.0.0
  shared_preferences: ^2.3.0
```

Concrete SDK adapters (Amplitude, Firebase, a console provider, …) are **not** part of this package — they belong to your app. See [Writing a provider](#writing-a-provider).

## Quick start

```dart
import 'package:analytics_kit/analytics_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Composition Root, for example in main()
final AnalyticsService analytics = CompositeAnalytics(providers: [
  AmplitudeAnalyticsProvider(apiKey: '…'), // your app's adapter
  ConsoleAnalyticsProvider(),              // your app's adapter
]);

final preferences = await SharedPreferences.getInstance();
final userIDProvider = AnonymousUserIDProvider(
  store: SharedPreferencesUserIDStore(
    preferences,
    onError: (failure) => debugPrint('$failure'), // or your logger
  ),
  hasher: const SHA256IdentifierHasher(),
);
analytics.setUserID(userIDProvider.currentUserID());

// Tracking
analytics.track(const AnalyticsEvent(
  name: 'paywall_shown',
  parameters: {'source': 'onboarding'},
));
```

## Widgets

`AnalyticsScope` gives the analytics to the widgets below it. Without a scope `AnalyticsScope.of` returns `NoOpAnalytics`, so widget tests stay silent:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final AnalyticsService analytics = /* … */;
  runApp(AnalyticsScope(analytics: analytics, child: const MyApp()));
}

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final analytics = AnalyticsScope.of(context);
    return FilledButton(
      onPressed: () => analytics.track(const AnalyticsEvent(name: 'subscribe_tapped')),
      child: const Text('Subscribe'),
    );
  }
}
```

Widgets get only `EventTracking` (`track`); identifying the user (`UserIdentification`) stays in the Composition Root.

## Writing a provider

A provider adapts AnalyticsKit calls to one SDK. Keep it in your app:

```dart
import 'package:analytics_kit/analytics_kit.dart';
import 'package:flutter/foundation.dart';

class ConsoleAnalyticsProvider implements AnalyticsProvider {
  @override
  void track(AnalyticsEvent event) {
    debugPrint('Analytics: track ${event.name} ${event.parameters}');
  }

  @override
  void setUserID(HashedUserID id) {
    debugPrint('Analytics: setUserID ${id.value}');
  }

  @override
  void setUserProperties(Map<String, Object> properties) {
    debugPrint('Analytics: setUserProperties $properties');
  }

  @override
  void reset() {
    debugPrint('Analytics: reset');
  }
}
```

A provider for Amplitude or Firebase has the same four methods and calls the SDK in each.

Adding another analytics system = adding one more provider to the `CompositeAnalytics` list. Nothing else changes.

The [`example`](example) app has two small providers and a full Composition Root.

## User ID

- `HashedUserID` can only be created by an `IdentifierHasher` of this package (its constructor is private), so a raw ID can never reach analytics by mistake.
- `SHA256IdentifierHasher` hashes the UTF-8 bytes to lowercase hex — the same input gives the same ID as the Swift and the Android libraries.
- `AnonymousUserIDProvider` generates a random ID on first launch (a lowercase UUID, the same form as in the Swift and the Android libraries) and keeps it in a `UserIDStore`.
- `SharedPreferencesUserIDStore` keeps the raw ID with the `shared_preferences` plugin. Storage failures are reported to `onError` and never crash the app.
- When your app gets accounts, replace the provider with one that hashes the backend ID — calling code stays the same.

### Differences from the native libraries

- **Where the ID lives.** The Swift library keeps it in the Keychain, where it survives a reinstall. Here it is in `UserDefaults` on iOS and `SharedPreferences` on Android: removing the app removes the ID, and it comes back only through the system backup. For another policy implement `UserIDStore` yourself (two methods).
- **When it is written.** `save` keeps the ID in memory at once and writes it to disk in the background; the native libraries write before they return. If the process dies in the first moments after the very first launch, the next launch makes a new ID.
- **A Flutter app and a native app do not share an ID**, even on the same device: each keeps its own.

## API

| Type | Purpose |
|---|---|
| `AnalyticsService` | `EventTracking` + `UserIdentification` — what the app uses |
| `AnalyticsProvider` | What an SDK adapter implements |
| `CompositeAnalytics` | Forwards every call to all providers, in order |
| `NoOpAnalytics` | Does nothing (tests) |
| `AnalyticsEvent` | `name` + `parameters` |
| `HashedUserID`, `IdentifierHasher`, `SHA256IdentifierHasher` | Safe user IDs |
| `UserIDProvider`, `AnonymousUserIDProvider` | Where the user ID comes from |
| `UserIDStore`, `SharedPreferencesUserIDStore`, `UserIDStoreFailure` | Where the raw ID is persisted |
| `AnalyticsScope` | `EventTracking` for widgets |

The names match the other two libraries (`setUserID`, `HashedUserID`), not the Dart `Id` convention.

## Running tests

```bash
flutter test
```

On a device or a simulator (the real storage, the example app with real taps):

```bash
cd example
flutter test integration_test
```

## License

MIT — see [LICENSE](LICENSE).
