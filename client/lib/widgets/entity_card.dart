import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/entity.dart';
import '../providers.dart';

class EntityCard extends ConsumerWidget {
  final Entity entity;
  final VoidCallback? onTap;

  const EntityCard({super.key, required this.entity, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subscribedIds = ref.watch(subscribedEntityIdsProvider);
    final isSubscribed = subscribedIds.contains(entity.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildAvatar(entity.avatar, 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            entity.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (entity.identityTag.isNotEmpty) ...[
                          const SizedBox(width: 6),
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
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (entity.bio.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        entity.bio,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _SubscribeButton(
                isSubscribed: isSubscribed,
                onToggle: () {
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubscribeButton extends StatelessWidget {
  final bool isSubscribed;
  final VoidCallback onToggle;

  const _SubscribeButton({
    required this.isSubscribed,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isSubscribed) {
      return TextButton(
        onPressed: onToggle,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          visualDensity: VisualDensity.compact,
        ),
        child: Text(
          '已订阅 ✓',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      );
    }

    return FilledButton.tonal(
      onPressed: onToggle,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        visualDensity: VisualDensity.compact,
      ),
      child: const Text('+ 订阅更新', style: TextStyle(fontSize: 12)),
    );
  }
}

Widget _buildAvatar(String url, double radius) {
  if (url.isEmpty) {
    return CircleAvatar(
      radius: radius,
      child: const Icon(Icons.person, size: 20),
    );
  }
  return CircleAvatar(
    radius: radius,
    backgroundImage: CachedNetworkImageProvider(url),
  );
}
