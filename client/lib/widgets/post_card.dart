import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/post.dart';

String formatRelativeTime(String isoDate) {
  if (isoDate.isEmpty) return '';
  final date = DateTime.tryParse(isoDate);
  if (date == null) return '';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return '刚刚';
  if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
  if (diff.inHours < 24) return '${diff.inHours}小时前';
  if (diff.inDays < 30) return '${diff.inDays}天前';
  if (diff.inDays < 365) return '${diff.inDays ~/ 30}个月前';
  return '${diff.inDays ~/ 365}年前';
}

IconData sourceIcon(String sourceType) {
  switch (sourceType) {
    case 'twitter':
      return Icons.tag;
    case 'blog':
      return Icons.article_outlined;
    case 'github':
      return Icons.code;
    case 'news':
      return Icons.newspaper;
    default:
      return Icons.link;
  }
}

class PostCard extends StatelessWidget {
  final Post post;
  final bool showEntityRow;

  const PostCard({super.key, required this.post, this.showEntityRow = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entity = post.entity;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/post/${post.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showEntityRow && entity != null) ...[
                _EntityRow(entity: entity, post: post, theme: theme),
                const SizedBox(height: 12),
              ],
              Text(
                post.summaryZh.isNotEmpty ? post.summaryZh : '暂无摘要',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (post.originalText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  post.originalText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EntityRow extends StatelessWidget {
  final PostEntity entity;
  final Post post;
  final ThemeData theme;

  const _EntityRow({
    required this.entity,
    required this.post,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.push('/entity/${entity.id}'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAvatar(entity.avatar, 18),
              const SizedBox(width: 8),
              Text(
                entity.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (entity.identityTag.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    entity.identityTag,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const Spacer(),
        Icon(sourceIcon(post.sourceType),
            size: 14, color: theme.colorScheme.onSurface.withOpacity(0.4)),
        const SizedBox(width: 4),
        Text(
          formatRelativeTime(post.publishedAt),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
      ],
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
