/// Keeps the app's raw user ID between launches.
///
/// Used by `AnonymousUserIDProvider`. `SharedPreferencesUserIDStore` is the
/// production choice; implement this interface for another storage or for tests.
abstract interface class UserIDStore {
  /// The saved ID, or `null` when none was saved yet.
  String? load();

  /// Saves the ID, replacing any earlier one. Must not throw: a failed save
  /// only means the next launch makes a new ID.
  void save(String id);
}
