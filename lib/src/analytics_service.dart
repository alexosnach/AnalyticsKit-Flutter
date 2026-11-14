import 'screen_view.dart';
import 'purchase.dart';
import 'analytics_value.dart';
import 'analytics_event.dart';
import 'identifier_hasher.dart';

/// What screens and features get: they can send events and nothing else.
abstract interface class EventTracking {
  void track(AnalyticsEvent event);
}

/// Reports which screens the user opens.
///
/// The app calls it on the service. A provider implements it only when its SDK
/// has its own screen API; every other provider receives
/// [ScreenView.fallbackEvent] through [EventTracking.track].
abstract interface class ScreenTracking {
  void trackScreen(ScreenView screen);
}

/// What the UI gets through `AnalyticsScope`: events and screens, nothing else.
abstract interface class UiAnalytics implements EventTracking, ScreenTracking {}

/// Records revenue.
///
/// The app calls it on the service; a provider implements it only when its SDK
/// records revenue. Providers that don't simply never see purchases.
abstract interface class RevenueTracking {
  void trackPurchase(Purchase purchase);
}

/// Says who the user is. Used in the Composition Root, not in the UI.
abstract interface class UserIdentification {
  void setUserID(HashedUserID id);
  void setUserProperties(AnalyticsParameters properties);
  void reset();
}

/// The analytics the app uses: [EventTracking] and [UserIdentification] together.
abstract interface class AnalyticsService
    implements UiAnalytics, RevenueTracking, UserIdentification {}
