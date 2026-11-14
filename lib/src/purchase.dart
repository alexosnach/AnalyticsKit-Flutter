import 'package:flutter/foundation.dart';

import 'analytics_value.dart';
import 'destinations.dart';

/// A completed purchase, as revenue analytics records it.
///
/// Independent of any store plugin: the app converts its own purchase type
/// (`in_app_purchase`, RevenueCat, a web checkout, …) into a `Purchase` at its
/// boundary.
///
/// Create it from a confirmed store purchase. Don't create one for a free
/// trial with no charge: report that as an event.
@immutable
class Purchase {
  const Purchase({
    required this.productID,
    required this.transactionID,
    required this.price,
    required this.currency,
    this.quantity = 1,
    this.parameters = const {},
    this.destinations = Destinations.all,
  });

  /// The store's product identifier, e.g. `"premium_yearly"`.
  final String productID;

  /// The store's unique ID of this transaction; lets providers drop duplicates.
  final String transactionID;

  /// Price of one unit.
  ///
  /// A `double`, because Dart has no built-in decimal type and the Flutter
  /// plugins of Firebase, Amplitude and AppsFlyer take revenue as `double`.
  final double price;

  /// ISO 4217 currency code, e.g. `"USD"`.
  final String currency;

  /// Units bought; 1 for subscriptions.
  final int quantity;

  /// Extra values for providers that accept them, e.g. `is_trial`.
  final AnalyticsParameters parameters;

  /// Which revenue-tracking providers receive it; every one by default.
  final Destinations destinations;

  /// `price × quantity`.
  double get revenue => price * quantity;

  @override
  bool operator ==(Object other) =>
      other is Purchase &&
      other.productID == productID &&
      other.transactionID == transactionID &&
      other.price == price &&
      other.currency == currency &&
      other.quantity == quantity &&
      mapEquals(other.parameters, parameters) &&
      other.destinations == destinations;

  @override
  int get hashCode => Object.hash(
        productID,
        transactionID,
        price,
        currency,
        quantity,
        Object.hashAllUnordered(
            parameters.entries.map((e) => Object.hash(e.key, e.value))),
        destinations,
      );

  @override
  String toString() =>
      'Purchase($productID, $transactionID, $price $currency × $quantity)';
}
