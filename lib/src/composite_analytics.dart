import 'analytics_event.dart';
import 'analytics_provider.dart';
import 'analytics_service.dart';
import 'analytics_value.dart';
import 'identifier_hasher.dart';
import 'purchase.dart';
import 'screen_view.dart';

/// The analytics the whole app uses: one [AnalyticsService] that forwards
/// calls to its providers, in their order.
///
/// An event goes only to the providers its [AnalyticsEvent.destinations]
/// include. User identification goes to every provider, so the user is the
/// same person in each analytics system.
///
/// Every call runs synchronously on the caller's isolate; the provider list
/// is copied once and never changes.
///
/// A new analytics system is a new provider in the list the Composition Root
/// builds; this type and the code that calls it do not change.
///
/// ```dart
/// final AnalyticsService analytics = CompositeAnalytics(providers: [
///   AmplitudeAnalyticsProvider(apiKey: '…'),
///   ConsoleAnalyticsProvider(),
/// ]);
/// ```
class CompositeAnalytics implements AnalyticsService {
  /// Builds the service from the providers the app plugs in.
  ///
  /// Create one instance in the Composition Root and inject it everywhere.
  /// Leave a provider out (for example in debug builds or before consent)
  /// and events routed to it are simply dropped. Providers are called in the
  /// order of the list. Those that also implement `RevenueTracking` receive
  /// purchases; the rest only receive events. Those that implement
  /// `ScreenTracking` receive screens through it; the rest receive them as
  /// [ScreenView.fallbackEvent].
  ///
  /// Takes a copy: a list the caller changes later does not change this one.
  CompositeAnalytics({required List<AnalyticsProvider> providers})
      : _providers = List.unmodifiable(providers);

  final List<AnalyticsProvider> _providers;

  /// Forwards the screen to every provider its destinations include: through
  /// the provider's own screen API, or as [ScreenView.fallbackEvent].
  @override
  void trackScreen(ScreenView screen) {
    for (final provider in _providers) {
      if (!screen.destinations.includes(provider.id)) continue;
      if (provider is ScreenTracking) {
        (provider as ScreenTracking).trackScreen(screen);
      } else {
        provider.track(screen.fallbackEvent);
      }
    }
  }

  /// Forwards the purchase to every revenue-tracking provider its destinations include.
  @override
  void trackPurchase(Purchase purchase) {
    for (final provider in _providers) {
      if (provider is RevenueTracking &&
          purchase.destinations.includes(provider.id)) {
        (provider as RevenueTracking).trackPurchase(purchase);
      }
    }
  }

  /// Forwards the event to every provider its destinations include, in order.
  @override
  void track(AnalyticsEvent event) {
    for (final provider in _providers) {
      if (event.destinations.includes(provider.id)) {
        provider.track(event);
      }
    }
  }

  /// Forwards the ID to every provider.
  @override
  void setUserID(HashedUserID id) {
    for (final provider in _providers) {
      provider.setUserID(id);
    }
  }

  /// Forwards the properties to every provider.
  @override
  void setUserProperties(AnalyticsParameters properties) {
    for (final provider in _providers) {
      provider.setUserProperties(properties);
    }
  }

  /// Resets every provider.
  @override
  void reset() {
    for (final provider in _providers) {
      provider.reset();
    }
  }
}
