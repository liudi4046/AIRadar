import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers.dart';

final trendingRecommendationProvider = StateProvider<bool>((ref) => true);

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subscribedIds = ref.watch(subscribedEntityIdsProvider);
    final trendingEnabled = ref.watch(trendingRecommendationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          // Subscription management section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              '订阅管理',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (subscribedIds.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurface.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  Text(
                    '你还没有订阅任何实体，去发现页看看吧',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () => context.go('/discover'),
                    child: const Text('去发现'),
                  ),
                ],
              ),
            )
          else
            ...subscribedIds.map(
              (id) => ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20),
                title: Text(id),
                trailing: TextButton(
                  onPressed: () {
                    ref.read(subscribedEntityIdsProvider.notifier).state =
                        subscribedIds.where((eid) => eid != id).toList();
                  },
                  child: Text(
                    '取消订阅',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),

          const Divider(height: 32),

          // Settings section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              '设置',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            title: const Text('热点推荐'),
            subtitle: const Text('在动态中穿插 AI 热点内容'),
            value: trendingEnabled,
            onChanged: (val) {
              ref.read(trendingRecommendationProvider.notifier).state = val;
            },
          ),

          const Divider(height: 32),

          // Footer
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'AI 追更 v0.1.0',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
