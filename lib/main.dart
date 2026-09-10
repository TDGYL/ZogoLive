import 'package:flutter/material.dart';
import 'package:zogolive/pages/main_page.dart';
import 'package:zogolive/utils/g5_colors.dart';
import 'package:zogolive/utils/g5_auth_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await G5AuthManager().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TactiGoal',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: G5Colors.pitch,
        primaryColor: G5Colors.accentEmerald,
        appBarTheme: const AppBarTheme(
          backgroundColor: G5Colors.pitch,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: G5Colors.pitch,
          selectedItemColor: G5Colors.accentEmerald,
          unselectedItemColor: G5Colors.textSecondary,
        ),
      ),
      home: const MainPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
