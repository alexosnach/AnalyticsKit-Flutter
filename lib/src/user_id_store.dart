/// Keeps the app's raw user ID between launches.
abstract interface class UserIDStore {
  /// The saved ID, or `null` when none was saved yet.
  String? load();

  void save(String id);
}
