# AnalyticsKit for Flutter

A provider-agnostic analytics layer for Flutter apps: one `AnalyticsService` that fans out to any number of analytics SDKs, with per-event routing, screen and revenue tracking, typed parameters and a hashed, persistent user ID.

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
      ref: 2.0.0
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
  parameters: {'source': AnalyticsValue.string('onboarding')},
));
```

## Typed parameters

Parameters and user properties are `AnalyticsParameters` (`Map<String, AnalyticsValue>`): `AnalyticsValue.string`, `.int`, `.double` or `.bool`. A value an SDK can't serialise doesn't compile. In an adapter, `parameters.plainValues` gives `Map<String, Object>` for SDKs that take `Object`.

## Routing events to providers

Every provider declares its own `ProviderID` next to its adapter — the package has no list of providers, so adding one never changes it:

```dart
abstract final class Providers {
  static const amplitude = ProviderID('amplitude');
  static const appsFlyer = ProviderID('appsflyer');
}
```

An event goes to every provider by default; `destinations` narrows it:

```dart
analytics.track(const AnalyticsEvent(
  name: 'af_complete_registration',
  destinations: Destinations.only({Providers.appsFlyer}),
));
analytics.track(const AnalyticsEvent(
  name: 'tutorial_finished',
  destinations: Destinations.except({Providers.appsFlyer}),
));
```

An ID of a provider that isn't plugged in is simply never matched. User identification (`setUserID`, `setUserProperties`, `reset`) always reaches every provider.

## Screens

SDKs' automatic screen tracking sees routes or the Flutter activity, not your screens, so report them yourself — once each time a screen becomes visible (from `initState` or a route observer, not from `build`):

```dart
analytics.trackScreen(const ScreenView(name: 'paywall', screenClass: 'PaywallScreen'));
```

Implementing `ScreenTracking` in a provider is optional. A provider whose SDK has a screen API implements it and receives the `ScreenView`; every other provider automatically receives a `screen_view` event with `screen_name` and `screen_class`, so no screen is lost and nothing has to be implemented:

```dart
class FirebaseAnalyticsProvider implements AnalyticsProvider, ScreenTracking {
  // …
  @override
  void trackScreen(ScreenView screen) {
    FirebaseAnalytics.instance.logScreenView(
      screenName: screen.name,
      screenClass: screen.screenClass ?? screen.name,
    );
  }
}
```

`destinations` works the same as for events.

## Revenue

```dart
analytics.trackPurchase(Purchase(
  productID: 'premium_yearly',
  transactionID: details.purchaseID ?? '',
  price: 39.99,                     // one unit
  currency: 'USD',                  // ISO 4217
  destinations: Destinations.all,   // or Destinations.only({...})
));
```

`Purchase` doesn't depend on `in_app_purchase` — convert your purchase type in the app. Only providers that also implement `RevenueTracking` receive purchases; the others don't implement anything:

```dart
class AmplitudeAnalyticsProvider implements AnalyticsProvider, RevenueTracking {
  // …
  @override
  void trackPurchase(Purchase purchase) {
    amplitude.revenue(Revenue()
      ..productId = purchase.productID
      ..price = purchase.price
      ..quantity = purchase.quantity);
  }
}
```

`price` is a `double`: Dart has no built-in decimal type, and the Flutter plugins of Firebase, Amplitude and AppsFlyer take revenue as `double` anyway. The Swift and Android libraries use `Decimal` and `BigDecimal`.

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

Widgets get only `UiAnalytics` (`track`, `trackScreen`); identifying the user and revenue stay out of the UI.

## Writing a provider

A provider adapts AnalyticsKit calls to one SDK. Keep it in your app:

```dart
import 'package:analytics_kit/analytics_kit.dart';
import 'package:flutter/foundation.dart';

class ConsoleAnalyticsProvider implements AnalyticsProvider {
  @override
  ProviderID get id => const ProviderID('console');

  @override
  void track(AnalyticsEvent event) {
    debugPrint('Analytics: track ${event.name} ${event.parameters}');
  }

  @override
  void setUserID(HashedUserID id) {
    debugPrint('Analytics: setUserID ${id.value}');
  }

  @override
  void setUserProperties(AnalyticsParameters properties) {
    debugPrint('Analytics: setUserProperties $properties');
  }

  @override
  void reset() {
    debugPrint('Analytics: reset');
  }
}
```

A provider for Amplitude or Firebase has the same `id` and four methods and calls the SDK in each; use `event.parameters.plainValues` where the SDK takes `Map<String, Object>`.

Adding another analytics system = one more provider (with its `ProviderID`) in the `CompositeAnalytics` list. Nothing in the package or at call sites changes.

The [`example`](example) app has two small providers and a full Composition Root.

## User ID

- `HashedUserID` can only be created by an `IdentifierHasher` of this package (its constructor is private), so a raw ID can never reach analytics by mistake.
- `SHA256IdentifierHasher` hashes the UTF-8 bytes to lowercase hex — the same input gives the same ID as the Swift and the Android libraries.
- `AnonymousUserIDProvider` generates a random ID on first launch (a lowercase UUID, the same form as in the Swift and the Android libraries) and keeps it in a `UserIDStore`.
- `SharedPreferencesUserIDStore` keeps the raw ID with the `shared_preferences` plugin. Storage failures are reported to `onError` and never crash the app.
- When your app gets accounts, replace the provider with one that hashes the backend ID — calling code stays the same.

### Differences from the native libraries

- **Threads.** The Swift library marks its types `Sendable`; the Kotlin one documents them as thread-safe. Dart runs each isolate on one thread, so every call simply runs on the caller's isolate; events, screens and purchases are immutable, so they can also be sent to another isolate.

- **Where the ID lives.** The Swift library keeps it in the Keychain, where it survives a reinstall. Here it is in `UserDefaults` on iOS and `SharedPreferences` on Android: removing the app removes the ID, and it comes back only through the system backup. For another policy implement `UserIDStore` yourself (two methods).
- **When it is written.** `save` keeps the ID in memory at once and writes it to disk in the background; the native libraries write before they return. If the process dies in the first moments after the very first launch, the next launch makes a new ID.
- **A Flutter app and a native app do not share an ID**, even on the same device: each keeps its own.

## API

| Type | Purpose |
|---|---|
| `AnalyticsService` | `UiAnalytics` + `RevenueTracking` + `UserIdentification` — what the app uses |
| `UiAnalytics` | `EventTracking` + `ScreenTracking` — what widgets get |
| `AnalyticsProvider` | What an SDK adapter implements (with its `id`) |
| `ScreenTracking`, `ScreenView` | `trackScreen` — optional for providers; others get a `screen_view` event |
| `RevenueTracking` | `trackPurchase` — implemented by providers whose SDK records revenue |
| `CompositeAnalytics` | Forwards calls to providers, in order, honouring `destinations` |
| `NoOpAnalytics` | Does nothing (tests) |
| `AnalyticsEvent` | `name` + `parameters` + `destinations` |
| `Purchase` | Store-agnostic purchase: product, transaction, price, currency, quantity |
| `AnalyticsValue`, `AnalyticsParameters` | Typed, immutable values |
| `ProviderID`, `Destinations` | Which providers receive an event, screen or purchase |
| `HashedUserID`, `IdentifierHasher`, `SHA256IdentifierHasher` | Safe user IDs |
| `UserIDProvider`, `AnonymousUserIDProvider` | Where the user ID comes from |
| `UserIDStore`, `SharedPreferencesUserIDStore`, `UserIDStoreFailure` | Where the raw ID is persisted |
| `AnalyticsScope` | `UiAnalytics` for widgets |

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
