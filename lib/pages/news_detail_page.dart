import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:livespeed/base/g5_base_view_controller.dart';
import 'package:livespeed/models/g5_news_model.dart';
import 'package:livespeed/utils/g5_colors.dart';
import 'package:livespeed/utils/g5_network_manager.dart';

class NewsDetailPage extends G5BaseViewController {
  /// 资讯ID
  final int newsId;

  const NewsDetailPage({Key? key, required this.newsId}) : super(key: key);

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends G5BaseViewState<NewsDetailPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  G5NewsItem? _newsDetail;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(G5Colors.pitch);

    _fetchNewsDetail();
  }

  Future<void> _fetchNewsDetail() async {
    try {
      final response = await G5NetworkManager().get(
        '/api/livespeed/info/detail',
        queryParameters: {'id': widget.newsId},
      );

      if (response.code == 0 && response.data != null) {
        final data = G5NewsItem.fromJson(response.data as Map<String, dynamic>);
        if (mounted) {
          setState(() {
            _newsDetail = data;
            _isLoading = false;
          });
          _loadHtmlContent();
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _loadHtmlContent() {
    if (_newsDetail == null) return;

    final title = _newsDetail!.title ?? '';
    final author = _newsDetail!.author ?? 'Official';
    final time = _formatTime(_newsDetail!.createdAt);
    final content = _newsDetail!.content ?? '';

    final htmlString = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
        <style>
          body {
            padding: 16px;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            background-color: #0f172a;
            color: #e2e8f0;
            line-height: 1.6;
            margin: 0;
          }
          .title {
            font-size: 22px;
            font-weight: bold;
            margin-bottom: 12px;
            color: #ffffff;
            line-height: 1.4;
          }
          .meta {
            font-size: 12px;
            color: #94a3b8;
            margin-bottom: 20px;
            display: flex;
            justify-content: space-between;
          }
          .cover {
            width: 100%;
            border-radius: 8px;
            margin-bottom: 20px;
            object-fit: cover;
          }
          .content {
            font-size: 15px;
            color: #cbd5e1;
            overflow-wrap: break-word;
            word-wrap: break-word;
          }
          .content img {
            max-width: 100%;
            height: auto;
            border-radius: 8px;
            margin: 10px 0;
            display: block;
          }
          .content p {
            margin: 0 0 12px 0;
          }
          a {
            color: #38bdf8;
            text-decoration: none;
          }
        </style>
      </head>
      <body>
        <div class="title">$title</div>
        <div class="meta">
          <span>$author</span>
          <span>$time</span>
        </div>
        <div class="content">
          $content
        </div>
      </body>
      </html>
    ''';

    _controller.loadHtmlString(htmlString);
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: G5Colors.pitch,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'News',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: G5Colors.accentEmerald));
    }

    if (_newsDetail == null) {
      return const Center(
        child: Text('No news yet', style: TextStyle(color: G5Colors.textSecondary)),
      );
    }

    return Container(
      color: G5Colors.pitch,
      child: WebViewWidget(controller: _controller),
    );
  }
}
