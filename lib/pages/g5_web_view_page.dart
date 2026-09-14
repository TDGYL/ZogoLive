import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:zogolive/base/g5_base_view_controller.dart';
import 'package:zogolive/utils/g5_colors.dart';

/// 通用WebView页
/// 用于加载用户协议、隐私协议等H5页面
class G5WebViewPage extends G5BaseViewController {
  /// 页面标题 - String类型，AppBar展示的标题
  final String pageTitle;

  /// 加载的URL - String类型，WebView加载的地址
  final String webUrl;

  const G5WebViewPage({
    Key? key,
    required this.pageTitle,
    required this.webUrl,
  }) : super(key: key);

  @override
  State<G5WebViewPage> createState() => _G5WebViewPageState();
}

class _G5WebViewPageState extends G5BaseViewState<G5WebViewPage> {
  /// WebView控制器 - WebViewController类型，管理WebView加载
  late final WebViewController _webController;

  /// 是否正在加载 - bool类型，控制加载进度条展示
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(G5Colors.pitch)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.webUrl));
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: G5Colors.pitch,
      elevation: 0,
      title: Text(
        widget.pageTitle,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      centerTitle: true,
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _webController),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(color: G5Colors.accentEmerald),
          ),
      ],
    );
  }
}
