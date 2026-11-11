import 'package:analytics_kit/analytics_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'test_doubles.dart';

void main() {
  const hasher = SHA256IdentifierHasher();

  group('AnalyticsEvent', () {
    test('has no parameters by default', () {
      const event = AnalyticsEvent(name: 'app_opened');

      expect(event.name, 'app_opened');
      expect(event.parameters, isEmpty);
    });

    test('keeps the given parameters', () {
      const event = AnalyticsEvent(
        name: 'paywall_shown',
        parameters: {'source': 'onboarding'},
      );

      expect(event.parameters['source'], 'onboarding');
    });
  });

  group('CompositeAnalytics', () {
    test('sends every call to every provider in order', () {
      final first = SpyAnalyticsProvider();
      final second = SpyAnalyticsProvider();
      final analytics = CompositeAnalytics(providers: [first, second]);
      final id = hasher.hash('user');

      analytics.track(const AnalyticsEvent(name: 'app_opened', parameters: {'n': 1}));
      analytics.setUserID(id);
      analytics.setUserProperties({'is_premium': true});
      analytics.reset();

      final expected = [
        'track app_opened {n: 1}',
        'setUserID ${id.value}',
        'setUserProperties {is_premium: true}',
        'reset',
      ];
      expect(first.calls, expected);
      expect(second.calls, expected);
    });

    test('calls providers in the order of the list', () {
      final order = <String>[];
      final analytics = CompositeAnalytics(providers: [
        _NamedProvider('first', order),
        _NamedProvider('second', order),
        _NamedProvider('third', order),
      ]);

      analytics.track(const AnalyticsEvent(name: 'app_opened'));

      expect(order, ['first', 'second', 'third']);
    });

    test('works with no providers', () {
      final analytics = CompositeAnalytics(providers: []);

      analytics.track(const AnalyticsEvent(name: 'app_opened'));
      analytics.reset();
    });

    test('each provider gets the same unchanged event', () {
      final spies = List.generate(3, (_) => SpyAnalyticsProvider());
      final analytics = CompositeAnalytics(providers: spies);

      analytics.track(const AnalyticsEvent(name: 'purchase', parameters: {'price': 9.99}));

      for (final spy in spies) {
        expect(spy.calls, ['track purchase {price: 9.99}']);
      }
    });

    test('a list changed later does not change the providers', () {
      final spy = SpyAnalyticsProvider();
      final providers = <AnalyticsProvider>[];
      final analytics = CompositeAnalytics(providers: providers);

      providers.add(spy);
      analytics.track(const AnalyticsEvent(name: 'app_opened'));

      expect(spy.calls, isEmpty);
    });
  });

  group('SHA256IdentifierHasher', () {
    test('matches the known SHA-256 of abc', () {
      expect(
        hasher.hash('abc').value,
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });

    // Text is hashed as UTF-8, so the same input gives the same ID on iOS,
    // Android and Flutter.
    test('hashes non-ASCII text as UTF-8', () {
      expect(
        hasher.hash('привет').value,
        'e58f1e8c55fa105bdd3f40e5037eb0b039b5998d52c05e6cd98878dd2da5cab2',
      );
    });

    test('is lowercase hex of 64 characters', () {
      final value = hasher.hash('8fc10609-b5a6-4c45-a2a0-8b340468e611').value;

      expect(value, matches(RegExp(r'^[0-9a-f]{64}$')));
    });

    test('same input gives same hash', () {
      expect(hasher.hash('user'), hasher.hash('user'));
    });

    test('different inputs give different hashes', () {
      expect(hasher.hash('user-1'), isNot(hasher.hash('user-2')));
    });

    test('never returns the raw ID', () {
      expect(hasher.hash('raw-id').value, isNot('raw-id'));
    });
  });

  group('AnonymousUserIDProvider', () {
    test('creates and saves an ID on first launch', () {
      final store = InMemoryUserIDStore();
      final provider = AnonymousUserIDProvider(store: store, hasher: hasher);

      final id = provider.currentUserID();

      expect(store.saved, isNotNull);
      expect(id, hasher.hash(store.saved!));
    });

    // The same form on every platform: 8fc10609-b5a6-4c45-a2a0-8b340468e611.
    test('saves the ID as a lowercase version 4 UUID', () {
      for (var i = 0; i < 200; i++) {
        final store = InMemoryUserIDStore();

        AnonymousUserIDProvider(store: store, hasher: hasher).currentUserID();

        expect(
          store.saved,
          matches(RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          )),
        );
      }
    });

    test('makes a different ID for every install', () {
      final ids = <String>{};
      for (var i = 0; i < 200; i++) {
        final store = InMemoryUserIDStore();
        AnonymousUserIDProvider(store: store, hasher: hasher).currentUserID();
        ids.add(store.saved!);
      }

      expect(ids, hasLength(200));
    });

    test('reuses the saved ID', () {
      final store = InMemoryUserIDStore(saved: 'existing-id');
      final provider = AnonymousUserIDProvider(store: store, hasher: hasher);

      expect(provider.currentUserID(), hasher.hash('existing-id'));
      expect(store.saveCount, 0);
    });

    test('gives the same ID on every call', () {
      final store = InMemoryUserIDStore();
      final provider = AnonymousUserIDProvider(store: store, hasher: hasher);

      final first = provider.currentUserID();
      final second = provider.currentUserID();

      expect(first, second);
      expect(store.saveCount, 1);
    });

    test('still gives an ID when saving fails', () {
      final store = InMemoryUserIDStore(keepsSaves: false);
      final provider = AnonymousUserIDProvider(store: store, hasher: hasher);

      final id = provider.currentUserID();

      expect(id.value, hasLength(64));
      expect(store.saveCount, 1);
    });

    test('sends only the hash, not the raw ID', () {
      final store = InMemoryUserIDStore(saved: 'raw-id');
      final provider = AnonymousUserIDProvider(store: store, hasher: hasher);

      expect(provider.currentUserID().value, isNot('raw-id'));
    });
  });

  // The plugin with its in-memory backend. The example app's integration
  // tests run the same store against the real storage of a device.
  group('SharedPreferencesUserIDStore', () {
    Future<SharedPreferences> preferences([Map<String, Object> values = const {}]) {
      SharedPreferences.setMockInitialValues(values);
      return SharedPreferences.getInstance();
    }

    test('has no ID before the first save', () async {
      final failures = <UserIDStoreFailure>[];
      final store = SharedPreferencesUserIDStore(await preferences(), onError: failures.add);

      expect(store.load(), isNull);
      expect(failures, isEmpty, reason: 'A missing ID is not a failure');
    });

    test('loads what was saved, without waiting', () async {
      final store = SharedPreferencesUserIDStore(await preferences());

      store.save('first-id');

      expect(store.load(), 'first-id');
    });

    test('replaces a saved ID', () async {
      final store = SharedPreferencesUserIDStore(await preferences());

      store.save('first-id');
      store.save('second-id');

      expect(store.load(), 'second-id');
    });

    test('another store with the same preferences sees the ID', () async {
      final shared = await preferences();

      SharedPreferencesUserIDStore(shared).save('shared-id');

      expect(SharedPreferencesUserIDStore(shared).load(), 'shared-id');
    });

    test('stores with different keys do not see each other', () async {
      final shared = await preferences();

      SharedPreferencesUserIDStore(shared, key: 'a').save('id-a');

      expect(SharedPreferencesUserIDStore(shared, key: 'b').load(), isNull);
    });

    test('reports a read failure when the key holds another type', () async {
      final failures = <UserIDStoreFailure>[];
      final store = SharedPreferencesUserIDStore(
        await preferences({'analytics.user_id': 42}),
        onError: failures.add,
      );

      expect(store.load(), isNull);
      expect(failures, hasLength(1));
      expect(failures.single.operation, 'read');
      expect('${failures.single}', 'SharedPreferences read failed: expected a String, found int');
    });

    test('reports a write failure and keeps the ID for this launch', () async {
      final shared = await preferences();
      SharedPreferencesStorePlatform.instance = _FailingStore();
      final failures = <UserIDStoreFailure>[];
      final store = SharedPreferencesUserIDStore(shared, onError: failures.add);

      store.save('id');
      await pumpEventQueue();

      expect(failures, hasLength(1));
      expect(failures.single.operation, 'write');
      expect(store.load(), 'id');
    });

    test('the anonymous provider keeps its ID in the store', () async {
      final shared = await preferences();

      final first = AnonymousUserIDProvider(
        store: SharedPreferencesUserIDStore(shared),
        hasher: hasher,
      ).currentUserID();
      final second = AnonymousUserIDProvider(
        store: SharedPreferencesUserIDStore(shared),
        hasher: hasher,
      ).currentUserID();

      expect(first, second);
      expect(first, hasher.hash(shared.getString('analytics.user_id')!));
    });
  });

  group('UserIDStoreFailure', () {
    test('keeps the cause', () {
      expect(const UserIDStoreFailure.read('boom').cause, 'boom');
      expect(const UserIDStoreFailure.write().cause, isNull);
    });

    test('describes the operation and the cause', () {
      expect('${const UserIDStoreFailure.read('boom')}', 'SharedPreferences read failed: boom');
      expect('${const UserIDStoreFailure.write()}', 'SharedPreferences write failed');
      expect('${const UserIDStoreFailure.write('disk full')}', 'SharedPreferences write failed: disk full');
    });
  });

  group('NoOpAnalytics', () {
    test('accepts every call', () {
      const AnalyticsService analytics = NoOpAnalytics();

      analytics.track(const AnalyticsEvent(name: 'app_opened'));
      analytics.setUserID(hasher.hash('user'));
      analytics.setUserProperties({'is_premium': true});
      analytics.reset();
    });
  });

  group('AnalyticsScope', () {
    testWidgets('defaults to NoOpAnalytics', (tester) async {
      late EventTracking found;

      await tester.pumpWidget(Builder(builder: (context) {
        found = AnalyticsScope.of(context);
        return const SizedBox();
      }));

      expect(found, isA<NoOpAnalytics>());
    });

    testWidgets('gives the analytics of the scope', (tester) async {
      final spy = SpyAnalyticsProvider();
      final analytics = CompositeAnalytics(providers: [spy]);

      await tester.pumpWidget(AnalyticsScope(
        analytics: analytics,
        child: Builder(builder: (context) {
          AnalyticsScope.of(context).track(const AnalyticsEvent(name: 'screen_shown'));
          return const SizedBox();
        }),
      ));

      expect(spy.calls, ['track screen_shown {}']);
    });
  });
}

class _NamedProvider implements AnalyticsProvider {
  _NamedProvider(this.name, this.order);

  final String name;
  final List<String> order;

  @override
  void track(AnalyticsEvent event) => order.add(name);

  @override
  void setUserID(HashedUserID id) {}

  @override
  void setUserProperties(Map<String, Object> properties) {}

  @override
  void reset() {}
}

/// A storage whose writes always fail.
class _FailingStore extends InMemorySharedPreferencesStore {
  _FailingStore() : super.empty();

  @override
  Future<bool> setValue(String valueType, String key, Object value) async => false;
}
