import 'analytics_event.dart';
import 'identifier_hasher.dart';

/// What screens and features get: they can send events and nothing else.
abstract interface class EventTracking {
  void track(AnalyticsEvent event);
}

/// Says who the user is. Used in the Composition Root, not in the UI.
abstract interface class UserIdentification {
  void setUserID(HashedUserID id);
  void setUserProperties(Map<String, Object> properties);
  void reset();
}

/// The analytics the app uses: [EventTracking] and [UserIdentification] together.
abstract interface class AnalyticsService
    implements EventTracking, UserIdentification {}
