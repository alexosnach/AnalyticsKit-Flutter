/// One thing that happened in the app: a name and the values that describe it.
class AnalyticsEvent {
  const AnalyticsEvent({required this.name, this.parameters = const {}});

  final String name;
  final Map<String, Object> parameters;

  @override
  String toString() => 'AnalyticsEvent($name, $parameters)';
}
