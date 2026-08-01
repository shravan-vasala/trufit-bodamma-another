import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class BackupEncryptionService {
  /// Encrypts data using AES-256-CBC.
  /// The key is derived by hashing the [password] with SHA-256.
  /// The output format is [16-byte IV] followed by the [Encrypted Data].
  static Uint8List encryptBytes(Uint8List data, String password) {
    final keyBytes = sha256.convert(utf8.encode(password)).bytes;
    final key = enc.Key(Uint8List.fromList(keyBytes));
    final iv = enc.IV.fromSecureRandom(16);
    
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    
    final encrypted = encrypter.encryptBytes(data, iv: iv);
    
    final out = BytesBuilder();
    out.add(iv.bytes);
    out.add(encrypted.bytes);
    return out.toBytes();
  }

  /// Decrypts data using AES-256-CBC.
  /// Assumes the [data] starts with a 16-byte IV.
  static Uint8List decryptBytes(Uint8List data, String password) {
    if (data.length < 16) throw Exception('Invalid encrypted data: too short');
    
    final keyBytes = sha256.convert(utf8.encode(password)).bytes;
    final key = enc.Key(Uint8List.fromList(keyBytes));
    
    final ivBytes = data.sublist(0, 16);
    final encryptedBytes = data.sublist(16);
    
    final iv = enc.IV(ivBytes);
    final encrypted = enc.Encrypted(encryptedBytes);
    
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final decryptedList = encrypter.decryptBytes(encrypted, iv: iv);
    return Uint8List.fromList(decryptedList);
  }
}
