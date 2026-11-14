import 'purchase.dart';
import 'analytics_value.dart';
import 'analytics_event.dart';
import 'identifier_hasher.dart';

/// What screens and features get: they can send events and nothing else.
abstract interface class EventTracking {
  void track(AnalyticsEvent event);
}

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
    implements EventTracking, RevenueTracking, UserIdentification {}
