import 'package:flutter/material.dart';
import 'package:zogolive/pages/matches_page.dart';
import 'package:zogolive/pages/community_page.dart';
import 'package:zogolive/pages/news_page.dart';
import 'package:zogolive/pages/profile_page.dart';
import 'package:zogolive/utils/g5_colors.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const MatchesPage(),
    const CommunityPage(),
    const NewsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: G5Colors.pitchBorder,
              width: 1.0,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: G5Colors.pitch,
          selectedItemColor: G5Colors.accentEmerald,
          unselectedItemColor: G5Colors.textSecondary,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_soccer),
              label: '比赛',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: '社区',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.article),
              label: '资讯',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }
}
