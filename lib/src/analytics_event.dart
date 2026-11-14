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

  /// Event name as providers show it. Use `snake_case`, at most 40 characters
  /// (the strictest common SDK limit), and keep it stable: dashboards and
  /// funnels are built on it.
  final String name;

  /// Details of this occurrence; none by default. No personal data.
  final AnalyticsParameters parameters;

  /// Which providers receive the event; every one by default. Narrow it for
  /// provider-specific events, e.g. AppsFlyer's `af_*` events:
  /// `Destinations.only({Providers.appsFlyer})`.
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
