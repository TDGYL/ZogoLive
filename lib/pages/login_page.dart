import 'package:flutter/material.dart';
import 'package:zogolive/base/g5_base_view_controller.dart';
import 'package:zogolive/utils/g5_colors.dart';
import 'package:zogolive/utils/g5_network_manager.dart';
import 'package:zogolive/utils/g5_auth_manager.dart';
import 'package:zogolive/models/g5_user_model.dart';
import 'package:zogolive/utils/g5_event_bus.dart';

class LoginPage extends G5BaseViewController {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends G5BaseViewState<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  bool _isAgree = false;
  bool _isLoading = false;

  @override
  bool get showBackButton => false;

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return null; // 自定义导航
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入电子邮箱')),
      );
      return;
    }
    if (_codeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入验证码')),
      );
      return;
    }
    if (!_isAgree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请阅读并同意服务协议与隐私政策')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print("login-----bigin");
      // 第一步：调用登录接口
      final loginResponse = await G5NetworkManager().post(
        '/api/livespeed/auth/login',
        // data: {
        //   "channel": "email",
        //   "account": _emailController.text.trim(),
        //   "code": _codeController.text.trim(),
        // },
        data: {
          "channel": "email",
          "account": "offical@livespeeds.com",
          "code": "1086",
        },
      );

      if (loginResponse.isSuccess && loginResponse.data != null) {
        final refreshToken = loginResponse.data['refresh_token'] as String?;
        if (refreshToken != null && refreshToken.isNotEmpty) {
          // 保存 Token 并设置到请求头
          await G5AuthManager().saveToken(refreshToken);

          // 第二步：请求用户信息
          final userResponse =
              await G5NetworkManager().get('/api/livespeed/member');

          if (userResponse.isSuccess && userResponse.data != null) {
            // 解析并保存用户信息
            final userModel = G5UserModel.fromJson(userResponse.data);
            await G5AuthManager().saveUserInfo(userModel);

            // 发送登录成功通知，让个人中心等需要的地方刷新数据
            G5EventBus().fire(LoginStatusChangeEvent(true));

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('登录成功')),
              );
              Navigator.of(context).pop();
            }
          } else {
            _showErrorToast(userResponse.message ?? '获取用户信息失败');
          }
        } else {
          _showErrorToast('登录失败：Token 异常');
        }
      } else {
        _showErrorToast(loginResponse.message ?? '登录失败');
      }
    } catch (e) {
      _showErrorToast('网络请求异常');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorToast(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget buildBody(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Stack(
        children: [
          // 背景光晕
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6366F1).withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFEC4899).withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // 顶部导航栏
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.1)),
                          ),
                          child: const Icon(Icons.arrow_back,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: G5Colors.accentEmerald,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'ZOGOLIVE',
                            style: TextStyle(
                              color: G5Colors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // 标题区
                  const Text(
                    'Login/Regist',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '欢迎来到 ZogoLive！请输入邮箱登录或注册账号',
                    style: TextStyle(
                      color: G5Colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 表单区
                  // 邮箱输入
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      '电子邮箱',
                      style: TextStyle(
                        color: G5Colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: G5Colors.pitchElevated.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.email_outlined,
                            color: G5Colors.textSecondary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _emailController,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: '请输入您的邮箱地址',
                              hintStyle: TextStyle(
                                  color: G5Colors.textSecondary, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 验证码输入
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      '邮箱验证码',
                      style: TextStyle(
                        color: G5Colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: G5Colors.pitchElevated.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.1)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Icon(Icons.shield_outlined,
                                  color: G5Colors.textSecondary, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _codeController,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      letterSpacing: 2),
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    counterText: '',
                                    hintText: '验证码',
                                    hintStyle: TextStyle(
                                        color: G5Colors.textSecondary,
                                        fontSize: 14,
                                        letterSpacing: 0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          // 获取验证码逻辑
                        },
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color:
                                    const Color(0xFF4F46E5).withOpacity(0.3)),
                          ),
                          child: const Text(
                            '获取验证码',
                            style: TextStyle(
                              color: Color(0xFFA5B4FC),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 协议勾选
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isAgree = !_isAgree;
                          });
                        },
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _isAgree
                                ? const Color(0xFF4F46E5)
                                : G5Colors.pitchElevated,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _isAgree
                                  ? const Color(0xFF4F46E5)
                                  : G5Colors.textSecondary,
                            ),
                          ),
                          child: _isAgree
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 12)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isAgree = !_isAgree;
                            });
                          },
                          child: const Text.rich(
                            TextSpan(
                              text: '我已阅读并同意 ',
                              style: TextStyle(
                                  color: G5Colors.textSecondary, fontSize: 11),
                              children: [
                                TextSpan(
                                  text: '服务协议',
                                  style: TextStyle(color: Color(0xFF818CF8)),
                                ),
                                TextSpan(text: ' 与 '),
                                TextSpan(
                                  text: '隐私政策',
                                  style: TextStyle(color: Color(0xFF818CF8)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // 登录按钮
                  GestureDetector(
                    onTap: _isLoading ? null : _handleLogin,
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF6366F1),
                            Color(0xFFA855F7),
                            Color(0xFFEC4899),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                '登 录',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                      ),
                    ),
                  ),

                  // 下方快捷登录隐藏了（满足需求）
                  const Spacer(),
                  const Center(
                    child: Text(
                      '© 2026 ZogoLive. All rights reserved.',
                      style: TextStyle(
                        color: G5Colors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
