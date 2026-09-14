/// 用户模型
class G5UserModel {
  int? id;
  String? account;
  String? email;
  String? nickname;
  String? avatar;
  String? signature;
  String? mobile;
  String? regTime;
  int? status;
  String? platforms;
  String? lastLoginTime;
  bool? isDebut;
  int? kMoney;
  int? kCoupon;
  int? followers;
  int? fansCount;
  int? sex;

  G5UserModel({
    this.id,
    this.account,
    this.email,
    this.nickname,
    this.avatar,
    this.signature,
    this.mobile,
    this.regTime,
    this.status,
    this.platforms,
    this.lastLoginTime,
    this.isDebut,
    this.kMoney,
    this.kCoupon,
    this.followers,
    this.fansCount,
    this.sex,
  });

  factory G5UserModel.fromJson(Map<String, dynamic> json) {
    return G5UserModel(
      id: json['id'] as int?,
      account: json['account'] as String?,
      email: json['email'] as String?,
      nickname: json['nickname'] as String?,
      avatar: json['avatar'] as String?,
      signature: json['signature'] as String?,
      mobile: json['mobile'] as String?,
      regTime: json['reg_time'] as String?,
      status: json['status'] as int?,
      platforms: json['platforms'] as String?,
      lastLoginTime: json['last_login_time'] as String?,
      isDebut: json['is_debut'] as bool?,
      kMoney: json['k_money'] as int?,
      kCoupon: json['k_coupon'] as int?,
      followers: json['followers'] as int?,
      fansCount: json['fans_count'] as int?,
      sex: json['sex'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account': account,
      'email': email,
      'nickname': nickname,
      'avatar': avatar,
      'signature': signature,
      'mobile': mobile,
      'reg_time': regTime,
      'status': status,
      'platforms': platforms,
      'last_login_time': lastLoginTime,
      'is_debut': isDebut,
      'k_money': kMoney,
      'k_coupon': kCoupon,
      'followers': followers,
      'fans_count': fansCount,
      'sex': sex,
    };
  }
}
