import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/entity.dart';
import '../models/post.dart';
import '../providers.dart';
import '../widgets/post_card.dart';

final entityDetailProvider =
    FutureProvider.family<Entity, String>((ref, entityId) async {
  final api = ref.read(apiClientProvider);
  return api.getEntity(entityId);
});

final entityPostsProvider =
    FutureProvider.family<List<Post>, String>((ref, entityId) async {
  final api = ref.read(apiClientProvider);
  return api.getEntityPosts(entityId);
});

class EntityScreen extends ConsumerWidget {
  final String entityId;

  const EntityScreen({super.key, required this.entityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entityAsync = ref.watch(entityDetailProvider(entityId));
    final postsAsync = ref.watch(entityPostsProvider(entityId));

    return Scaffold(
      body: entityAsync.when(
        loading: () => CustomScrollView(
          slivers: [
            const SliverAppBar(title: Text('加载中...')),
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
        error: (err, _) => CustomScrollView(
          slivers: [
            SliverAppBar(title: const Text('错误')),
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.error),
                    const SizedBox(height: 16),
                    const Text('加载失败'),
                    const SizedBox(height: 16),
                    FilledButton.tonal(
                      onPressed: () {
                        ref.invalidate(entityDetailProvider(entityId));
                        ref.invalidate(entityPostsProvider(entityId));
                      },
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        data: (entity) {
          final posts = postsAsync.valueOrNull ?? [];

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                title: Text(entity.name),
                pinned: true,
              ),
              SliverToBoxAdapter(
                child: _EntityInfoSection(entity: entity, ref: ref),
              ),
              if (postsAsync.isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (posts.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('暂无动态')),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        PostCard(post: posts[index], showEntityRow: false),
                    childCount: posts.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }
}

class _EntityInfoSection extends StatelessWidget {
  final Entity entity;
  final WidgetRef ref;

  const _EntityInfoSection({required this.entity, required this.ref});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subscribedIds = ref.watch(subscribedEntityIdsProvider);
    final isSubscribed = subscribedIds.contains(entity.id);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + name + tag
          Row(
            children: [
              _buildAvatar(entity.avatar, 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entity.name,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    if (entity.identityTag.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
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
            ],
          ),

          // Bio
          if (entity.bio.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(entity.bio,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
          ],

          // Activity tags
          if (entity.activityTags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: entity.activityTags
                  .map((tag) => Chip(
                        label: Text(tag, style: const TextStyle(fontSize: 12)),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          ],

          // Influence metrics
          if (entity.influence.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: entity.influence.entries
                  .take(4)
                  .map((e) => Expanded(
                        child: Column(
                          children: [
                            Text(e.value,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(e.key,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                )),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ],

          const SizedBox(height: 16),

          // Subscribe button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                final notifier =
                    ref.read(subscribedEntityIdsProvider.notifier);
                if (isSubscribed) {
                  notifier.state = subscribedIds
                      .where((id) => id != entity.id)
                      .toList();
                } else {
                  notifier.state = [...subscribedIds, entity.id];
                }
              },
              icon: Icon(isSubscribed ? Icons.check : Icons.add),
              label: Text(isSubscribed ? '已订阅' : '订阅更新'),
            ),
          ),

          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 4),
          Text('动态',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

Widget _buildAvatar(String url, double radius) {
  if (url.isEmpty) {
    return CircleAvatar(
      radius: radius,
      child: const Icon(Icons.person, size: 28),
    );
  }
  return CircleAvatar(
    radius: radius,
    backgroundImage: CachedNetworkImageProvider(url),
  );
}
