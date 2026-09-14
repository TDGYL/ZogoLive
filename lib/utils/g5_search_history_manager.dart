import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 搜索历史管理类
/// 功能：基于SharedPreferences持久化搜索历史记录，最多保留8条，最新的排在最前
class G5SearchHistoryManager {
  /// SharedPreferences存储key - String类型，搜索历史列表的持久化键名
  static const String _storageKey = 'g5_search_history_list';

  /// 最Over历史记录条数 - int类型，超过后自动删除最早的记录
  static const int _maxCount = 8;

  /// 单例实例 - G5SearchHistoryManager?类型，懒加载初始化
  static G5SearchHistoryManager? _instance;

  /// 获取单例实例
  /// 返回：G5SearchHistoryManager，全局唯一实例
  static G5SearchHistoryManager get instance {
    _instance ??= G5SearchHistoryManager._internal();
    return _instance!;
  }

  /// 私有构造函数
  G5SearchHistoryManager._internal();

  /// 读取搜索历史列表
  /// 返回：Future<List<String>>，历史记录数组，最新的在最前面
  Future<List<String>> getHistoryList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_storageKey);
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
      return list.cast<String>();
    } catch (e) {
      return [];
    }
  }

  /// 添加一条搜索历史
  /// 去重处理：已存在时先移除再插入到最前面；超过最Over条数时移除最早的
  /// 参数：keyword - String类型，搜索关键词
  /// 返回：Future<List<String>>，添加后的最新历史列表
  Future<List<String>> addHistory(String keyword) async {
    final String trimmed = keyword.trim();
    // 空字符串不入库
    if (trimmed.isEmpty) return [];

    final List<String> list = await getHistoryList();
    // 去重：已存在则先移除
    list.remove(trimmed);
    // 插入到最前面
    list.insert(0, trimmed);
    // 超出最Over条数时删除最早的
    if (list.length > _maxCount) {
      list.removeRange(_maxCount, list.length);
    }

    await _save(list);
    return list;
  }

  /// 删除全部搜索历史
  /// 返回：Future<void>
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  /// 删除单条搜索历史
  /// 参数：keyword - String类型，要删除的关键词
  /// 返回：Future<List<String>>，删除后的最新历史列表
  Future<List<String>> removeHistory(String keyword) async {
    final List<String> list = await getHistoryList();
    list.remove(keyword.trim());
    await _save(list);
    return list;
  }

  /// 持久化历史列表到本地
  /// 参数：list - List<String>，待Save的历史记录数组
  /// 返回：Future<void>
  Future<void> _save(List<String> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(list));
  }
}
