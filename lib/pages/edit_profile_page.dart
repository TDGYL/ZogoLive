import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:livespeed/base/g5_base_view_controller.dart';
import 'package:livespeed/utils/g5_auth_manager.dart';
import 'package:livespeed/utils/g5_colors.dart';

/// Edit Profile页
/// 展示头像、Nickname输入框、Gender选择和Save按钮
/// 头像支持从相册选择，点击SaveNotice"Submitted for review!"
class EditProfilePage extends G5BaseViewController {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends G5BaseViewState<EditProfilePage> {
  /// Nickname输入控制器 - TextEditingController类型，管理Nickname输入框文本
  final TextEditingController _nicknameController = TextEditingController();

  /// 用户头像 - String?类型，当前展示的头像URL或本地路径
  String? _avatar;

  /// 是否选择了本地头像 - bool类型，true表示头像来自相册选择
  bool _isLocalAvatar = false;

  /// Gender - int?类型，1Male 2Female，null/0未知
  int? _sex;

  @override
  void initState() {
    super.initState();
    // 用当前登录用户信息初始化表单
    final user = G5AuthManager().currentUser;
    _nicknameController.text = user?.nickname ?? '';
    _avatar = user?.avatar;
    _sex = user?.sex;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  /// Save资料
  /// 点击Save直接Notice：Submitted for review!
  void _saveProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Submitted for review!')),
    );
  }

  /// 从相册选择头像
  /// 调起系统相册，选择成功后更新本地头像展示
  void _pickAvatar() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null && mounted) {
      setState(() {
        _avatar = pickedFile.path;
        _isLocalAvatar = true;
      });
    }
  }

  /// 显示Gender选择弹窗
  /// 提供Male/Female两个选项，选择后更新Gender
  void _showSexPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: G5Colors.pitchCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              _buildSexOption(sheetContext, 1, 'Male', Icons.male),
              const Divider(height: 1, color: G5Colors.pitchBorder),
              _buildSexOption(sheetContext, 2, 'Female', Icons.female),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// 构建Gender选项行
  /// 参数：sheetContext - BuildContext，弹窗上下文；
  ///       value - int类型，Gender值；label - String类型，选项文案；icon - IconData类型，图标
  /// 返回：Widget，可点击的选项行
  Widget _buildSexOption(
      BuildContext sheetContext, int value, String label, IconData icon) {
    final selected = _sex == value;
    return InkWell(
      onTap: () {
        Navigator.of(sheetContext).pop();
        setState(() {
          _sex = value;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon,
                color: selected
                    ? G5Colors.accentEmerald
                    : G5Colors.textSecondary,
                size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: G5Colors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check,
                  color: G5Colors.accentEmerald, size: 18),
          ],
        ),
      ),
    );
  }

  /// Gender文案
  /// 返回：String，1Male 2Female 其他未知
  String get _sexText {
    switch (_sex) {
      case 1:
        return 'Male';
      case 2:
        return 'Female';
      default:
        return 'Unset';
    }
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: G5Colors.pitch,
      elevation: 0,
      title: const Text(
        'Edit Profile',
        style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      centerTitle: true,
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 头像：点击进入相册选择
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickAvatar,
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: G5Colors.pitchElevated,
                      border:
                          Border.all(color: G5Colors.pitchBorder, width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: (_avatar != null && _avatar!.isNotEmpty)
                        ? (_isLocalAvatar
                            ? Image.file(
                                File(_avatar!),
                                width: 84,
                                height: 84,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                _avatar!,
                                width: 84,
                                height: 84,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const Icon(
                                    Icons.person,
                                    color: G5Colors.textSecondary,
                                    size: 40),
                              ))
                        : const Icon(Icons.person,
                            color: G5Colors.textSecondary, size: 40),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap to change avatar',
                  style: TextStyle(
                      color: G5Colors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 表单卡片
          Container(
            decoration: BoxDecoration(
              color: G5Colors.pitchCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: G5Colors.pitchBorder),
            ),
            child: Column(
              children: [
                // Nickname输入框
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 72,
                        child: Text(
                          'Nickname',
                          style: TextStyle(
                              color: G5Colors.textSecondary, fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _nicknameController,
                          style: const TextStyle(
                              color: G5Colors.textPrimary, fontSize: 14),
                          maxLength: 20,
                          decoration: const InputDecoration(
                            hintText: 'Enter nickname',
                            hintStyle: TextStyle(
                                color: G5Colors.textSecondary, fontSize: 13),
                            border: InputBorder.none,
                            counterText: '',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: G5Colors.pitchBorder),
                // Gender选择
                InkWell(
                  onTap: _showSexPicker,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 72,
                          child: Text(
                            'Gender',
                            style: TextStyle(
                                color: G5Colors.textSecondary, fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _sexText,
                            style: const TextStyle(
                                color: G5Colors.textPrimary, fontSize: 14),
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            size: 14, color: G5Colors.textSecondary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Save按钮
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: G5Colors.accentEmerald,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
