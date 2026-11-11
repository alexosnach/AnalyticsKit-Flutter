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
abstract interface class IdentifierHasher {
  HashedUserID hash(String identifier);
}

/// SHA-256 as a lowercase hex string of 64 characters.
class SHA256IdentifierHasher implements IdentifierHasher {
  const SHA256IdentifierHasher();

  @override
  HashedUserID hash(String identifier) {
    final digest = sha256.convert(utf8.encode(identifier));
    return HashedUserID._(digest.toString());
  }
}
