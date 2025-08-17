// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('App loads and shows login or wish list screen', (WidgetTester tester) async {
    await tester.pumpWidget(const WishfulApp());

    // Should find either the login or wish list screen widgets
    expect(find.text('Login'), findsOneWidget);
    // If you want to test for wish list screen, mock FirebaseAuth accordingly.
  });
}
