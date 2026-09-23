import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt_lib;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// A service for securely storing sensitive values (tokens, API keys, etc.).
///
/// On Android/iOS/macOS/Windows, delegates to [FlutterSecureStorage] via the
/// `flutter_secure_storage` package (which uses OS-native keychains).
///
/// On Linux/headless environments where `libsecret` / D-Bus may not be
/// available, falls back to AES-256-GCM file-based encryption using the
/// `encrypt` package. The encryption key is derived from a device-specific
/// secret stored in a file with restricted permissions (0600).
class SecureStorageService {
  SecureStorageService._({
    required this.storageDir,
    required this.encryptionKey,
    required this.flutterSecureStorage,
    this.inMemoryStore,
  });

  final String storageDir;
  final encrypt_lib.Key encryptionKey;
  final FlutterSecureStorage? flutterSecureStorage;
  final Map<String, String>? inMemoryStore;

  static SecureStorageService? _instance;

  @visibleForTesting
  static void setMockInstance(SecureStorageService? mock) {
    _instance = mock;
  }

  @visibleForTesting
  static SecureStorageService createInMemory({String storageDir = '/tmp'}) {
    return SecureStorageService._(
      storageDir: storageDir,
      encryptionKey: encrypt_lib.Key.fromLength(32),
      flutterSecureStorage: null,
      inMemoryStore: <String, String>{},
    );
  }

  /// Returns the singleton [SecureStorageService], initializing it on first
  /// call. Initialization is async because we need to resolve storage paths
  /// and derive keys from the filesystem.
  static Future<SecureStorageService> get instance async {
    if (_instance != null) return _instance!;
    _instance = await _create();
    return _instance!;
  }

  static Future<SecureStorageService> _create() async {
    final supportDir = await _getSupportDir();
    final storageDir = p.join(supportDir, '.secure_vault');

    // Ensure storage directory exists
    final storageDirObj = Directory(storageDir);
    if (!await storageDirObj.exists()) {
      await storageDirObj.create(recursive: true);
    }

    // Derive encryption key (AES-256 requires 32 bytes)
    final encryptionKey = await _deriveKey(supportDir);

    const fss = FlutterSecureStorage();

    return SecureStorageService._(
      storageDir: storageDir,
      encryptionKey: encryptionKey,
      flutterSecureStorage: fss,
    );
  }

