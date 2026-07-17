import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fridgeos/core/error/failure.dart';
import 'package:fridgeos/infrastructure/backup/backup_crypto.dart';

void main() {
  group('BackupCrypto', () {
    test('round-trip encrypts and decrypts plaintext', () async {
      final crypto = BackupCrypto(random: Random(42));
      const passphrase = 'kitchen-secret';
      final plaintext = Uint8List.fromList(utf8.encode('{"hello":"world"}'));

      final encrypted = await crypto.encrypt(
        plaintext: plaintext,
        passphrase: passphrase,
      );
      expect(encrypted.isSuccess, isTrue);

      final envelope = encrypted.valueOrNull!;
      expect(envelope.kdf, kBackupKdfPbkdf2Sha256);
      expect(envelope.kdfIterations, kBackupPbkdf2Iterations);

      final decrypted = await crypto.decrypt(
        envelope: envelope,
        passphrase: passphrase,
      );
      expect(decrypted.isSuccess, isTrue);
      expect(decrypted.valueOrNull, plaintext);
    });

    test('wrong passphrase fails authentication', () async {
      final crypto = BackupCrypto(random: Random(7));
      final plaintext = Uint8List.fromList(utf8.encode('payload'));

      final encrypted = await crypto.encrypt(
        plaintext: plaintext,
        passphrase: 'correct',
      );
      final envelope = encrypted.valueOrNull!;

      final decrypted = await crypto.decrypt(
        envelope: envelope,
        passphrase: 'wrong',
      );
      expect(decrypted.isFailure, isTrue);
      expect(decrypted.failureOrNull, isA<CryptoFailure>());
    });

    test('rejects empty passphrase', () async {
      final crypto = BackupCrypto();
      final result = await crypto.encrypt(
        plaintext: Uint8List.fromList([1]),
        passphrase: '',
      );
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });
  });
}
