import 'package:flutter/material.dart';
import 'package:livespeed/pages/matches_page.dart';
import 'package:livespeed/pages/community_page.dart';
import 'package:livespeed/pages/news_page.dart';
import 'package:livespeed/pages/profile_page.dart';
import 'package:livespeed/utils/g5_colors.dart';
import 'package:livespeed/utils/g5_event_bus.dart';

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
  void initState() {
    super.initState();
    // 监听切TabEvents，通知对应页面刷新
    G5EventBus().on<MainTabSwitchEvent>().listen((event) {
      if (event.index == _currentIndex && mounted) {
        setState(() {});
      }
    });
  }

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
            // 通知切到"Me"Tab，触发个人信息刷新
            if (index == 3) {
              G5EventBus().fire(MainTabSwitchEvent(index));
            }
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
              label: 'Matches',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Community',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.article),
              label: 'News',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Me',
            ),
          ],
        ),
      ),
    );
  }
}
