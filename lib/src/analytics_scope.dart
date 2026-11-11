import 'package:flutter/widgets.dart';

import 'analytics_service.dart';
import 'no_op_analytics.dart';

/// Gives the analytics to the widgets below it.
///
/// ```dart
/// runApp(AnalyticsScope(analytics: analytics, child: const MyApp()));
///
/// final analytics = AnalyticsScope.of(context);
/// analytics.track(const AnalyticsEvent(name: 'subscribe_tapped'));
/// ```
///
/// Widgets get only [EventTracking]: identifying the user stays in the
/// Composition Root.
class AnalyticsScope extends InheritedWidget {
  const AnalyticsScope({
    super.key,
    required this.analytics,
    required super.child,
  });

  final EventTracking analytics;

  /// The analytics of the nearest scope, or [NoOpAnalytics] when there is
  /// none, so widget tests and previews stay silent.
  static EventTracking of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AnalyticsScope>();
    return scope?.analytics ?? const NoOpAnalytics();
  }

  @override
  bool updateShouldNotify(AnalyticsScope oldWidget) =>
      !identical(analytics, oldWidget.analytics);
}
