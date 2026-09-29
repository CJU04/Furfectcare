// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vetcare_connect/providers/app_init_provider.dart';
import 'package:vetcare_connect/providers/auth_provider.dart';
import 'package:vetcare_connect/providers/theme_provider.dart';

import 'package:vetcare_connect/main.dart';

void main() {
  testWidgets('App renders with providers', (WidgetTester tester) async {
    // ThemeProvider reads SharedPreferences on construction, so the platform
    // channel has to be backed by an in-memory mock inside the test harness.
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppInitProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const VetCareConnectApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);

    // The splash screen schedules a delayed navigation via Future.delayed, so
    // pump past that timer. Otherwise the test framework fails the case with
    // "A Timer is still pending even after the widget tree was disposed".
    await tester.pump(const Duration(milliseconds: 200));
  });
}
