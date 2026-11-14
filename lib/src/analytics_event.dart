import 'package:flutter/foundation.dart';

import 'analytics_value.dart';
import 'destinations.dart';

/// Something that happened in the app: a name, typed parameters and the
/// providers it goes to.
@immutable
class AnalyticsEvent {
  const AnalyticsEvent({
    required this.name,
    this.parameters = const {},
    this.destinations = Destinations.all,
  });

  final String name;
  final AnalyticsParameters parameters;

  /// Which providers receive the event; every one by default.
  final Destinations destinations;

  @override
  bool operator ==(Object other) =>
      other is AnalyticsEvent &&
      other.name == name &&
      mapEquals(other.parameters, parameters) &&
      other.destinations == destinations;

  @override
  int get hashCode => Object.hash(
        name,
        Object.hashAllUnordered(
            parameters.entries.map((e) => Object.hash(e.key, e.value))),
        destinations,
      );

  @override
  String toString() => 'AnalyticsEvent($name, $parameters, $destinations)';
}
