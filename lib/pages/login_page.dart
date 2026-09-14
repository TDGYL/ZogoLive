import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:captcha_plugin_flutter/captcha_plugin_flutter.dart';
import 'package:livespeed/base/g5_base_view_controller.dart';
import 'package:livespeed/pages/g5_web_view_page.dart';
import 'package:livespeed/utils/g5_colors.dart';
import 'package:livespeed/utils/g5_network_manager.dart';
import 'package:livespeed/utils/g5_auth_manager.dart';
import 'package:livespeed/models/g5_user_model.dart';
import 'package:livespeed/utils/g5_event_bus.dart';

class LoginPage extends G5BaseViewController {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends G5BaseViewState<LoginPage> {
  /// Email输入控制器 - TextEditingController类型，监听Email输入框内容
  final TextEditingController _emailController = TextEditingController();

  /// Code输入控制器 - TextEditingController类型，监听Code输入框内容
  final TextEditingController _codeController = TextEditingController();

  /// 是否同意协议 - bool类型，true表示已勾选Terms of Service与Privacy Policy
  bool _isAgree = false;

  /// 是否正在Log In - bool类型，true表示Log In请求进行中，防止重复提交
  bool _isLoading = false;

  /// 倒计时剩余秒数 - int类型，0表示未在倒计时，>0时按钮不可点击
  int _countdown = 0;

  /// 倒计时定时器 - Timer?类型，用于周期性刷新倒计时秒数，页面销毁时需cancel
  Timer? _countdownTimer;

  /// 网易易盾人机验证插件实例 - CaptchaPluginFlutter类型，用于调起滑块/点选验证
  final CaptchaPluginFlutter _captchaPlugin = CaptchaPluginFlutter();

  /// 网易易盾Code业务ID - String类型，易盾后台分配的VerifyCode
  static const String _captchaVerifyCode = '69d5b2ee3fec46658e01c0b45fc381af';

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
    _countdownTimer?.cancel();
    _captchaPlugin.destroyCaptcha();
    super.dispose();
  }

  /// 点击Get Code
  /// 校验Email非空后，调起网易易盾人机验证，验证成功回调validate后请求SendCode接口
  void _handleGetVerifyCode() {
    // 倒计时中不允许重复获取
    if (_countdown > 0) return;

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    // 调起网易易盾人机验证
    _captchaPlugin.init({
      'captcha_id': _captchaVerifyCode,
      // Load failed时启用降级方案，支持点击重试
      'use_default_fallback': true,
      // 自动降级重试次数
      'failed_max_retry_count': 3,
      // 超时时间（毫秒）
      'timeout': 10000,
      // 点击弹窗外部不消失
      'is_touch_outside_disappear': false,
      // 关闭按钮在底部
      'is_close_button_bottom': true,
    });
    _captchaPlugin.showCaptcha(
      onLoaded: () {
        print('captcha onLoaded');
      },
      onSuccess: (dynamic data) {
        // 验证成功，拿到validate后请求SendCode接口
        print('captcha onSuccess: $data');
        final String validate = data['validate'] ?? '';
        if (validate.isNotEmpty) {
          _sendVerifyCode(validate);
        }
      },
      onError: (dynamic data) {
        // 验证失败
        print('captcha onError: $data');
        _showErrorToast('Captcha failed, try again');
      },
      onClose: (dynamic data) {
        // 用户关闭验证弹窗
        print('captcha onClose: $data');
      },
    );
  }

