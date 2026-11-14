import 'package:flutter/foundation.dart';

import 'provider_id.dart';

/// Which providers receive an event.
///
/// An ID of a provider that isn't plugged in is simply never matched: the
/// event goes nowhere for it and nothing fails, so providers can be added or
/// removed in the Composition Root without touching any call site.
@immutable
sealed class Destinations {
  const Destinations();

  /// Every plugged-in provider.
  static const Destinations all = AllDestinations();

  /// Only these providers.
  const factory Destinations.only(Set<ProviderID> ids) = OnlyDestinations;

  /// Every plugged-in provider except these.
  const factory Destinations.except(Set<ProviderID> ids) = ExceptDestinations;

  /// Whether the provider with this ID receives the event.
  bool includes(ProviderID id);
}

/// Every plugged-in provider.
final class AllDestinations extends Destinations {
  const AllDestinations();

  @override
  bool includes(ProviderID id) => true;

  @override
  bool operator ==(Object other) => other is AllDestinations;

  @override
  int get hashCode => (AllDestinations).hashCode;

  @override
  String toString() => 'all';
}

/// Only these providers.
final class OnlyDestinations extends Destinations {
  const OnlyDestinations(this.ids);

  final Set<ProviderID> ids;

  @override
  bool includes(ProviderID id) => ids.contains(id);

  @override
  bool operator ==(Object other) =>
      other is OnlyDestinations && setEquals(other.ids, ids);

  @override
  int get hashCode =>
      Object.hash(OnlyDestinations, Object.hashAllUnordered(ids));

  @override
  String toString() => 'only $ids';
}

/// Every plugged-in provider except these.
final class ExceptDestinations extends Destinations {
  const ExceptDestinations(this.ids);

  final Set<ProviderID> ids;

  @override
  bool includes(ProviderID id) => !ids.contains(id);

  @override
  bool operator ==(Object other) =>
      other is ExceptDestinations && setEquals(other.ids, ids);

  @override
  int get hashCode =>
      Object.hash(ExceptDestinations, Object.hashAllUnordered(ids));

  @override
  String toString() => 'except $ids';
}
