import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/post.dart';
import '../providers.dart';
import '../widgets/post_card.dart';

final postDetailProvider =
    FutureProvider.family<Post, String>((ref, postId) async {
  final api = ref.read(apiClientProvider);
  return api.getPostDetail(postId);
});

class PostDetailScreen extends ConsumerWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(postDetailProvider(postId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('详情'),
      ),
      body: postAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              const Text('加载失败'),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(postDetailProvider(postId)),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (post) => _PostDetailBody(post: post),
      ),
    );
  }
}

class _PostDetailBody extends StatelessWidget {
  final Post post;

  const _PostDetailBody({required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entity = post.entity;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Entity info bar
          if (entity != null)
            GestureDetector(
              onTap: () => context.push('/entity/${entity.id}'),
              child: Row(
                children: [
                  _buildAvatar(entity.avatar, 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(entity.name,
                                style: theme.textTheme.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            if (entity.identityTag.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  entity.identityTag,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color:
                                        theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatRelativeTime(post.publishedAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // AI Core Insight card
          if (post.insightZh.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          color: theme.colorScheme.onPrimary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'AI 核心洞察',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onPrimary.withOpacity(0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    post.insightZh,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // AI Detailed Interpretation
          if (post.interpretationZh.isNotEmpty) ...[
            Text(
              'AI 深度解读',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              post.interpretationZh,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.8,
                fontSize: 16,
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Original link
          if (post.sourceUrl.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => launchUrl(Uri.parse(post.sourceUrl)),
                icon: const Text('🔗'),
                label: const Text('查看原文链接'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Widget _buildAvatar(String url, double radius) {
  if (url.isEmpty) {
    return CircleAvatar(
      radius: radius,
      child: const Icon(Icons.person, size: 18),
    );
  }
  return CircleAvatar(
    radius: radius,
    backgroundImage: CachedNetworkImageProvider(url),
  );
}
