import 'package:analytics_kit/analytics_kit.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers.dart';

/// The Composition Root: the one place that knows which providers the app has.
class AppDependencies {
  AppDependencies._(this.analytics, this.recorder, this.userID);

  final AnalyticsService analytics;
  final RecordingAnalyticsProvider recorder;
  final HashedUserID userID;

  static Future<AppDependencies> create() async {
    final recorder = RecordingAnalyticsProvider();
    final AnalyticsService analytics = CompositeAnalytics(providers: [
      ConsoleAnalyticsProvider(),
      recorder,
    ]);

    final preferences = await SharedPreferences.getInstance();
    final userIDProvider = AnonymousUserIDProvider(
      store: SharedPreferencesUserIDStore(
        preferences,
        onError: (failure) => debugPrint('Analytics: $failure'),
      ),
      hasher: const SHA256IdentifierHasher(),
    );
    final userID = userIDProvider.currentUserID();

    analytics.setUserID(userID);
    analytics.track(const AnalyticsEvent(name: 'app_opened'));

    return AppDependencies._(analytics, recorder, userID);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ExampleApp(dependencies: await AppDependencies.create()));
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return AnalyticsScope(
      analytics: dependencies.analytics,
      child: MaterialApp(
        title: 'AnalyticsKit Example',
        home: ExampleScreen(
          userID: dependencies.userID.value,
          recorder: dependencies.recorder,
        ),
      ),
    );
  }
}

class ExampleScreen extends StatelessWidget {
  const ExampleScreen({super.key, required this.userID, required this.recorder});

  final String userID;
  final RecordingAnalyticsProvider recorder;

  @override
  Widget build(BuildContext context) {
    // The screen gets only `EventTracking`: it can send events and nothing else.
    final analytics = AnalyticsScope.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              Text('User ID', style: Theme.of(context).textTheme.labelLarge),
              Text(userID, key: const Key('user_id')),
              FilledButton(
                onPressed: () => analytics.track(const AnalyticsEvent(
                  name: 'button_tapped',
                  parameters: {'screen': 'example'},
                )),
                child: const Text('Track event'),
              ),
              ListenableBuilder(
                listenable: recorder,
                builder: (context, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 16,
                  children: [
                    Text(
                      'Events sent: ${recorder.events.length}',
                      key: const Key('events_count'),
                    ),
                    Text(
                      'Last event: ${recorder.events.lastOrNull?.name ?? '—'}',
                      key: const Key('last_event'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
