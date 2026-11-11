import 'package:analytics_kit/analytics_kit.dart';
import 'package:analytics_kit_example/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The real app on a device: real providers, real storage, real taps.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const hasher = SHA256IdentifierHasher();

  String text(String key) => (find.byKey(Key(key)).evaluate().single.widget as Text).data!;

  testWidgets('app start identifies the user and tracks app_opened', (tester) async {
    final dependencies = await AppDependencies.create();
    await tester.pumpWidget(ExampleApp(dependencies: dependencies));

    expect(dependencies.recorder.userID, dependencies.userID);
    expect(dependencies.recorder.events.first.name, 'app_opened');
  });

  testWidgets('user ID on screen is the hash of the stored lowercase UUID', (tester) async {
    final dependencies = await AppDependencies.create();
    await tester.pumpWidget(ExampleApp(dependencies: dependencies));

    final preferences = await SharedPreferences.getInstance();
    final raw = SharedPreferencesUserIDStore(preferences).load()!;

    expect(raw, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
    expect(dependencies.userID, hasher.hash(raw));
    expect(dependencies.userID.value, hasLength(64));
    expect(text('user_id'), dependencies.userID.value);
  });

  testWidgets('user ID stays the same after the storage is read from disk again', (tester) async {
    final first = (await AppDependencies.create()).userID;

    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    final second = (await AppDependencies.create()).userID;

    expect(second, first);
  });

  testWidgets('tap on the button sends the event through the composite', (tester) async {
    final dependencies = await AppDependencies.create();
    await tester.pumpWidget(ExampleApp(dependencies: dependencies));
    final before = dependencies.recorder.events.length;

    await tester.tap(find.text('Track event'));
    await tester.tap(find.text('Track event'));
    await tester.pump();

    expect(text('events_count'), 'Events sent: ${before + 2}');
    expect(text('last_event'), 'Last event: button_tapped');
    expect(dependencies.recorder.events.last.name, 'button_tapped');
    expect(dependencies.recorder.events.last.parameters, {'screen': 'example'});
  });

  group('SharedPreferencesUserIDStore on the real storage', () {
    late SharedPreferences preferences;
    late String key;

    setUp(() async {
      preferences = await SharedPreferences.getInstance();
      key = 'tests.analyticskit.${DateTime.now().microsecondsSinceEpoch}';
    });

    tearDown(() => preferences.remove(key));

    testWidgets('has no ID before the first save', (tester) async {
      final failures = <UserIDStoreFailure>[];
      final store = SharedPreferencesUserIDStore(preferences, key: key, onError: failures.add);

      expect(store.load(), isNull);
      expect(failures, isEmpty);
    });

    testWidgets('what was saved is on disk', (tester) async {
      final failures = <UserIDStoreFailure>[];
      SharedPreferencesUserIDStore(preferences, key: key, onError: failures.add).save('first-id');

      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
      await preferences.reload();

      expect(SharedPreferencesUserIDStore(preferences, key: key).load(), 'first-id');
      expect(failures, isEmpty);
    });

    testWidgets('replaces a saved ID', (tester) async {
      final store = SharedPreferencesUserIDStore(preferences, key: key);

      store.save('first-id');
      store.save('second-id');
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
      await preferences.reload();

      expect(store.load(), 'second-id');
    });

    testWidgets('reports a read failure when the key holds another type', (tester) async {
      await preferences.setInt(key, 42);
      await preferences.reload();
      final failures = <UserIDStoreFailure>[];
      final store = SharedPreferencesUserIDStore(preferences, key: key, onError: failures.add);

      expect(store.load(), isNull);
      expect(failures.single.operation, 'read');
    });
  });
}
