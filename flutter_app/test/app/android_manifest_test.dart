import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Security fitness function (docs/03-non-functional-requirements.md NFR-SEC-6,
/// docs/08-threat-model.md SR-6): the release manifest must declare only the
/// minimal permission set and must disable cleartext traffic and OS auto-backup.
void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml');

  group('AndroidManifest', () {
    late String contents;

    setUpAll(() {
      expect(manifest.existsSync(), isTrue, reason: 'manifest must exist');
      contents = manifest.readAsStringSync();
    });

    test('declares only the allowed permissions', () {
      const allowed = <String>{
        'android.permission.INTERNET',
        'android.permission.CAMERA',
        'android.permission.POST_NOTIFICATIONS',
      };

      final declared = RegExp(
        r'uses-permission android:name="([^"]+)"',
      ).allMatches(contents).map((m) => m.group(1)!).toSet();

      expect(
        declared.difference(allowed),
        isEmpty,
        reason: 'unexpected permission(s) declared',
      );
    });

    test('disables cleartext traffic', () {
      expect(contents, contains('android:usesCleartextTraffic="false"'));
      expect(contents, contains('android:networkSecurityConfig'));
    });

    test('disables OS auto-backup', () {
      expect(contents, contains('android:allowBackup="false"'));
    });
  });

  test('network security config forbids cleartext', () {
    final config = File(
      'android/app/src/main/res/xml/network_security_config.xml',
    );
    expect(config.existsSync(), isTrue);
    final text = config.readAsStringSync();
    expect(text, contains('cleartextTrafficPermitted="false"'));
    expect(text.contains('cleartextTrafficPermitted="true"'), isFalse);
  });
}
