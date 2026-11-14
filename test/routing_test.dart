import 'package:analytics_kit/analytics_kit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_doubles.dart';

const amplitudeID = ProviderID('amplitude');
const appsFlyerID = ProviderID('appsflyer');
const firebaseID = ProviderID('firebase');
const notPluggedInID = ProviderID('not_plugged_in');

void main() {
  group('Destinations', () {
    test('all includes every provider', () {
      expect(Destinations.all.includes(amplitudeID), isTrue);
      expect(Destinations.all.includes(notPluggedInID), isTrue);
    });

    test('only includes just the listed providers', () {
      const destinations = Destinations.only({appsFlyerID});

      expect(destinations.includes(appsFlyerID), isTrue);
      expect(destinations.includes(amplitudeID), isFalse);
    });

    test('except includes every provider but the listed', () {
      const destinations = Destinations.except({appsFlyerID});

      expect(destinations.includes(appsFlyerID), isFalse);
      expect(destinations.includes(amplitudeID), isTrue);
    });

    test('empty only includes no provider', () {
      expect(const Destinations.only({}).includes(amplitudeID), isFalse);
    });
  });

  group('CompositeAnalytics routing', () {
    late SpyAnalyticsProvider amplitude;
    late SpyAnalyticsProvider appsFlyer;
    late SpyAnalyticsProvider firebase;
    late CompositeAnalytics analytics;

    setUp(() {
      amplitude = SpyAnalyticsProvider(amplitudeID);
      appsFlyer = SpyAnalyticsProvider(appsFlyerID);
      firebase = SpyAnalyticsProvider(firebaseID);
      analytics =
          CompositeAnalytics(providers: [amplitude, appsFlyer, firebase]);
    });

    test('events go everywhere by default', () {
      analytics.track(const AnalyticsEvent(name: 'app_opened'));

      for (final spy in [amplitude, appsFlyer, firebase]) {
        expect(spy.calls, ['track app_opened {}']);
      }
    });

    test('only reaches just the listed providers', () {
      analytics.track(const AnalyticsEvent(
        name: 'af_complete_registration',
        destinations: Destinations.only({appsFlyerID}),
      ));

      expect(appsFlyer.calls, ['track af_complete_registration {}']);
      expect(amplitude.calls, isEmpty);
      expect(firebase.calls, isEmpty);
    });

    test('except skips the listed providers', () {
      analytics.track(const AnalyticsEvent(
        name: 'screen_view',
        destinations: Destinations.except({appsFlyerID}),
      ));

      expect(amplitude.calls, ['track screen_view {}']);
      expect(firebase.calls, ['track screen_view {}']);
      expect(appsFlyer.calls, isEmpty);
    });

    test('a provider that is not plugged in is silently ignored', () {
      analytics.track(const AnalyticsEvent(
        name: 'x',
        destinations: Destinations.only({notPluggedInID}),
      ));

      for (final spy in [amplitude, appsFlyer, firebase]) {
        expect(spy.calls, isEmpty);
      }
    });

    test('routing keeps the order of events', () {
      analytics.track(const AnalyticsEvent(
          name: 'first', destinations: Destinations.only({amplitudeID})));
      analytics.track(const AnalyticsEvent(
          name: 'second', destinations: Destinations.only({appsFlyerID})));
      analytics.track(const AnalyticsEvent(name: 'third'));

      expect(amplitude.calls, ['track first {}', 'track third {}']);
      expect(appsFlyer.calls, ['track second {}', 'track third {}']);
    });

    test('user identification is never filtered', () {
      final id = const SHA256IdentifierHasher().hash('user');

      analytics.setUserID(id);
      analytics
          .setUserProperties(const {'plan': AnalyticsValue.string('premium')});
      analytics.reset();

      final expected = [
        'setUserID ${id.value}',
        'setUserProperties {plan: premium}',
        'reset'
      ];
      for (final spy in [amplitude, appsFlyer, firebase]) {
        expect(spy.calls, expected);
      }
    });
  });
}
