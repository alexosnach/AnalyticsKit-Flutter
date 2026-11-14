import 'package:flutter/foundation.dart';

import 'analytics_value.dart';

/// Something that happened in the app: a name and typed parameters.
@immutable
class AnalyticsEvent {
  const AnalyticsEvent({required this.name, this.parameters = const {}});

  final String name;
  final AnalyticsParameters parameters;

  @override
  bool operator ==(Object other) =>
      other is AnalyticsEvent &&
      other.name == name &&
      mapEquals(other.parameters, parameters);

  @override
  int get hashCode => Object.hash(
      name,
      Object.hashAllUnordered(
          parameters.entries.map((e) => Object.hash(e.key, e.value))));

  @override
  String toString() => 'AnalyticsEvent($name, $parameters)';
}
