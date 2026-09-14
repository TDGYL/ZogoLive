import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zogolive/base/g5_base_view_controller.dart';
import 'package:zogolive/models/g5_user_model.dart';
import 'package:zogolive/utils/g5_colors.dart';
import 'package:zogolive/pages/login_page.dart';
import 'package:zogolive/pages/my_matches_page.dart';
import 'package:zogolive/pages/edit_profile_page.dart';
import 'package:zogolive/pages/customer_service_page.dart';
import 'package:zogolive/pages/about_us_page.dart';
import 'package:zogolive/pages/settings_page.dart';
import 'package:zogolive/utils/g5_auth_manager.dart';
import 'package:zogolive/utils/g5_event_bus.dart';
import 'package:zogolive/utils/g5_network_manager.dart';

class ProfilePage extends G5BaseViewController {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends G5BaseViewState<ProfilePage> {
  StreamSubscription? _authSubscription;

  /// 用户信息刷新事件订阅 - StreamSubscription?类型，监听关注/粉丝数变化通知
  StreamSubscription? _userInfoSubscription;

  /// 主页Tab切换事件订阅 - StreamSubscription?类型，监听切到"我的"Tab
  StreamSubscription? _tabSwitchSubscription;

  @override
  bool get showBackButton => false;

  @override
  void initData() {
    super.initData();
    _authSubscription = G5EventBus().on<LoginStatusChangeEvent>().listen((event) {
      if (mounted) {
        setState(() {}); // 收到通知后刷新界面
        // 登录状态下重新拉取个人信息
        _fetchUserInfo();
      }
    });
    // 监听用户信息刷新事件（关注/粉丝数变化）
    _userInfoSubscription =
        G5EventBus().on<UserInfoRefreshEvent>().listen((event) {
      if (mounted) {
        setState(() {}); // 收到通知后刷新界面
      }
    });
    // 监听主页Tab切换事件：切到"我的"Tab时拉取个人信息刷新关注数和粉丝数
    _tabSwitchSubscription =
        G5EventBus().on<MainTabSwitchEvent>().listen((event) {
      if (mounted && event.index == 3) {
        _fetchUserInfo();
      }
    });
    // 登录状态下进入页面时拉取个人信息
    _fetchUserInfo();
  }

