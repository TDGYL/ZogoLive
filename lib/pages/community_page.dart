import 'package:flutter/material.dart';
import 'package:zogolive/base/g5_base_view_controller.dart';
import 'package:zogolive/models/g5_post_model.dart';
import 'package:zogolive/utils/g5_colors.dart';

class CommunityPage extends G5BaseViewController {
  const CommunityPage({Key? key}) : super(key: key);

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends G5BaseViewState<CommunityPage> {
  List<G5PostModel> posts = [];

  @override
  bool get showBackButton => false;

  @override
  void initData() {
    super.initData();
    posts = [
      G5PostModel(
        authorName: '战术狂人安切洛',
        authorAvatarUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=100&q=80',
        publishTime: '20分钟前',
        location: '马德里',
        title: 'Pro 分析师',
        content: '今晚皇马对阵曼城，安切洛蒂在第65分钟的换人堪称胜负手！九张图全景拆解这场世纪对决的高光战术走势 👇',
        imageUrls: [
          'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?auto=format&fit=crop&w=250&q=80',
          'https://images.unsplash.com/photo-1489944440615-453fc2b6a9a9?auto=format&fit=crop&w=250&q=80',
          'https://images.unsplash.com/photo-1522778119026-d647f0596c20?auto=format&fit=crop&w=250&q=80',
          'https://images.unsplash.com/photo-1518091043644-c1d4457512c6?auto=format&fit=crop&w=250&q=80',
          'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&w=250&q=80',
          'https://images.unsplash.com/photo-1511512578047-dfb367046420?auto=format&fit=crop&w=250&q=80',
        ],
        relatedMatch: '关联比赛：皇家马德里 2 - 1 曼城',
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
              color: G5Colors.accentGold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: G5Colors.accentGold.withOpacity(0.3)),
            ),
            child:
                const Icon(Icons.groups, color: G5Colors.accentGold, size: 18),
          ),
          const SizedBox(width: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '极球·社区',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              Text(
                '240,000+ 深度战术球迷研讨',
                style: TextStyle(fontSize: 10, color: G5Colors.textSecondary),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
          child: ElevatedButton.icon(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: G5Colors.accentEmerald,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            icon: const Icon(Icons.edit, size: 12),
            label: const Text('发帖',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return _buildPostCard(posts[index]);
      },
    );
  }

  Widget _buildPostCard(G5PostModel post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: G5Colors.pitchCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: G5Colors.pitchBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: G5Colors.accentGold.withOpacity(0.4)),
                      image: DecorationImage(
                        image: NetworkImage(post.authorAvatarUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${post.publishTime} · ${post.location}',
                        style: const TextStyle(
                          color: G5Colors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: G5Colors.accentEmerald.withOpacity(0.1),
                  border: Border.all(
                      color: G5Colors.accentEmerald.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '+ 关注',
                  style: TextStyle(
                    color: G5Colors.accentEmerald,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.content,
            style: const TextStyle(
              color: G5Colors.textPrimary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          if (post.imageUrls.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: post.imageUrls.length,
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    post.imageUrls[index],
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          const SizedBox(height: 12),
          if (post.relatedMatch.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: G5Colors.pitchElevated,
                border:
                    Border.all(color: G5Colors.accentEmerald.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sports_soccer,
                      color: G5Colors.accentEmerald, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      post.relatedMatch,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: G5Colors.textSecondary, size: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
