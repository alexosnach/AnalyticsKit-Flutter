import 'analytics_event.dart';
import 'analytics_service.dart';
import 'analytics_value.dart';
import 'identifier_hasher.dart';
import 'purchase.dart';
import 'screen_view.dart';

/// Analytics that ignores every call.
///
/// Use it in widget tests that don't check analytics and builds that must
/// send nothing (e.g. debug). `AnalyticsScope.of` returns it when there is
/// no scope.
class NoOpAnalytics implements AnalyticsService {
  const NoOpAnalytics();

  /// Does nothing.
  @override
  void track(AnalyticsEvent event) {}

  /// Does nothing.
  @override
  void trackScreen(ScreenView screen) {}

  /// Does nothing.
  @override
  void trackPurchase(Purchase purchase) {}

  /// Does nothing.
  @override
  void setUserID(HashedUserID id) {}

  /// Does nothing.
  @override
  void setUserProperties(AnalyticsParameters properties) {}

  /// Does nothing.
  @override
  void reset() {}
}
