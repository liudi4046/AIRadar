import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/post.dart';
import '../providers.dart';
import '../widgets/post_card.dart';
import '../widgets/trending_card.dart';

final timelineProvider = FutureProvider<List<Post>>((ref) async {
  final api = ref.read(apiClientProvider);
  final entityIds = ref.watch(subscribedEntityIdsProvider);
  if (entityIds.isEmpty) return [];
  return api.getTimeline(entityIds);
});

final trendingProvider = FutureProvider<List<Post>>((ref) async {
  final api = ref.read(apiClientProvider);
  return api.getTrending();
});

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(timelineProvider);
    final trendingAsync = ref.watch(trendingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 追更'),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(timelineProvider);
          ref.invalidate(trendingProvider);
          await Future.wait([
            ref.read(timelineProvider.future),
            ref.read(trendingProvider.future),
          ]);
        },
        child: timelineAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => _ErrorBody(
            message: '加载失败，请下拉刷新重试',
            onRetry: () {
              ref.invalidate(timelineProvider);
              ref.invalidate(trendingProvider);
            },
          ),
          data: (posts) {
            final trending = trendingAsync.valueOrNull ?? [];

            if (posts.isEmpty && trending.isEmpty) {
              return _EmptyBody();
            }

            final items = _interleave(posts, trending);

            return ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 32),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                if (item.isTrendingSlot) {
                  return TrendingCard(post: item.post);
                }
                return PostCard(post: item.post);
              },
            );
          },
        ),
      ),
    );
  }
}

class _TimelineItem {
  final Post post;
  final bool isTrendingSlot;

  const _TimelineItem(this.post, {this.isTrendingSlot = false});
}

List<_TimelineItem> _interleave(List<Post> posts, List<Post> trending) {
  final result = <_TimelineItem>[];
  int trendIdx = 0;

  for (int i = 0; i < posts.length; i++) {
    result.add(_TimelineItem(posts[i]));
    if ((i + 1) % 5 == 0 && trendIdx < trending.length) {
      result.add(_TimelineItem(trending[trendIdx], isTrendingSlot: true));
      trendIdx++;
    }
  }

  while (trendIdx < trending.length) {
    result.add(_TimelineItem(trending[trendIdx], isTrendingSlot: true));
    trendIdx++;
  }

  return result;
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Center(
          child: Column(
            children: [
              Icon(Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(message, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: onRetry,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      children: [
        const SizedBox(height: 120),
        Center(
          child: Column(
            children: [
              Icon(Icons.check_circle_outline,
                  size: 56, color: theme.colorScheme.primary.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text('你已看完所有最新动态 ✓',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => context.go('/discover'),
                child: Text(
                  '去发现更多值得关注的 AI 大牛 →',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
