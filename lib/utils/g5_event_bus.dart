import 'dart:async';

/// 简单的全局Events总线
class G5EventBus {
  static final G5EventBus _instance = G5EventBus._internal();
  factory G5EventBus() => _instance;

  G5EventBus._internal();

  final StreamController _streamController = StreamController.broadcast();

  /// 监听指定类型的Events
  Stream<T> on<T>() {
    if (T == dynamic) {
      return _streamController.stream as Stream<T>;
    } else {
      return _streamController.stream.where((event) => event is T).cast<T>();
    }
  }

  /// SendEvents
  void fire(event) {
    _streamController.add(event);
  }
}

/// 登录状态变更Events
class LoginStatusChangeEvent {
  final bool isLoggedIn;
  LoginStatusChangeEvent(this.isLoggedIn);
}

/// 用户信息刷新Events（关注数/粉丝数等变化时触发）
class UserInfoRefreshEvent {}

/// 主页Tab切换Events（index=3表示切到"我的"）
class MainTabSwitchEvent {
  final int index;
  MainTabSwitchEvent(this.index);
}

/// 帖子删除Events（帖子被作者删除后通知列表同步移除）
class PostDeleteEvent {
  /// 被删除的帖子ID - int类型，用于列表定位删除项
  final int postId;

  PostDeleteEvent(this.postId);
}