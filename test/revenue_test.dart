import 'package:analytics_kit/analytics_kit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_doubles.dart';

const amplitudeID = ProviderID('amplitude');
const appsFlyerID = ProviderID('appsflyer');
const uxCamID = ProviderID('uxcam');

Purchase makePurchase({Destinations destinations = Destinations.all}) =>
    Purchase(
      productID: 'premium_yearly',
      transactionID: 'GPA.1234-5678',
      price: 39.99,
      currency: 'USD',
      destinations: destinations,
    );

void main() {
  group('Purchase', () {
    test('defaults to one unit without extras for every provider', () {
      final purchase = makePurchase();

      expect(purchase.quantity, 1);
      expect(purchase.parameters, isEmpty);
      expect(purchase.destinations, Destinations.all);
    });

    test('revenue is price times quantity', () {
      const purchase = Purchase(
          productID: 'coins',
          transactionID: 't',
          price: 2.5,
          currency: 'EUR',
          quantity: 3);

      expect(purchase.revenue, 7.5);
    });

    test('compares by value', () {
      expect(makePurchase(), makePurchase());
    });
  });

  group('CompositeAnalytics revenue', () {
    late SpyRevenueProvider amplitude;
    late SpyRevenueProvider appsFlyer;
    late SpyAnalyticsProvider uxCam;
    late CompositeAnalytics analytics;

    setUp(() {
      amplitude = SpyRevenueProvider(amplitudeID);
      appsFlyer = SpyRevenueProvider(appsFlyerID);
      uxCam = SpyAnalyticsProvider(uxCamID);
      analytics = CompositeAnalytics(providers: [amplitude, uxCam, appsFlyer]);
    });

    test('purchases reach every revenue provider', () {
      final purchase = makePurchase();

      analytics.trackPurchase(purchase);

      expect(amplitude.purchases, [purchase]);
      expect(appsFlyer.purchases, [purchase]);
    });

    test(
        'a provider without revenue never sees purchases but still gets events',
        () {
      analytics.trackPurchase(makePurchase());
      analytics.track(const AnalyticsEvent(name: 'paywall_shown'));

      expect(uxCam.calls, ['track paywall_shown {}']);
    });

    test('purchases follow their destinations', () {
      final purchase =
          makePurchase(destinations: const Destinations.only({appsFlyerID}));

      analytics.trackPurchase(purchase);

      expect(appsFlyer.purchases, [purchase]);
      expect(amplitude.purchases, isEmpty);
    });

    test('a purchase is not also sent as an event', () {
      analytics.trackPurchase(makePurchase());

      expect(amplitude.calls, isEmpty);
      expect(appsFlyer.calls, isEmpty);
    });

    test('works without any revenue provider', () {
      CompositeAnalytics(providers: [uxCam]).trackPurchase(makePurchase());

      expect(uxCam.calls, isEmpty);
    });
  });
}
