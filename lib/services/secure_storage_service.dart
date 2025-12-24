import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// 🔒 SECURE STORAGE SERVICE
/// Provides encrypted local storage for sensitive data
/// Uses AES-256 encryption with unique device keys
class SecureStorageService {
  static final SecureStorageService _instance =
      SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  // Flutter Secure Storage - Encrypted keychain/keystore
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Encryption key (generated once per device)
  encrypt.Key? _encryptionKey;
  encrypt.IV? _iv;

  /// Initialize encryption keys (call this on app startup)
  Future<void> initialize() async {
    try {
      // Try to get existing key
      String? keyString = await _secureStorage.read(key: '_encryption_key');
      String? ivString = await _secureStorage.read(key: '_encryption_iv');

      if (keyString == null || ivString == null) {
        // Generate new key and IV
        _encryptionKey = encrypt.Key.fromSecureRandom(32); // AES-256
        _iv = encrypt.IV.fromSecureRandom(16);

        // Save to secure storage
        await _secureStorage.write(
          key: '_encryption_key',
          value: base64.encode(_encryptionKey!.bytes),
        );
        await _secureStorage.write(
          key: '_encryption_iv',
          value: base64.encode(_iv!.bytes),
        );

        debugPrint('🔐 New encryption keys generated');
      } else {
        // Load existing key and IV
        _encryptionKey = encrypt.Key(base64.decode(keyString));
        _iv = encrypt.IV(base64.decode(ivString));
        debugPrint('🔐 Encryption keys loaded');
      }
    } catch (e) {
      debugPrint('❌ Error initializing encryption: $e');
      rethrow;
    }
  }

  /// Encrypt and store data
  Future<void> write({required String key, required String value}) async {
    try {
      if (_encryptionKey == null || _iv == null) {
        await initialize();
      }

      // Encrypt the value
      final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey!));
      final encrypted = encrypter.encrypt(value, iv: _iv!);

      // Store encrypted value
      await _secureStorage.write(
        key: key,
        value: encrypted.base64,
      );

      debugPrint('✅ Encrypted data stored: $key');
    } catch (e) {
      debugPrint('❌ Error writing encrypted data: $e');
      rethrow;
    }
  }

  /// Read and decrypt data
  Future<String?> read({required String key}) async {
    try {
      if (_encryptionKey == null || _iv == null) {
        await initialize();
      }

      // Read encrypted value
      final encryptedValue = await _secureStorage.read(key: key);
      if (encryptedValue == null) return null;

      // Decrypt the value
      final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey!));
      final decrypted = encrypter.decrypt64(encryptedValue, iv: _iv!);

      debugPrint('✅ Data decrypted: $key');
      return decrypted;
    } catch (e) {
      debugPrint('❌ Error reading encrypted data: $e');
      return null;
    }
  }

  /// Delete encrypted data
  Future<void> delete({required String key}) async {
    try {
      await _secureStorage.delete(key: key);
      debugPrint('✅ Encrypted data deleted: $key');
    } catch (e) {
      debugPrint('❌ Error deleting encrypted data: $e');
      rethrow;
    }
  }

  /// Delete all encrypted data
  Future<void> deleteAll() async {
    try {
      await _secureStorage.deleteAll();
      _encryptionKey = null;
      _iv = null;
      debugPrint('✅ All encrypted data deleted');
    } catch (e) {
      debugPrint('❌ Error deleting all encrypted data: $e');
      rethrow;
    }
  }

  /// Check if key exists
  Future<bool> containsKey({required String key}) async {
    try {
      final value = await _secureStorage.read(key: key);
      return value != null;
    } catch (e) {
      debugPrint('❌ Error checking key existence: $e');
      return false;
    }
  }

  /// Hash sensitive data (one-way - cannot be decrypted)
  String hashData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ============================================
  // CONVENIENCE METHODS FOR COMMON DATA TYPES
  // ============================================

  /// Store JSON object (encrypted)
  Future<void> writeJson(
      {required String key, required Map<String, dynamic> json}) async {
    final jsonString = jsonEncode(json);
    await write(key: key, value: jsonString);
  }

  /// Read JSON object (decrypted)
  Future<Map<String, dynamic>?> readJson({required String key}) async {
    final jsonString = await read(key: key);
    if (jsonString == null) return null;
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Store boolean (encrypted)
  Future<void> writeBool({required String key, required bool value}) async {
    await write(key: key, value: value.toString());
  }

  /// Read boolean (decrypted)
  Future<bool?> readBool({required String key}) async {
    final value = await read(key: key);
    if (value == null) return null;
    return value.toLowerCase() == 'true';
  }

  /// Store integer (encrypted)
  Future<void> writeInt({required String key, required int value}) async {
    await write(key: key, value: value.toString());
  }

  /// Read integer (decrypted)
  Future<int?> readInt({required String key}) async {
    final value = await read(key: key);
    if (value == null) return null;
    return int.tryParse(value);
  }
}

// ============================================
// STORAGE KEYS (Centralized)
// ============================================
class StorageKeys {
  // User preferences
  static const String theme = 'user_theme';
  static const String currency = 'user_currency';
  static const String language = 'user_language';

  // Security
  static const String biometricEnabled = 'biometric_enabled';
  static const String lastLoginTime = 'last_login_time';

  // Cache
  static const String cachedUserData = 'cached_user_data';
  static const String cachedTransactions = 'cached_transactions';

  // Session
  static const String sessionToken = 'session_token';
  static const String refreshToken = 'refresh_token';
}
