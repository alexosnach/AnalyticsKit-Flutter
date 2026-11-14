import 'package:flutter/foundation.dart';

import 'analytics_event.dart';
import 'analytics_value.dart';
import 'destinations.dart';

/// The user has opened a screen.
///
/// SDKs' automatic screen tracking sees routes or the Flutter activity, not
/// the screens the product team talks about, so the app reports them itself.
@immutable
class ScreenView {
  const ScreenView({
    required this.name,
    this.screenClass,
    this.parameters = const {},
    this.destinations = Destinations.all,
  });

  /// Event name used for providers that have no screen API of their own.
  static const fallbackEventName = 'screen_view';

  /// Fallback parameter key for [name]; the same key Firebase uses.
  static const nameParameter = 'screen_name';

  /// Fallback parameter key for [screenClass]; the same key Firebase uses.
  static const classParameter = 'screen_class';

  /// Stable `snake_case` screen name, e.g. `"paywall"`. Funnels are built on it.
  final String name;

  /// The widget that shows the screen, e.g. `"PaywallScreen"`; optional.
  final String? screenClass;

  /// Details of this visit, e.g. `source`. No personal data.
  final AnalyticsParameters parameters;

  /// Which providers receive it; every one by default.
  final Destinations destinations;

  /// The screen as a plain event, for providers without a screen API:
  /// `screen_view` with `screen_name`, `screen_class` (if set) and
  /// [parameters]. The screen's own keys win over parameters with the same names.
  AnalyticsEvent get fallbackEvent => AnalyticsEvent(
        name: fallbackEventName,
        parameters: {
          ...parameters,
          nameParameter: AnalyticsValue.string(name),
          if (screenClass case final screenClass?)
            classParameter: AnalyticsValue.string(screenClass),
        },
        destinations: destinations,
      );

  @override
  bool operator ==(Object other) =>
      other is ScreenView &&
      other.name == name &&
      other.screenClass == screenClass &&
      mapEquals(other.parameters, parameters) &&
      other.destinations == destinations;

  @override
  int get hashCode => Object.hash(
        name,
        screenClass,
        Object.hashAllUnordered(
            parameters.entries.map((e) => Object.hash(e.key, e.value))),
        destinations,
      );

  @override
  String toString() =>
      'ScreenView($name, $screenClass, $parameters, $destinations)';
}
