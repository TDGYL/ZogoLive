// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures with WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:livespeed/pages/login_page.dart';

void main() {
  testWidgets('LoginPage renders smoke test', (WidgetTester tester) async {
    // Build the login page and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    // Verify that the login page renders without throwing.
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Log In'), findsWidgets);
  });
}
