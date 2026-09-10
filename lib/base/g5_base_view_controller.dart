import 'package:flutter/material.dart';

/// 基础视图控制器基类
abstract class G5BaseViewController extends StatefulWidget {
  const G5BaseViewController({Key? key}) : super(key: key);
}

/// 基础视图状态基类
abstract class G5BaseViewState<T extends G5BaseViewController>
    extends State<T> {
  /// 获取当前页面的标题
  String get pageTitle => '';

  /// 是否需要显示返回按钮
  bool get showBackButton => true;

  @override
  void initState() {
    super.initState();
    initData();
  }

  /// 初始化数据，子类可重写
  void initData() {
    // 默认空实现
  }

  /// 构建页面主体，子类必须实现
  Widget buildBody(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14), // G5Colors.pitch
      appBar: buildAppBar(context),
      body: buildBody(context),
    );
  }

  /// 构建导航栏
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    if (pageTitle.isEmpty) {
      return null; // 没有标题时不显示默认导航栏
    }
    return AppBar(
      backgroundColor: const Color(0xFF0B0E14),
      elevation: 0,
      centerTitle: true,
      title: Text(
        pageTitle,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
    );
  }
}
