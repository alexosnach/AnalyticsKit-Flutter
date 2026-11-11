import 'dart:math';

import 'identifier_hasher.dart';
import 'user_id_store.dart';

/// Gives the user ID analytics sends, already hashed.
///
/// Today the ID is anonymous, made on the device. When the app gets accounts,
/// a provider that hashes the backend's ID replaces this one in the
/// Composition Root; the code that sends the ID does not change.
abstract interface class UserIDProvider {
  HashedUserID currentUserID();
}

/// A random ID made on first launch and kept in the store from then on.
///
/// It identifies this app on this device: another device of the same person
/// gets its own.
class AnonymousUserIDProvider implements UserIDProvider {
  const AnonymousUserIDProvider({
    required UserIDStore store,
    required IdentifierHasher hasher,
  })  : _store = store,
        _hasher = hasher;

  final UserIDStore _store;
  final IdentifierHasher _hasher;

  @override
  HashedUserID currentUserID() => _hasher.hash(_rawID());

  /// The saved ID, or a new one saved now. If saving fails, the new ID still
  /// serves this call and the next one makes another.
  String _rawID() {
    final saved = _store.load();
    if (saved != null) {
      return saved;
    }
    final id = _randomUUID();
    _store.save(id);
    return id;
  }

  /// A random (version 4) UUID, always lowercase: the same form on every
  /// platform, for example `8fc10609-b5a6-4c45-a2a0-8b340468e611`.
  static String _randomUUID() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC 4122 variant

    final hex =
        bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    return [
      hex.substring(0, 8),
      hex.substring(8, 12),
      hex.substring(12, 16),
      hex.substring(16, 20),
      hex.substring(20),
    ].join('-').toLowerCase();
  }
}
