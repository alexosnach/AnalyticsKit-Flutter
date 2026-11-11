import 'analytics_event.dart';
import 'analytics_service.dart';
import 'identifier_hasher.dart';

/// Does nothing: for tests and as the default of `AnalyticsScope`.
class NoOpAnalytics implements AnalyticsService {
  const NoOpAnalytics();

  @override
  void track(AnalyticsEvent event) {}

  @override
  void setUserID(HashedUserID id) {}

  @override
  void setUserProperties(Map<String, Object> properties) {}

  @override
  void reset() {}
}
