import 'package:analytics_kit/analytics_kit.dart';

/// Records every call, in order, in a form tests can compare.
class SpyAnalyticsProvider implements AnalyticsProvider {
  final List<String> calls = [];

  @override
  void track(AnalyticsEvent event) {
    calls.add('track ${event.name} ${event.parameters}');
  }

  @override
  void setUserID(HashedUserID id) {
    calls.add('setUserID ${id.value}');
  }

  @override
  void setUserProperties(Map<String, Object> properties) {
    calls.add('setUserProperties $properties');
  }

  @override
  void reset() {
    calls.add('reset');
  }
}

/// Keeps the ID in memory; can be told to forget every save.
class InMemoryUserIDStore implements UserIDStore {
  /// [keepsSaves] `false` acts like a storage that fails to write.
  InMemoryUserIDStore({this.saved, this.keepsSaves = true});

  String? saved;
  int saveCount = 0;
  final bool keepsSaves;

  @override
  String? load() => saved;

  @override
  void save(String id) {
    saveCount += 1;
    if (keepsSaves) {
      saved = id;
    }
  }
}
