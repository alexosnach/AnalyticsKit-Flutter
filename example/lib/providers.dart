import 'package:analytics_kit/analytics_kit.dart';
import 'package:flutter/foundation.dart';

// Providers belong to the app, not to AnalyticsKit. A real app would have
// an Amplitude or a Firebase provider here, written the same way.

/// Prints every call to the console with the `Analytics` prefix.
class ConsoleAnalyticsProvider implements AnalyticsProvider {
  @override
  void track(AnalyticsEvent event) {
    debugPrint('Analytics: track ${event.name} ${event.parameters}');
  }

  @override
  void setUserID(HashedUserID id) {
    debugPrint('Analytics: setUserID ${id.value}');
  }

  @override
  void setUserProperties(Map<String, Object> properties) {
    debugPrint('Analytics: setUserProperties $properties');
  }

  @override
  void reset() {
    debugPrint('Analytics: reset');
  }
}

/// Keeps the events it received, so the screen can show them.
class RecordingAnalyticsProvider extends ChangeNotifier
    implements AnalyticsProvider {
  final List<AnalyticsEvent> events = [];
  HashedUserID? userID;

  @override
  void track(AnalyticsEvent event) {
    events.add(event);
    notifyListeners();
  }

  @override
  void setUserID(HashedUserID id) {
    userID = id;
  }

  @override
  void setUserProperties(Map<String, Object> properties) {}

  @override
  void reset() {
    events.clear();
    userID = null;
    notifyListeners();
  }
}
