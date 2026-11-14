import 'package:analytics_kit/analytics_kit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_doubles.dart';

const firebaseID = ProviderID('firebase');
const amplitudeID = ProviderID('amplitude');
const uxCamID = ProviderID('uxcam');

void main() {
  group('ScreenView', () {
    test('defaults to no class, no parameters, every provider', () {
      const screen = ScreenView(name: 'home');

      expect(screen.screenClass, isNull);
      expect(screen.parameters, isEmpty);
      expect(screen.destinations, Destinations.all);
    });

    test('fallback event carries name, class and parameters', () {
      const screen = ScreenView(
        name: 'paywall',
        screenClass: 'PaywallScreen',
        parameters: {'source': AnalyticsValue.string('settings')},
        destinations: Destinations.only({amplitudeID}),
      );

      expect(
        screen.fallbackEvent,
        const AnalyticsEvent(
          name: 'screen_view',
          parameters: {
            'screen_name': AnalyticsValue.string('paywall'),
            'screen_class': AnalyticsValue.string('PaywallScreen'),
            'source': AnalyticsValue.string('settings'),
          },
          destinations: Destinations.only({amplitudeID}),
        ),
      );
    });

    test('fallback event omits a missing class', () {
      expect(
        const ScreenView(name: 'home').fallbackEvent.parameters,
        {'screen_name': const AnalyticsValue.string('home')},
      );
    });

    test('screen name wins over a parameter with the same key', () {
      const screen = ScreenView(
          name: 'home',
          parameters: {'screen_name': AnalyticsValue.string('other')});

      expect(screen.fallbackEvent.parameters['screen_name'],
          const AnalyticsValue.string('home'));
    });
  });

  group('CompositeAnalytics screens', () {
    late SpyScreenProvider firebase;
    late SpyAnalyticsProvider amplitude;
    late SpyScreenProvider uxCam;
    late CompositeAnalytics analytics;

    setUp(() {
      firebase = SpyScreenProvider(firebaseID);
      amplitude = SpyAnalyticsProvider(amplitudeID);
      uxCam = SpyScreenProvider(uxCamID);
      analytics = CompositeAnalytics(providers: [firebase, amplitude, uxCam]);
    });

    test('providers with a screen API use it', () {
      const screen = ScreenView(name: 'home', screenClass: 'HomeScreen');

      analytics.trackScreen(screen);

      expect(firebase.screens, [screen]);
      expect(uxCam.screens, [screen]);
    });

    test("providers with a screen API don't also get the fallback event", () {
      analytics.trackScreen(const ScreenView(name: 'home'));

      expect(firebase.calls, isEmpty);
      expect(uxCam.calls, isEmpty);
    });

    test('providers without a screen API get the fallback event', () {
      analytics.trackScreen(
          const ScreenView(name: 'home', screenClass: 'HomeScreen'));

      expect(amplitude.calls,
          ['track screen_view {screen_name: home, screen_class: HomeScreen}']);
    });

    test('screens follow their destinations', () {
      analytics.trackScreen(const ScreenView(
          name: 'home', destinations: Destinations.only({amplitudeID})));

      expect(amplitude.calls, ['track screen_view {screen_name: home}']);
      expect(firebase.screens, isEmpty);
      expect(uxCam.screens, isEmpty);
    });

    test('except skips a provider with a screen API', () {
      const screen = ScreenView(
          name: 'home', destinations: Destinations.except({uxCamID}));

      analytics.trackScreen(screen);

      expect(firebase.screens, [screen]);
      expect(uxCam.screens, isEmpty);
      expect(amplitude.calls, hasLength(1));
    });
  });
}
