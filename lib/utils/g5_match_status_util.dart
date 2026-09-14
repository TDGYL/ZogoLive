/// 比赛状态工具类
/// 将接口返回的中文/长状态名统一转换为常规英文缩写展示
/// 足球常用缩写：NS未开赛 / 1H上半场 / HT中场 / 2H下半场 / FT完场 / PEN点球 / CANC取消 / POST推迟
class G5MatchStatusUtil {
  /// 状态缩写映射表 - Map<String, String>类型，中文状态名到英文缩写
  static const Map<String, String> _statusMap = {
    '未开赛': 'NS',
    '未开始': 'NS',
    '赛前': 'NS',
    '上半场': '1H',
    '中场': 'HT',
    '中场休息': 'HT',
    '下半场': '2H',
    '进行中': 'LIVE',
    '完场': 'FT',
    '已完场': 'FT',
    '结束': 'FT',
    '加时': 'ET',
    '点球': 'PEN',
    '点球大战': 'PEN',
    '取消': 'CANC',
    '推迟': 'POST',
    '中断': 'INT',
    '待定': 'TBD',
    '腰斩': 'ABD',
  };

  /// 获取状态缩写
  /// 优先按状态名映射为缩写；已是英文则原样返回（长英文转标准缩写）
  /// 参数：statusName - String?，接口返回的状态名；statusId - int?，状态ID
  /// 返回：String，状态缩写，空数据返回空字符串
  static String abbreviate(String? statusName, {int? statusId}) {
    final name = statusName?.trim() ?? '';

    // 状态名映射
    if (_statusMap.containsKey(name)) {
      return _statusMap[name]!;
    }

    // 状态ID兜底映射（常用约定：0/1未开赛，2/3进行中，4完场等）
    if (name.isEmpty && statusId != null) {
      switch (statusId) {
        case 0:
        case 1:
          return 'NS';
        case 2:
        case 3:
          return 'LIVE';
        case 8:
          return 'FT';
      }
    }

    // 已是英文短状态，直接返回
    return name;
  }

  /// 是否为进行中的比赛
  /// 参数：statusId - int?，状态ID
  /// 返回：bool，true表示进行中
  static bool isLive(int? statusId) {
    return statusId == 2 || statusId == 3 || statusId == 4;
  }
}
