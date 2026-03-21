import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/entity.dart';
import '../providers.dart';

void showEntityDetailSheet(BuildContext context, Entity entity) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) => _EntityDetailContent(
        entity: entity,
        scrollController: scrollController,
      ),
    ),
  );
}

class _EntityDetailContent extends ConsumerWidget {
  final Entity entity;
  final ScrollController scrollController;

  const _EntityDetailContent({
    required this.entity,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subscribedIds = ref.watch(subscribedEntityIdsProvider);
    final isSubscribed = subscribedIds.contains(entity.id);

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Avatar + Name + Tag
        Row(
          children: [
            _buildAvatar(entity.avatar, 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entity.name,
                      style: theme.textTheme.titleLarge
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
          Text(
            entity.bio,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],

        // Activity tags
        if (entity.activityTags.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: entity.activityTags
                .map((tag) => Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 12)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

        // Recent highlights
        if (entity.recentHighlights.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('近期亮点',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...entity.recentHighlights.take(2).map(
                (h) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('•  ',
                          style: TextStyle(
                              color: theme.colorScheme.primary, fontSize: 14)),
                      Expanded(
                        child: Text(h,
                            style:
                                theme.textTheme.bodySmall?.copyWith(height: 1.4)),
                      ),
                    ],
                  ),
                ),
              ),
        ],

        const SizedBox(height: 24),

        // Action buttons
        Row(
          children: [
            Expanded(
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
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/entity/${entity.id}');
                },
                child: const Text('查看全部动态 →'),
              ),
            ),
          ],
        ),
      ],
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
