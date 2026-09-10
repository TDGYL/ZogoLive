import 'package:flutter/foundation.dart';

/// 基础 ViewModel
class G5BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;

  /// 是否正在加载
  bool get isLoading => _isLoading;

  /// 设置加载状态并通知
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }
}
