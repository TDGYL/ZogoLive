import 'package:flutter/material.dart';
import 'package:zogolive/base/g5_base_view_controller.dart';
import 'package:zogolive/models/g5_user_model.dart';
import 'package:zogolive/utils/g5_colors.dart';
import 'package:zogolive/pages/login_page.dart';

class ProfilePage extends G5BaseViewController {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends G5BaseViewState<ProfilePage> {
  late G5UserModel user;

  @override
  bool get showBackButton => false;

  @override
  void initData() {
    super.initData();
    user = G5UserModel(
      uid: '88492041',
      nickname: '战术狂人安切洛',
      avatarUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80',
      followers: '12.4k',
      following: '350',
      isLoggedIn: true,
    );
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    user.isLoggedIn = !user.isLoggedIn;
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: G5Colors.pitch,
                    border: Border.all(color: G5Colors.pitchBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sync,
                          color: G5Colors.accentEmerald, size: 10),
                      const SizedBox(width: 4),
                      Text(
                        user.isLoggedIn ? '切换未登录状态' : '切换已登录状态',
                        style: const TextStyle(
                            color: G5Colors.accentEmerald, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              const Icon(Icons.settings,
                  color: G5Colors.textSecondary, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: G5Colors.pitchBorder, width: 2),
                  image: DecorationImage(
                    image: NetworkImage(
                      user.isLoggedIn
                          ? user.avatarUrl
                          : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.isLoggedIn ? user.nickname : '未登录用户',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.isLoggedIn ? 'ID: ${user.uid}' : 'ID: --',
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
                        user.isLoggedIn ? user.followers : '0',
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
                        user.isLoggedIn ? user.following : '0',
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
    return Container(
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
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const LoginPage()));
            },
          ),
          const Divider(height: 1, color: G5Colors.pitchBorder),
          _buildMenuItem(
            Icons.headset_mic,
            G5Colors.accentGold,
            '在线客服',
            trailing: const Icon(Icons.chevron_right, size: 14, color: G5Colors.textSecondary),
          ),
          const Divider(height: 1, color: G5Colors.pitchBorder),
          _buildMenuItem(
            Icons.info,
            G5Colors.accentBlue,
            '关于我们',
            trailing: const Text('v2.8', style: TextStyle(color: G5Colors.textSecondary, fontSize: 10)),
          ),
          const Divider(height: 1, color: G5Colors.pitchBorder),
          _buildMenuItem(
            Icons.settings,
            G5Colors.textSecondary,
            '设置',
            trailing: const Icon(Icons.chevron_right, size: 14, color: G5Colors.textSecondary),
          ),
        ],
      ),
    );
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