  /// Resolves the application support directory.
  static Future<String> _getSupportDir() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return Directory.systemTemp.path;
    }
    try {
      final dir = await getApplicationSupportDirectory();
      return dir.path;
    } catch (_) {
      // Fallback for environments where path_provider isn't available
      final home =
          Platform.environment['HOME'] ??
          Platform.environment['USERPROFILE'] ??
          '/tmp';
      return p.join(home, '.local', 'share', 'bot_creator');
    }
  }

  /// Derives a 32-byte AES-256 key from a device-specific secret.
  ///
  /// The secret is stored in a file at [keysDir]/device_secret with 0600
  /// permissions. If the file doesn't exist yet, a new random secret is
  /// generated. The final key is SHA-256(device_secret + "bot_creator_secure_v1").
  static Future<encrypt_lib.Key> _deriveKey(String supportDir) async {
    final keysDir = p.join(supportDir, '.keys');
    final keysDirObj = Directory(keysDir);
    if (!await keysDirObj.exists()) {
      await keysDirObj.create(recursive: true);
    }

    final secretFile = File(p.join(keysDir, 'device_secret'));
    String secret;

    if (await secretFile.exists()) {
      secret = (await secretFile.readAsString()).trim();
    } else {
      // Generate a new 128-character random hex secret
      final bytes = List<int>.generate(64, (_) => Random.secure().nextInt(256));
      secret = base64Url.encode(bytes);
      await secretFile.writeAsString(secret);
      // Restrict permissions to owner-only (Unix)
      _restrictFilePermissions(secretFile);
    }
    _restrictFilePermissions(secretFile);

    // Derive key: SHA-256(secret + domain separator)
    final hash = sha256.convert(utf8.encode('$secret:bot_creator_secure_v1'));
    return encrypt_lib.Key.fromUtf8(hash.toString().substring(0, 32));
  }

  /// Attempts to set file permissions to 0600 (owner read/write only) on Unix.
  static void _restrictFilePermissions(File file) {
    try {
      if (!Platform.isWindows &&
          !Platform.environment.containsKey('FLUTTER_TEST')) {
        // Use chmod via Process to set 0600 permissions
        Process.run('chmod', ['600', file.path]);
      }
    } catch (_) {
      // Platform may not support this
    }
  }

  /// Returns the file path for a given key. Uses the SHA-256 hash of the
  /// key as the filename to prevent path traversal and special character
  /// issues.
  String _filePath(String key) {
    final safeName = sha256.convert(utf8.encode(key)).toString();
    return p.join(storageDir, safeName);
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Writes a value to secure storage.
  ///
  /// Writes to both flutter_secure_storage (if available) and the encrypted
  /// file fallback, ensuring dual-write coverage.
  Future<void> write(String key, String value) async {
    if (inMemoryStore != null) {
      inMemoryStore![key] = value;
      return;
    }
    if (flutterSecureStorage != null) {
      try {
        await flutterSecureStorage!.write(key: key, value: value);
      } catch (_) {
        // fallback below handles it
      }
    }
    await _writeEncrypted(key, value);
  }

  /// Reads a value from secure storage.
  ///
  /// Tries flutter_secure_storage first (on supported platforms), then
  /// falls back to reading the encrypted file.
  Future<String?> read(String key) async {
    if (inMemoryStore != null) {
      return inMemoryStore![key];
    }
    // Try flutter_secure_storage first
    if (flutterSecureStorage != null) {
      try {
        final result = await flutterSecureStorage!
            .read(key: key)
            .timeout(const Duration(milliseconds: 200));
        if (result != null && result.isNotEmpty) {
          return result;
        }
      } catch (_) {
        // flutter_secure_storage failed; fall through
      }
    }

    // Fall back to encrypted file
    return _readEncrypted(key);
  }

  /// Deletes a value from secure storage.
  Future<void> delete(String key) async {
    if (inMemoryStore != null) {
      inMemoryStore!.remove(key);
      return;
    }
    if (flutterSecureStorage != null) {
      try {
        await flutterSecureStorage!.delete(key: key);
      } catch (_) {}
    }

    final file = File(_filePath(key));
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Clears all values from secure storage.
  Future<void> clear() async {
    if (inMemoryStore != null) {
      inMemoryStore!.clear();
      return;
    }
    if (flutterSecureStorage != null) {
      try {
        await flutterSecureStorage!.deleteAll();
      } catch (_) {}
    }

    final dir = Directory(storageDir);
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        if (entity is File) {
          try {
            await entity.delete();
          } catch (_) {}
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // AES-256-GCM file-backed storage
  // ---------------------------------------------------------------------------

  /// Writes an encrypted value to a file on disk.
  Future<void> _writeEncrypted(String key, String value) async {
    final iv = encrypt_lib.IV.fromSecureRandom(12); // 96-bit IV for GCM
    final encrypter = encrypt_lib.Encrypter(
      encrypt_lib.AES(encryptionKey, mode: encrypt_lib.AESMode.gcm),
    );
    final encrypted = encrypter.encrypt(value, iv: iv);

    // Format: base64(iv):base64(ciphertext+tag)
    // The encrypt package appends the GCM tag to the ciphertext
    final payload = '${iv.base64}:${encrypted.base64}';
    final file = File(_filePath(key));
    await file.create(recursive: true);
    await file.writeAsString(payload);
    _restrictFilePermissions(file);
  }

  /// Reads and decrypts a value from a file on disk.
  Future<String?> _readEncrypted(String key) async {
    final file = File(_filePath(key));
    if (!await file.exists()) return null;

    try {
      final payload = (await file.readAsString()).trim();
      final parts = payload.split(':');
      if (parts.length != 2) return null;

      final iv = encrypt_lib.IV.fromBase64(parts[0]);
      final encrypted = encrypt_lib.Encrypted.fromBase64(parts[1]);
      final encrypter = encrypt_lib.Encrypter(
        encrypt_lib.AES(encryptionKey, mode: encrypt_lib.AESMode.gcm),
      );
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      debugPrint('[SecureStorageService] Decryption failed for key "$key": $e');
      return null;
    }
  }
}
