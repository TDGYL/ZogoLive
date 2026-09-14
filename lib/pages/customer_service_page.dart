import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zogolive/base/g5_base_view_controller.dart';
import 'package:zogolive/utils/g5_colors.dart';

/// 在线客服页
/// 展示客服邮箱列表，支持一键复制邮箱地址
class CustomerServicePage extends G5BaseViewController {
  const CustomerServicePage({Key? key}) : super(key: key);

  @override
  State<CustomerServicePage> createState() => _CustomerServicePageState();
}

class _CustomerServicePageState extends G5BaseViewState<CustomerServicePage> {
  /// 客服邮箱 - String类型，对外展示的客服联系方式
  static const String _serviceEmail = 'LiveSpeedService@outlook.com';

  /// 复制邮箱到剪贴板
  /// 复制成功后toast提示
  void _copyEmail() async {
    await Clipboard.setData(const ClipboardData(text: _serviceEmail));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('复制成功')),
      );
    }
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: G5Colors.pitch,
      elevation: 0,
      title: const Text(
        '在线客服',
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
        Container(
          decoration: BoxDecoration(
            color: G5Colors.pitchCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: G5Colors.pitchBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // 邮箱头像
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: G5Colors.accentGold.withOpacity(0.15),
                    border: Border.all(
                        color: G5Colors.accentGold.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.email,
                      color: G5Colors.accentGold, size: 20),
                ),
                const SizedBox(width: 12),
                // 邮箱地址
                const Expanded(
                  child: Text(
                    _serviceEmail,
                    style: TextStyle(
                      color: G5Colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // 复制按钮
                GestureDetector(
                  onTap: _copyEmail,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: G5Colors.accentEmerald.withOpacity(0.1),
                      border: Border.all(
                          color: G5Colors.accentEmerald.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy,
                            color: G5Colors.accentEmerald, size: 12),
                        SizedBox(width: 4),
                        Text(
                          '复制',
                          style: TextStyle(
                            color: G5Colors.accentEmerald,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
