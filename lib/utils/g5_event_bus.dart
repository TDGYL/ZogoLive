import 'dart:async';

/// 简单的全局事件总线
class G5EventBus {
  static final G5EventBus _instance = G5EventBus._internal();
  factory G5EventBus() => _instance;

  G5EventBus._internal();

  final StreamController _streamController = StreamController.broadcast();

  /// 监听指定类型的事件
  Stream<T> on<T>() {
    if (T == dynamic) {
      return _streamController.stream as Stream<T>;
    } else {
      return _streamController.stream.where((event) => event is T).cast<T>();
    }
  }

  /// 发送事件
  void fire(event) {
    _streamController.add(event);
  }
}

/// 登录状态变更事件
class LoginStatusChangeEvent {
  final bool isLoggedIn;
  LoginStatusChangeEvent(this.isLoggedIn);
}