import 'package:shared_preferences/shared_preferences.dart';

import 'user_id_store.dart';

/// Stores the user ID with the `shared_preferences` plugin: `UserDefaults`
/// on iOS, `SharedPreferences` on Android.
///
/// The ID lives as long as the app's data: removing the app removes it.
/// It comes back after a reinstall only through the system backup.
///
/// The app loads the preferences once, before it builds its analytics:
///
/// ```dart
/// final preferences = await SharedPreferences.getInstance();
/// final store = SharedPreferencesUserIDStore(
///   preferences,
///   onError: (failure) => debugPrint('$failure'),
/// );
/// ```
///
/// After that `load` and `save` do not wait: `save` keeps the ID in memory
/// at once and writes it to disk in the background.
///
/// A storage failure does not stop the app: the ID still serves this launch.
/// The store reports it to `onError`, so the app can log it with its own
/// logger or send it to crash reporting.
class SharedPreferencesUserIDStore implements UserIDStore {
  SharedPreferencesUserIDStore(
    SharedPreferences preferences, {
    String key = 'analytics.user_id',
    void Function(UserIDStoreFailure failure)? onError,
  })  : _preferences = preferences,
        _key = key,
        _onError = onError ?? _ignore;

  final SharedPreferences _preferences;
  final String _key;
  final void Function(UserIDStoreFailure failure) _onError;

  static void _ignore(UserIDStoreFailure failure) {}

  @override
  String? load() {
    final Object? value;
    try {
      value = _preferences.get(_key);
    } catch (error) {
      _onError(UserIDStoreFailure.read(error));
      return null;
    }
    if (value == null || value is String) {
      return value as String?;
    }
    // The key holds a value of another type.
    _onError(UserIDStoreFailure.read(
      'expected a String, found ${value.runtimeType}',
    ));
    return null;
  }

  @override
  void save(String id) {
    _preferences.setString(_key, id).then(
      (saved) {
        if (!saved) {
          _onError(const UserIDStoreFailure.write());
        }
      },
      onError: (Object error) => _onError(UserIDStoreFailure.write(error)),
    );
  }
}

/// A storage call that failed.
/// The store keeps working after it: the ID serves this launch.
class UserIDStoreFailure {
  /// Reading the saved ID failed (a missing ID is not a failure).
  const UserIDStoreFailure.read(Object this.cause) : operation = 'read';

  /// Writing the ID to disk failed.
  const UserIDStoreFailure.write([this.cause]) : operation = 'write';

  /// `read` or `write`.
  final String operation;

  /// What the storage reported, when it reported anything.
  final Object? cause;

  /// For example: `SharedPreferences write failed`.
  @override
  String toString() => cause == null
      ? 'SharedPreferences $operation failed'
      : 'SharedPreferences $operation failed: $cause';
}
