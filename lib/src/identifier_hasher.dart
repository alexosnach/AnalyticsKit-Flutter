import 'dart:convert';

import 'package:crypto/crypto.dart';

/// A user ID that has been hashed and is safe to send to analytics.
///
/// Only a hasher in this file can create it: its constructor is private,
/// so a raw ID can never be passed where a `HashedUserID` is expected.
class HashedUserID {
  const HashedUserID._(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      other is HashedUserID && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'HashedUserID($value)';
}

/// Turns a raw identifier into the one analytics receives.
///
/// Use it directly when the app already has a user ID, e.g. from its backend
/// after sign-in: `analytics.setUserID(hasher.hash(user.id))`.
abstract interface class IdentifierHasher {
  /// The hashed form of [identifier]; the same input always gives the same result.
  HashedUserID hash(String identifier);
}

/// SHA-256 as a lowercase hex string of 64 characters.
///
/// The same algorithm and format as the Swift and Android libraries, so one
/// user gets the same ID on every platform.
class SHA256IdentifierHasher implements IdentifierHasher {
  const SHA256IdentifierHasher();

  /// SHA-256 of the identifier's UTF-8 bytes, as lowercase hex.
  @override
  HashedUserID hash(String identifier) {
    final digest = sha256.convert(utf8.encode(identifier));
    return HashedUserID._(digest.toString());
  }
}
