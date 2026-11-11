import 'analytics_event.dart';
import 'identifier_hasher.dart';

/// One analytics system plugged into the app: Amplitude, Firebase, the console.
///
/// Only `CompositeAnalytics` calls it; the rest of the app uses
/// `AnalyticsService`. The two interfaces have the same methods today, but
/// they serve different callers, so each can grow without touching the other.
///
/// An implementation adapts these calls to its SDK: names, value types and
/// limits of the SDK stay inside that one file.
abstract interface class AnalyticsProvider {
  void track(AnalyticsEvent event);
  void setUserID(HashedUserID id);
  void setUserProperties(Map<String, Object> properties);
  void reset();
}
