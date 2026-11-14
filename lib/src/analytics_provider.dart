import 'analytics_event.dart';
import 'analytics_value.dart';
import 'identifier_hasher.dart';
import 'provider_id.dart';

/// One analytics system plugged into the app: Amplitude, Firebase, the console.
///
/// Only `CompositeAnalytics` calls it; the rest of the app uses
/// `AnalyticsService`. The two have similar methods today, but they serve
/// different callers, so each can grow without touching the other.
///
/// An implementation adapts these calls to its SDK: names, value types and
/// limits of the SDK stay inside that one file. Keep adapters in the app (or
/// a package of their own), not in this package.
///
/// To add an analytics system:
/// 1. Declare its ID: `static const mixpanel = ProviderID('mixpanel');`.
/// 2. Write a class that implements `AnalyticsProvider`; add `RevenueTracking`
///    if its SDK records revenue, `ScreenTracking` if it has a screen API
///    (otherwise screens arrive in [track] as `screen_view` events).
/// 3. Add it to the `CompositeAnalytics` list in the Composition Root.
///
/// Nothing else changes.
abstract interface class AnalyticsProvider {
  /// Which `Destinations` this provider matches. Declare it as a constant
  /// [ProviderID] next to the adapter and return it here; it must be unique
  /// among the providers of one composite.
  ProviderID get id;

  /// Sends the event to the SDK. Called only for events whose destinations
  /// include [id]. Map [AnalyticsEvent.parameters] with `plainValues` if the
  /// SDK takes `Map<String, Object>`.
  void track(AnalyticsEvent event);

  /// Sets the SDK's user ID. `id.value` is the hash, never the raw ID.
  void setUserID(HashedUserID id);

  /// Sets the SDK's user properties, or does nothing if it has none.
  void setUserProperties(AnalyticsParameters properties);

  /// Clears the SDK's user ID and properties, or does nothing if it can't.
  void reset();
}
