import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:fridgeos/core/error/failure.dart';
import 'package:fridgeos/core/result.dart';

/// KDF identifier stored in backup envelopes (FR-SET-3).
const String kBackupKdfPbkdf2Sha256 = 'pbkdf2-hmac-sha256';

/// Current encrypted backup envelope format version.
const int kBackupEnvelopeVersion = 1;

/// PBKDF2 iteration count (OWASP-aligned for mobile offline backups).
const int kBackupPbkdf2Iterations = 100_000;

/// 128-bit random salt per backup.
const int kBackupSaltLengthBytes = 16;

/// On-disk / wire JSON envelope wrapping AES-256-GCM ciphertext.
final class BackupEnvelope {
  const BackupEnvelope({
    required this.version,
    required this.createdAt,
    required this.kdf,
    required this.kdfIterations,
    required this.salt,
    required this.nonce,
    required this.ciphertext,
    required this.mac,
  });

  final int version;
  final DateTime createdAt;
  final String kdf;
  final int kdfIterations;
  final Uint8List salt;
  final Uint8List nonce;
  final Uint8List ciphertext;
  final Uint8List mac;

  Map<String, dynamic> toJson() => {
    'version': version,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'kdf': kdf,
    'kdfIterations': kdfIterations,
    'salt': base64Encode(salt),
    'nonce': base64Encode(nonce),
    'ciphertext': base64Encode(ciphertext),
    'mac': base64Encode(mac),
  };

  static Result<BackupEnvelope> fromJson(Map<String, dynamic> json) {
    try {
      final version = json['version'];
      if (version is! int) {
        return const Result.failure(CryptoFailure('Invalid backup version'));
      }
      final createdAtRaw = json['createdAt'];
      if (createdAtRaw is! String) {
        return const Result.failure(CryptoFailure('Invalid backup timestamp'));
      }
      final createdAt = DateTime.parse(createdAtRaw).toUtc();
      final kdf = json['kdf'];
      if (kdf is! String || kdf.isEmpty) {
        return const Result.failure(CryptoFailure('Invalid backup KDF'));
      }
      final iterations = json['kdfIterations'];
      if (iterations is! int || iterations <= 0) {
        return const Result.failure(CryptoFailure('Invalid KDF iterations'));
      }

      Uint8List decodeField(String key) {
        final value = json[key];
        if (value is! String) {
          throw const FormatException('missing field');
        }
        return Uint8List.fromList(base64Decode(value));
      }

      return Result.success(
        BackupEnvelope(
          version: version,
          createdAt: createdAt,
          kdf: kdf,
          kdfIterations: iterations,
          salt: decodeField('salt'),
          nonce: decodeField('nonce'),
          ciphertext: decodeField('ciphertext'),
          mac: decodeField('mac'),
        ),
      );
    } on FormatException {
      return const Result.failure(CryptoFailure('Malformed backup envelope'));
    }
  }

  Uint8List toBytes() => Uint8List.fromList(utf8.encode(jsonEncode(toJson())));
}

/// Passphrase-based AES-256-GCM encryption for offline backups.
///
/// Key derivation uses PBKDF2-HMAC-SHA256 (via package:cryptography) with a
/// random 128-bit salt and 100k iterations. Argon2id would be preferable for
/// new greenfield designs but PBKDF2 is widely available, auditable in pure
/// Dart tests, and sufficient for passphrase-protected local exports.
final class BackupCrypto {
  BackupCrypto({Random? random}) : _random = random ?? Random.secure();

  final Random _random;
  final AesGcm _aesGcm = AesGcm.with256bits();
  final Pbkdf2 _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: kBackupPbkdf2Iterations,
    bits: 256,
  );

  Future<Result<BackupEnvelope>> encrypt({
    required Uint8List plaintext,
    required String passphrase,
  }) async {
    if (passphrase.isEmpty) {
      return const Result.failure(
        ValidationFailure('Passphrase must not be empty'),
      );
    }

    final salt = _randomBytes(kBackupSaltLengthBytes);
    final secretKey = await _deriveKey(passphrase: passphrase, salt: salt);
    final secretBox = await _aesGcm.encrypt(plaintext, secretKey: secretKey);

    return Result.success(
      BackupEnvelope(
        version: kBackupEnvelopeVersion,
        createdAt: DateTime.now().toUtc(),
        kdf: kBackupKdfPbkdf2Sha256,
        kdfIterations: kBackupPbkdf2Iterations,
        salt: salt,
        nonce: Uint8List.fromList(secretBox.nonce),
        ciphertext: Uint8List.fromList(secretBox.cipherText),
        mac: Uint8List.fromList(secretBox.mac.bytes),
      ),
    );
  }

  Future<Result<Uint8List>> decrypt({
    required BackupEnvelope envelope,
    required String passphrase,
  }) async {
    if (passphrase.isEmpty) {
      return const Result.failure(
        ValidationFailure('Passphrase must not be empty'),
      );
    }
    if (envelope.kdf != kBackupKdfPbkdf2Sha256) {
      return const Result.failure(CryptoFailure('Unsupported backup KDF'));
    }

    final secretKey = await _deriveKey(
      passphrase: passphrase,
      salt: envelope.salt,
      iterations: envelope.kdfIterations,
    );
    final secretBox = SecretBox(
      envelope.ciphertext,
      nonce: envelope.nonce,
      mac: Mac(envelope.mac),
    );

    try {
      final clearText = await _aesGcm.decrypt(secretBox, secretKey: secretKey);
      return Result.success(Uint8List.fromList(clearText));
    } on SecretBoxAuthenticationError {
      return const Result.failure(CryptoFailure('Incorrect passphrase'));
    } on Exception {
      return const Result.failure(CryptoFailure('Backup decryption failed'));
    }
  }

  Future<SecretKey> _deriveKey({
    required String passphrase,
    required Uint8List salt,
    int? iterations,
  }) {
    final kdf = iterations == null || iterations == kBackupPbkdf2Iterations
        ? _pbkdf2
        : Pbkdf2(
            macAlgorithm: Hmac.sha256(),
            iterations: iterations,
            bits: 256,
          );
    return kdf.deriveKeyFromPassword(password: passphrase, nonce: salt);
  }

  Uint8List _randomBytes(int length) {
    return Uint8List.fromList(
      List<int>.generate(length, (_) => _random.nextInt(256)),
    );
  }
}
