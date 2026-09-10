/// 用户模型
class G5UserModel {
  /// 用户ID
  String uid;

  /// 用户昵称
  String nickname;

  /// 头像 URL
  String avatarUrl;

  /// 粉丝数
  String followers;

  /// 关注数
  String following;

  /// 是否登录
  bool isLoggedIn;

  G5UserModel({
    required this.uid,
    required this.nickname,
    required this.avatarUrl,
    required this.followers,
    required this.following,
    this.isLoggedIn = false,
  });

  /// 从 JSON 解析
  factory G5UserModel.fromJson(Map<String, dynamic> json) {
    return G5UserModel(
      uid: json['uid'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      followers: json['followers'] as String? ?? '0',
      following: json['following'] as String? ?? '0',
      isLoggedIn: json['isLoggedIn'] as bool? ?? false,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'followers': followers,
      'following': following,
      'isLoggedIn': isLoggedIn,
    };
  }
}
