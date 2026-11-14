import 'purchase.dart';
import 'analytics_value.dart';
import 'analytics_event.dart';
import 'analytics_service.dart';
import 'identifier_hasher.dart';

/// Does nothing: for tests and as the default of `AnalyticsScope`.
class NoOpAnalytics implements AnalyticsService {
  const NoOpAnalytics();

  @override
  void track(AnalyticsEvent event) {}

  @override
  void trackPurchase(Purchase purchase) {}

  @override
  void setUserID(HashedUserID id) {}

  @override
  void setUserProperties(AnalyticsParameters properties) {}

  @override
  void reset() {}
}