  /// 请求个人信息接口
  /// 接口：GET /api/livespeed/member
  /// 成功后更新我关注的和粉丝数
  Future<void> _fetchUserInfo() async {
    if (!G5AuthManager().isLoggedIn) return;

    try {
      final response =
          await G5NetworkManager().get('/api/livespeed/member');

      if (response.isSuccess &&
          response.data != null &&
          mounted) {
        final user =
            G5UserModel.fromJson(response.data as Map<String, dynamic>);
        // 更新全局用户信息并通知刷新
        await G5AuthManager().saveUserInfo(user);
        G5EventBus().fire(UserInfoRefreshEvent());
      }
    } catch (e) {
      // 静默失败，不影响页面展示
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userInfoSubscription?.cancel();
    _tabSwitchSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 每次页面重新可见时（比如从登录页返回）拉取个人信息刷新界面
    _fetchUserInfo();
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return null; // 使用自定义的头部
  }

  @override
  Widget buildBody(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildMenuSection(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final isLoggedIn = G5AuthManager().isLoggedIn;
    final user = G5AuthManager().currentUser;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [G5Colors.pitchElevated, G5Colors.pitch],
        ),
        border: Border(bottom: BorderSide(color: G5Colors.pitchBorder)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              // 未登录时点击头像跳转登录页
              GestureDetector(
                onTap: () {
                  if (!isLoggedIn) {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const LoginPage()));
                  }
                },
                child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLoggedIn ? Colors.transparent : G5Colors.pitchElevated,
                  border: Border.all(color: G5Colors.pitchBorder, width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: (isLoggedIn && user?.avatar != null && user!.avatar!.isNotEmpty)
                    ? Image.network(
                        user.avatar!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.person, color: G5Colors.textSecondary, size: 30),
                      )
                    : const Icon(Icons.person, color: G5Colors.textSecondary, size: 30),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (isLoggedIn && user?.nickname != null) ? user!.nickname! : '未登录用户',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    (isLoggedIn && user?.id != null) ? 'ID: ${user!.id}' : 'ID: --',
                    style: const TextStyle(
                      color: G5Colors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: G5Colors.pitchCard.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: G5Colors.pitchBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        isLoggedIn ? '${user?.fansCount ?? 0}' : '0',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '粉丝',
                        style: TextStyle(
                            color: G5Colors.textSecondary, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Container(
                    width: 1,
                    height: 30,
                    color: G5Colors.pitchBorder.withOpacity(0.6)),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        isLoggedIn ? '${user?.followers ?? 0}' : '0',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '我关注的',
                        style: TextStyle(
                            color: G5Colors.textSecondary, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    final isLoggedIn = G5AuthManager().isLoggedIn;
    
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: G5Colors.pitchCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: G5Colors.pitchBorder),
          ),
          child: Column(
            children: [
              _buildMenuItem(
                Icons.edit,
                G5Colors.accentEmerald,
                '编辑资料',
                trailing: const Icon(Icons.chevron_right, size: 14, color: G5Colors.textSecondary),
                onTap: () {
                  // 未登录跳转登录页，已登录跳转编辑资料
                  if (!G5AuthManager().isLoggedIn) {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const LoginPage()));
                  } else {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const EditProfilePage()));
                  }
                },
              ),
              const Divider(height: 1, color: G5Colors.pitchBorder),
              _buildMenuItem(
                Icons.sports_soccer,
                G5Colors.accentEmerald,
                '我关注的比赛',
                trailing: const Icon(Icons.chevron_right, size: 14, color: G5Colors.textSecondary),
                onTap: () {
                  // 未登录跳转登录页，已登录跳转我关注的比赛列表
                  if (!G5AuthManager().isLoggedIn) {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const LoginPage()));
                  } else {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MyMatchesPage()));
                  }
                },
              ),
              const Divider(height: 1, color: G5Colors.pitchBorder),
              _buildMenuItem(
                Icons.headset_mic,
                G5Colors.accentGold,
                '在线客服',
                trailing: const Icon(Icons.chevron_right, size: 14, color: G5Colors.textSecondary),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CustomerServicePage()));
                },
              ),
              const Divider(height: 1, color: G5Colors.pitchBorder),
              _buildMenuItem(
                Icons.info,
                G5Colors.accentBlue,
                '关于我们',
                trailing: const Icon(Icons.chevron_right, size: 14, color: G5Colors.textSecondary),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AboutUsPage()));
                },
              ),
              const Divider(height: 1, color: G5Colors.pitchBorder),
              _buildMenuItem(
                Icons.settings,
                G5Colors.textSecondary,
                '设置',
                trailing: const Icon(Icons.chevron_right, size: 14, color: G5Colors.textSecondary),
                onTap: () {
                  // 未登录跳转登录页，已登录跳转设置页
                  if (!G5AuthManager().isLoggedIn) {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const LoginPage()));
                  } else {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsPage()));
                  }
                },
              ),
            ],
          ),
        ),
        
        if (isLoggedIn) ...[
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: G5Colors.pitchCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: G5Colors.pitchBorder),
            ),
            child: _buildMenuItem(
              Icons.logout,
              Colors.redAccent,
              '退出登录',
              onTap: () => _showLogoutConfirmDialog(),
            ),
          ),
        ],
      ],
    );
  }

  void _showLogoutConfirmDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: G5Colors.pitchCard,
          title: const Text('提示', style: TextStyle(color: Colors.white)),
          content: const Text('确定要退出当前账号吗？', style: TextStyle(color: G5Colors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消', style: TextStyle(color: G5Colors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 关闭弹窗
                _performLogout();
              },
              child: const Text('确定', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }

  void _performLogout() async {
    await G5AuthManager().logout();
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('退出成功')),
      );
    }
  }

  Widget _buildMenuItem(IconData icon, Color iconColor, String title, {Widget? trailing, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: G5Colors.textPrimary, fontSize: 12),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
