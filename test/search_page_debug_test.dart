import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livespeed/pages/search_page.dart';

void main() {
  testWidgets('SearchPage renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SearchPage()));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byType(SearchPage), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Trending Searches'), findsOneWidget);
  });
}
