import 'package:flutter/material.dart';
import 'package:zogolive/base/g5_base_view_controller.dart';
import 'package:zogolive/models/g5_news_model.dart';
import 'package:zogolive/utils/g5_colors.dart';

class NewsPage extends G5BaseViewController {
  const NewsPage({Key? key}) : super(key: key);

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends G5BaseViewState<NewsPage> {
  List<G5NewsModel> newsList = [];

  @override
  bool get showBackButton => false;

  @override
  void initData() {
    super.initData();
    newsList = [
      G5NewsModel(
        title: '欧冠淘汰赛分析：四大豪门齐聚死亡半区，谁能踏平伯纳乌？',
        publishTime: '10分钟前',
        reads: '4.8w',
        coverUrl:
            'https://images.unsplash.com/photo-1518091043644-c1d4457512c6?auto=format&fit=crop&w=600&q=80',
        source: '深度专栏',
        isHeadline: true,
      ),
      G5NewsModel(
        title: '哈兰德专访：并不在意金球奖排名，团队大满贯才是我唯一的执念',
        publishTime: '1小时前',
        reads: '1.8w',
        coverUrl:
            'https://images.unsplash.com/photo-1522778119026-d647f0596c20?auto=format&fit=crop&w=300&q=80',
        source: '深度专访',
      ),
      G5NewsModel(
        title: '国际足联宣布：2027世俱杯扩军方案正式通过，总奖金破10亿美金',
        publishTime: '3小时前',
        reads: '2.4w',
        coverUrl:
            'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&w=300&q=80',
        source: 'FIFA 动态',
      ),
    ];
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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: newsList.length,
      itemBuilder: (context, index) {
        final news = newsList[index];
        if (news.isHeadline) {
          return _buildHeadlineCard(news);
        } else {
          return _buildNormalNewsCard(news);
        }
      },
    );
  }

  Widget _buildHeadlineCard(G5NewsModel news) {
    return Container(
      height: 180,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: G5Colors.pitchBorder),
        image: DecorationImage(
          image: NetworkImage(news.coverUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
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
              news.title,
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
                  '${news.reads} 阅读量 · ${news.publishTime}',
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
    );
  }

  Widget _buildNormalNewsCard(G5NewsModel news) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: G5Colors.pitchCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: G5Colors.pitchBorder),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              news.coverUrl,
              width: 96,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  news.title,
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
                      '${news.reads} 阅读量 · ${news.publishTime}',
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
    );
  }
}
