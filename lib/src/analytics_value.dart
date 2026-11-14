/// One value an event or a user property carries.
///
/// Analytics SDKs accept only a handful of scalar types; this type lists
/// exactly those, so a value an SDK can't serialise never compiles. Every
/// value is immutable, so it can be sent to another isolate.
///
/// ```dart
/// const {'source': AnalyticsValue.string('onboarding'), 'step': AnalyticsValue.int(2)}
/// ```
sealed class AnalyticsValue {
  const AnalyticsValue();

  /// A text value.
  const factory AnalyticsValue.string(String value) = StringValue;

  /// A whole number.
  const factory AnalyticsValue.int(int value) = IntValue;

  /// A fractional number.
  const factory AnalyticsValue.double(double value) = DoubleValue;

  /// A flag.
  const factory AnalyticsValue.bool(bool value) = BoolValue;

  /// The plain Dart value (`String`, `int`, `double` or `bool`), for SDKs
  /// whose APIs take `Object`. Use it inside providers only.
  Object get plainValue;

  @override
  bool operator ==(Object other) =>
      other is AnalyticsValue &&
      other.runtimeType == runtimeType &&
      other.plainValue == plainValue;

  @override
  int get hashCode => Object.hash(runtimeType, plainValue);

  @override
  String toString() => '$plainValue';
}

/// A text value.
final class StringValue extends AnalyticsValue {
  const StringValue(this.value);
  final String value;
  @override
  Object get plainValue => value;
}

/// A whole number.
final class IntValue extends AnalyticsValue {
  const IntValue(this.value);
  final int value;
  @override
  Object get plainValue => value;
}

/// A fractional number.
final class DoubleValue extends AnalyticsValue {
  const DoubleValue(this.value);
  final double value;
  @override
  Object get plainValue => value;
}

/// A flag.
final class BoolValue extends AnalyticsValue {
  const BoolValue(this.value);
  final bool value;
  @override
  Object get plainValue => value;
}

/// Parameters of an event, or a set of user properties.
typedef AnalyticsParameters = Map<String, AnalyticsValue>;

/// Plain values for SDKs whose APIs take `Map<String, Object>`.
extension AnalyticsParametersPlainValues on AnalyticsParameters {
  /// The same map with plain Dart values.
  Map<String, Object> get plainValues =>
      map((key, value) => MapEntry(key, value.plainValue));
}
