import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:livespeed/base/g5_base_view_controller.dart';
import 'package:livespeed/pages/g5_web_view_page.dart';
import 'package:livespeed/utils/g5_colors.dart';

/// About页
/// 展示项目Logo、版本号及Terms of Service、Privacy Policy、Website入口列表
class AboutUsPage extends G5BaseViewController {
  const AboutUsPage({Key? key}) : super(key: key);

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends G5BaseViewState<AboutUsPage> {
  /// 应用版本号 - String类型，展示在Logo下方
  static const String _appVersion = 'v1.0.0';

  /// Terms of ServiceURL - String类型，点击Terms of Service跳转WebView加载
  static const String _userAgreementUrl =
      'https://www.livespeeds.com/user-agreement?platform=IOS';

  /// Privacy PolicyURL - String类型，点击Privacy Policy跳转WebView加载
  static const String _privacyAgreementUrl =
      'https://www.livespeeds.com/privacy-agreement?platform=IOS';

  /// Website - String类型，右侧展示文案
  static const String _officialWebsite = 'https://www.livespeeds.com';

  /// 跳转WebView加载协议页面
  /// 参数：title - String类型，页面标题；url - String类型，加载的地址
  void _pushToWebView({required String title, required String url}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => G5WebViewPage(pageTitle: title, webUrl: url),
    ));
  }

  /// 复制Website到剪贴板
  /// Copied后toastNotice
  void _copyWebsite() async {
    await Clipboard.setData(const ClipboardData(text: _officialWebsite));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied')),
      );
    }
  }

  /// 构建列表项
  /// 参数：icon - IconData类型，左侧图标；iconColor - Color类型，图标颜色；
  ///       title - String类型，标题；trailing - Widget?类型，右侧内容；
  ///       onTap - VoidCallback?类型，点击回调
  /// 返回：Widget，可点击的列表项
  Widget _buildListItem(
    IconData icon,
    Color iconColor,
    String title, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
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
                style: const TextStyle(
                    color: G5Colors.textPrimary, fontSize: 12),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: G5Colors.pitch,
      elevation: 0,
      title: const Text(
        'About',
        style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      centerTitle: true,
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 40),
        // 项目Logo
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/live_speed_icon.jpg',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: G5Colors.accentEmerald.withOpacity(0.15),
                  border: Border.all(
                      color: G5Colors.accentEmerald.withOpacity(0.3)),
                ),
                child: const Icon(Icons.sports_soccer,
                    color: G5Colors.accentEmerald, size: 40),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 版本号
        const Center(
          child: Text(
            _appVersion,
            style: TextStyle(
                color: G5Colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 40),
        // 功能列表
        Container(
          decoration: BoxDecoration(
            color: G5Colors.pitchCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: G5Colors.pitchBorder),
          ),
          child: Column(
            children: [
              _buildListItem(
                Icons.description,
                G5Colors.accentEmerald,
                'Terms of Service',
                trailing: const Icon(Icons.chevron_right,
                    size: 14, color: G5Colors.textSecondary),
                onTap: () {
                  _pushToWebView(title: 'Terms of Service', url: _userAgreementUrl);
                },
              ),
              const Divider(height: 1, color: G5Colors.pitchBorder),
              _buildListItem(
                Icons.privacy_tip,
                G5Colors.accentBlue,
                'Privacy Policy',
                trailing: const Icon(Icons.chevron_right,
                    size: 14, color: G5Colors.textSecondary),
                onTap: () {
                  _pushToWebView(title: 'Privacy Policy', url: _privacyAgreementUrl);
                },
              ),
              const Divider(height: 1, color: G5Colors.pitchBorder),
              _buildListItem(
                Icons.language,
                G5Colors.accentGold,
                'Website',
                trailing: const Text(
                  _officialWebsite,
                  style: TextStyle(
                      color: G5Colors.textSecondary, fontSize: 10),
                ),
                onTap: _copyWebsite,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
