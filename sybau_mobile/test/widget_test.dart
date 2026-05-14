// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sybau_mobile/main.dart';
import 'package:sybau_mobile/services/api_service.dart';

void main() {
  test('mediaUrl leaves inline profile image URLs untouched', () {
    const imageUrl = 'data:image/png;base64,abc123';

    expect(ApiService.mediaUrl(imageUrl), imageUrl);
  });

  test('mediaUrl leaves absolute remote URLs untouched', () {
    const imageUrl = 'https://example.test/avatar.png';

    expect(ApiService.mediaUrl(imageUrl), imageUrl);
  });

  test('mediaUrl resolves backend-relative upload paths', () {
    expect(
      ApiService.mediaUrl('/uploads/profile-images/avatar.png'),
      'https://sybau-xll5.onrender.com/uploads/profile-images/avatar.png',
    );
  });

  testWidgets('App starts and builds', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});

    await tester.pumpWidget(const SybauApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('SYBAU'), findsOneWidget);
  });
}
