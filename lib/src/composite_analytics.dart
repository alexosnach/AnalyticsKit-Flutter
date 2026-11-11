import 'analytics_event.dart';
import 'analytics_provider.dart';
import 'analytics_service.dart';
import 'identifier_hasher.dart';

/// The analytics the whole app uses: one [AnalyticsService] that forwards
/// every call to all its providers, in their order.
///
/// A new analytics system is a new provider in the list the Composition Root
/// builds; this type and the code that calls it do not change.
///
/// ```dart
/// final AnalyticsService analytics = CompositeAnalytics(providers: [
///   AmplitudeAnalyticsProvider(apiKey: '…'),
///   ConsoleAnalyticsProvider(),
/// ]);
/// ```
class CompositeAnalytics implements AnalyticsService {
  /// Takes a copy: a list the caller changes later does not change this one.
  CompositeAnalytics({required List<AnalyticsProvider> providers})
      : _providers = List.unmodifiable(providers);

  final List<AnalyticsProvider> _providers;

  @override
  void track(AnalyticsEvent event) {
    for (final provider in _providers) {
      provider.track(event);
    }
  }

  @override
  void setUserID(HashedUserID id) {
    for (final provider in _providers) {
      provider.setUserID(id);
    }
  }

  @override
  void setUserProperties(Map<String, Object> properties) {
    for (final provider in _providers) {
      provider.setUserProperties(properties);
    }
  }

  @override
  void reset() {
    for (final provider in _providers) {
      provider.reset();
    }
  }
}