  /// 请求SendEmailCode
  /// 接口：POST /api/livespeed/auth/send-verify
  /// 参数：validate - String类型，人机验证返回的validate；account - String类型，Email账号
  /// 成功后开启60秒倒计时
  /// 参数：validate - String类型，网易易盾人机验证成功回调的validate
  Future<void> _sendVerifyCode(String validate) async {
    try {
      final response = await G5NetworkManager().post(
        '/api/livespeed/auth/send-verify',
        data: {
          'validate': validate,
          'account': _emailController.text.trim(),
          'channel': 'email',
          'scene': 'sms-login',
        },
      );

      if (response.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Code sent, please check')),
          );
        }
        // 开启倒计时
        _startCountdown();
      } else {
        _showErrorToast(response.message ?? 'Code send failed');
      }
    } catch (e) {
      _showErrorToast('Network error');
    }
  }

  /// 开启60秒Get Code倒计时
  /// 每秒刷新剩余秒数，倒计时期间按钮置灰不可点击，结束后恢复
  void _startCountdown() {
    setState(() {
      _countdown = 60;
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }
    if (_codeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter code')),
      );
      return;
    }
    if (!_isAgree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Terms & Privacy Policy')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print("login-----bigin");
      // 第一步：调用Log In接口
      final loginResponse = await G5NetworkManager().post(
        '/api/livespeed/auth/login',

        data: {
            "channel": "email",
           "account": _emailController.text.trim(),
           "code": _codeController.text.trim(),
        },
      );

      if (loginResponse.isSuccess && loginResponse.data != null) {
        final refreshToken = loginResponse.data['refresh_token'] as String?;
        if (refreshToken != null && refreshToken.isNotEmpty) {
          // Save Token 并设置到请求头
          await G5AuthManager().saveToken(refreshToken);

          // 第二步：请求用户信息
          final userResponse =
              await G5NetworkManager().get('/api/livespeed/member');

          if (userResponse.isSuccess && userResponse.data != null) {
            // 解析并Save用户信息
            final userModel = G5UserModel.fromJson(userResponse.data);
            await G5AuthManager().saveUserInfo(userModel);

            // SendLogin successful通知，让个人中心等需要的地方刷新Stats
            G5EventBus().fire(LoginStatusChangeEvent(true));

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Login successful')),
              );
              Navigator.of(context).pop();
            }
          } else {
            _showErrorToast(userResponse.message ?? 'Failed to get user info');
          }
        } else {
          _showErrorToast('Login failed: token error');
        }
      } else {
        _showErrorToast(loginResponse.message ?? 'Login failed');
      }
    } catch (e) {
      _showErrorToast('Network error');
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

  /// 跳转WebView加载协议页面
  /// 参数：title - String类型，页面标题；url - String类型，加载的协议地址
  void _pushToWebView({required String title, required String url}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => G5WebViewPage(pageTitle: title, webUrl: url),
    ));
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
                            'LIVESPEED',
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
                    'Welcome to LiveSpeed! Enter email to log in or sign up',
                    style: TextStyle(
                      color: G5Colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 表单区
                  // Email输入
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      'Email',
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
                              hintText: 'Enter your email address',
                              hintStyle: TextStyle(
                                  color: G5Colors.textSecondary, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Code输入
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      'EmailCode',
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
                                    hintText: 'Code',
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
                        onTap: _countdown > 0 ? null : _handleGetVerifyCode,
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withOpacity(
                                _countdown > 0 ? 0.1 : 0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0xFF4F46E5).withOpacity(
                                    _countdown > 0 ? 0.15 : 0.3)),
                          ),
                          child: Text(
                            _countdown > 0 ? '$_countdown s' : 'Get Code',
                            style: TextStyle(
                              color: _countdown > 0
                                  ? G5Colors.textSecondary
                                  : const Color(0xFFA5B4FC),
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
                          child: Text.rich(
                            TextSpan(
                              text: 'I have read and agree to the ',
                              style: const TextStyle(
                                  color: G5Colors.textSecondary,
                                  fontSize: 11),
                              children: [
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: const TextStyle(
                                      color: Color(0xFF818CF8)),
                                  // 点击跳转WebView加载Terms of Service
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => _pushToWebView(
                                          title: 'Terms of Service',
                                          url:
                                              'https://www.livespeeds.com/user-agreement?platform=IOS',
                                        ),
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: const TextStyle(
                                      color: Color(0xFF818CF8)),
                                  // 点击跳转WebView加载Privacy Policy
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => _pushToWebView(
                                          title: 'Privacy Policy',
                                          url:
                                              'https://www.livespeeds.com/privacy-agreement?platform=IOS',
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Log In按钮
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
                                'Log In',
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

                  // 下方快捷Log In隐藏了（满足需求）
                  const Spacer(),
                  const Center(
                    child: Text(
                      '© 2026 LiveSpeed. All rights reserved.',
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
