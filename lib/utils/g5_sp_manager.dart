import 'package:shared_preferences/shared_preferences.dart';

/// 本地存储管理类
class G5SpManager {
  static SharedPreferences? _prefs;

  /// 初始化
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 保存字符串
  static Future<bool> setString(String key, String value) async {
    if (_prefs == null) await init();
    return _prefs!.setString(key, value);
  }

  /// 获取字符串
  static String? getString(String key) {
    return _prefs?.getString(key);
  }

  /// 清除数据
  static Future<bool> remove(String key) async {
    if (_prefs == null) await init();
    return _prefs!.remove(key);
  }
}
