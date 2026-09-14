import 'package:flutter/material.dart';
import 'package:zogolive/base/g5_base_view_controller.dart';
import 'package:zogolive/utils/g5_auth_manager.dart';
import 'package:zogolive/utils/g5_colors.dart';
import 'package:zogolive/utils/g5_event_bus.dart';
import 'package:zogolive/utils/g5_network_manager.dart';

/// 设置页
/// 展示当前登录用户邮箱和注销账号入口
/// 仅登录状态可进入（入口处已做登录校验）
class SettingsPage extends G5BaseViewController {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends G5BaseViewState<SettingsPage> {
  /// 是否正在注销 - bool类型，防止重复提交
  bool _isCancelling = false;

  /// 显示注销账号二次确认弹窗
  /// 点击"取消"关闭弹窗，点击"注销"调用注销接口
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: G5Colors.pitchCard,
          title: const Text('提示', style: TextStyle(color: Colors.white)),
          content: const Text('确定要注销账号吗？注销后账号数据将无法恢复',
              style: TextStyle(color: G5Colors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消',
                  style: TextStyle(color: G5Colors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // 关闭弹窗
                _cancelAccount();
              },
              child: const Text('注销',
                  style: TextStyle(color: G5Colors.accentCrimson)),
            ),
          ],
        );
      },
    );
  }

  /// 注销账号
  /// 接口：POST /api/livespeed/member/cancel（无入参）
  /// 成功后清除本地用户信息并回退到个人中心，界面自动刷新
  void _cancelAccount() async {
    if (_isCancelling) return;
    setState(() {
      _isCancelling = true;
    });

    var success = false;
    try {
      final response = await G5NetworkManager()
          .post('/api/livespeed/member/cancel');
      success = response.isSuccess;
    } catch (e) {
      success = false;
    }

    if (!mounted) return;
    setState(() {
      _isCancelling = false;
    });

    if (success) {
      // 删除本地用户信息并发送登录状态变更通知，个人中心自动刷新为未登录状态
      await G5AuthManager().logout();
      G5EventBus().fire(LoginStatusChangeEvent(false));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('注销成功')),
      );
      Navigator.of(context).pop(); // 回退到个人中心
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('注销失败，请稍后重试')),
      );
    }
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: G5Colors.pitch,
      elevation: 0,
      title: const Text(
        '设置',
        style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      centerTitle: true,
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    final user = G5AuthManager().currentUser;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: G5Colors.pitchCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: G5Colors.pitchBorder),
          ),
          child: Column(
            children: [
              // 用户邮箱
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.email,
                        color: G5Colors.accentEmerald, size: 16),
                    const SizedBox(width: 12),
                    const Text(
                      '用户邮箱',
                      style: TextStyle(
                          color: G5Colors.textPrimary, fontSize: 12),
                    ),
                    const Spacer(),
                    // 邮箱占大部分宽度，超长省略
                    Flexible(
                      flex: 2,
                      child: Text(
                        (user?.email?.isNotEmpty ?? false)
                            ? user!.email!
                            : (user?.account ?? '--'),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            color: G5Colors.textSecondary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: G5Colors.pitchBorder),
              // 注销账号
              InkWell(
                onTap: _showDeleteAccountDialog,
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.person_off,
                          color: G5Colors.accentCrimson, size: 16),
                      SizedBox(width: 12),
                      Text(
                        '注销账号',
                        style: TextStyle(
                            color: G5Colors.accentCrimson, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
