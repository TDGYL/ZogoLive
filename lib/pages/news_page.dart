import 'package:flutter/material.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:zogolive/base/g5_base_view_controller.dart';
import 'package:zogolive/models/g5_news_model.dart';
import 'package:zogolive/pages/news_detail_page.dart';
import 'package:zogolive/utils/g5_colors.dart';
import 'package:zogolive/utils/g5_network_manager.dart';

class NewsPage extends G5BaseViewController {
  const NewsPage({Key? key}) : super(key: key);

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends G5BaseViewState<NewsPage> {
  final EasyRefreshController _refreshController = EasyRefreshController(
    controlFinishRefresh: true,
    controlFinishLoad: true,
  );

  List<G5NewsItem> newsList = [];
  int _page = 1;
  final int _size = 10;
  bool _isFirstLoading = true;

  @override
  bool get showBackButton => false;

  @override
  void initData() {
    super.initData();
    _fetchData(isRefresh: true);
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _fetchData({required bool isRefresh}) async {
    if (isRefresh) {
      _page = 1;
    } else {
      _page++;
    }

    final params = {
      "type": 1,
      "page": _page,
      "size": _size,
    };

    final response = await G5NetworkManager().get(
      '/api/v1/info/list',
      queryParameters: params,
    );
    print("请求成功---re${response.isSuccess}");
    if (response.isSuccess) {
      final data = G5NewsData.fromJson(response.data);
      final newItems = data.results ?? [];
      print("请求成功---news");
      setState(() {
        if (isRefresh) {
          newsList = newItems;
        } else {
          newsList.addAll(newItems);
        }
        if (_isFirstLoading) {
          _isFirstLoading = false;
        }
      });

      if (isRefresh) {
        print("请求成功---news--1");
        _refreshController.finishRefresh(IndicatorResult.success);
        _refreshController.resetFooter();
      } else {
        _refreshController.finishLoad(
          newItems.length < _size
              ? IndicatorResult.noMore
              : IndicatorResult.success,
        );
      }
    } else {
      setState(() {
        if (_isFirstLoading) {
          _isFirstLoading = false;
        }
      });
      if (isRefresh) {
        _refreshController.finishRefresh(IndicatorResult.fail);
      } else {
        _refreshController.finishLoad(IndicatorResult.fail);
      }
    }
  }

  // 辅助方法：时间戳转相对时间
  String _formatPublishTime(int? timestamp) {
    if (timestamp == null || timestamp == 0) return '';
    final now = DateTime.now();
    final publishDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final difference = now.difference(publishDate);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else {
      return '${publishDate.month}-${publishDate.day}';
    }
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: G5Colors.pitch,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: G5Colors.accentBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: G5Colors.accentBlue.withOpacity(0.3)),
            ),
            child:
                const Icon(Icons.article, color: G5Colors.accentBlue, size: 18),
          ),
          const SizedBox(width: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '极球·深度资讯',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              Text(
                '权威体育记者 24 小时实时快讯',
                style: TextStyle(fontSize: 10, color: G5Colors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    if (_isFirstLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: G5Colors.accentEmerald,
        ),
      );
    }

    return EasyRefresh(
      controller: _refreshController,
      header: const ClassicHeader(
        dragText: '下拉刷新',
        armedText: '释放刷新',
        readyText: '正在刷新...',
        processingText: '正在刷新...',
        processedText: '刷新成功',
        noMoreText: '没有更多',
        failedText: '刷新失败',
        messageText: '最后更新于 %T',
        iconTheme: IconThemeData(color: G5Colors.accentEmerald),
        textStyle: TextStyle(color: G5Colors.textSecondary, fontSize: 12),
        messageStyle: TextStyle(color: G5Colors.textSecondary, fontSize: 10),
      ),
      footer: const ClassicFooter(
        dragText: '上拉加载',
        armedText: '释放加载',
        readyText: '正在加载...',
        processingText: '正在加载...',
        processedText: '加载成功',
        noMoreText: '没有更多数据了',
        failedText: '加载失败',
        messageText: '最后更新于 %T',
        iconTheme: IconThemeData(color: G5Colors.accentEmerald),
        textStyle: TextStyle(color: G5Colors.textSecondary, fontSize: 12),
        messageStyle: TextStyle(color: G5Colors.textSecondary, fontSize: 10),
      ),
      onRefresh: () => _fetchData(isRefresh: true),
      onLoad: () => _fetchData(isRefresh: false),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: newsList.length,
        itemBuilder: (context, index) {
          final news = newsList[index];
          // 第一个元素作为 Headline
          if (index == 0) {
            return _buildHeadlineCard(news);
          } else {
            return _buildNormalNewsCard(news);
          }
        },
      ),
    );
  }

  Widget _buildHeadlineCard(G5NewsItem news) {
    return GestureDetector(
      onTap: () {
        if (news.id != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailPage(newsId: news.id!),
            ),
          );
        }
      },
      child: Container(
        height: 180,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: G5Colors.pitchBorder),
          color: G5Colors.pitchElevated,
        ),
        child: Stack(
          children: [
            if (news.cover != null && news.cover!.isNotEmpty)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    news.cover!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(),
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    G5Colors.pitch.withOpacity(0.8),
                    G5Colors.pitch,
                  ],
                ),
              ),
              padding: const EdgeInsets.all(14),
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.title ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.remove_red_eye,
                          color: G5Colors.textSecondary, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${news.contentCounts ?? 0} 阅读量 · ${_formatPublishTime(news.createdAt)}',
                        style: const TextStyle(
                          color: G5Colors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalNewsCard(G5NewsItem news) {
    return GestureDetector(
      onTap: () {
        if (news.id != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailPage(newsId: news.id!),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: G5Colors.pitchCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: G5Colors.pitchBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 96,
              height: 80,
              decoration: BoxDecoration(
                color: G5Colors.pitchElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: news.cover != null && news.cover!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        news.cover!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image,
                                color: G5Colors.textSecondary),
                      ),
                    )
                  : const Icon(Icons.image, color: G5Colors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    news.title ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.remove_red_eye,
                          color: G5Colors.textSecondary, size: 10),
                      const SizedBox(width: 4),
                      Text(
                        '${news.contentCounts ?? 0} 阅读量 · ${_formatPublishTime(news.createdAt)}',
                        style: const TextStyle(
                          color: G5Colors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
