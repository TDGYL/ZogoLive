import 'dart:convert';
import 'package:livespeed/models/g5_user_model.dart';
import 'package:livespeed/utils/g5_sp_manager.dart';
import 'package:livespeed/utils/g5_network_manager.dart';

class G5AuthManager {
  static final G5AuthManager _instance = G5AuthManager._internal();
  factory G5AuthManager() => _instance;

  G5AuthManager._internal();

  static const String _kTokenKey = 'g5_user_token';
  static const String _kUserInfoKey = 'g5_user_info';

  String? _token;
  G5UserModel? _currentUser;

  /// 获取当前 Token
  String? get token => _token;

  /// 获取当前用户信息
  G5UserModel? get currentUser => _currentUser;

  /// 是否已登录
  bool get isLoggedIn => _token != null && _token!.isNotEmpty && _currentUser != null;

  /// 初始化，从缓存中读取Stats
  Future<void> init() async {
    _token = G5SpManager.getString(_kTokenKey);
    final userInfoJson = G5SpManager.getString(_kUserInfoKey);
    
    if (_token != null && _token!.isNotEmpty) {
      G5NetworkManager().setAuthorizationHeader(_token!);
    }

    if (userInfoJson != null && userInfoJson.isNotEmpty) {
      try {
        final Map<String, dynamic> map = jsonDecode(userInfoJson);
        _currentUser = G5UserModel.fromJson(map);
      } catch (e) {
        _currentUser = null;
      }
    }
  }

  /// Save登录 Token
  Future<void> saveToken(String token) async {
    _token = token;
    await G5SpManager.setString(_kTokenKey, token);
    G5NetworkManager().setAuthorizationHeader(token);
  }

  /// Save用户信息
  Future<void> saveUserInfo(G5UserModel user) async {
    _currentUser = user;
    final jsonString = jsonEncode(user.toJson());
    await G5SpManager.setString(_kUserInfoKey, jsonString);
  }

  /// 退出登录，清除Stats
  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    await G5SpManager.remove(_kTokenKey);
    await G5SpManager.remove(_kUserInfoKey);
    G5NetworkManager().clearAuthorizationHeader();
  }
}