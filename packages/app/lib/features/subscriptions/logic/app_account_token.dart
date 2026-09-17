import 'package:uuid/uuid.dart';

/// RFC 4122 DNS namespace. The token is derived rather than random so it can be
/// re-derived on every launch and stays stable for a given account.
const String _kAppAccountTokenNamespace =
    '6ba7b810-9dad-11d1-80b4-00c04fd430c8';

/// Derives the deterministic store account token (a UUIDv5) sent for [ownerId].
///
/// StoreKit2 only forwards the purchase's `applicationUserName` as
/// `appAccountToken` when it parses as a UUID — the plugin drops anything else
/// silently. Sending the raw account id therefore made every App Store
/// notification arrive with no account token at all, so the backend could not
/// attach the purchase to an account until the client verified it (and never
/// could when the client never came back).
///
/// A UUID cannot be reversed, so the backend records this token → owner mapping
/// when the client calls `/billing/verify`, and resolves store notifications
/// against it. Google Play receives the same value as its obfuscated account id:
/// it must not be the raw account id, and the backend resolves Play purchases
/// through the purchase token anyway.
///
/// Returns null when [ownerId] is missing, so callers can omit the field.
String? appAccountTokenForOwner(String? ownerId) {
  final normalized = ownerId?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return const Uuid().v5(
    _kAppAccountTokenNamespace,
    'bot-creator:owner:$normalized',
  );
}
