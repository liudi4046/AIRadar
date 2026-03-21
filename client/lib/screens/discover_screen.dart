import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/entity.dart';
import '../providers.dart';
import '../widgets/entity_card.dart';
import '../widgets/entity_detail_sheet.dart';

const categoryLabels = {
  'core_leaders': '🧠 核心领袖',
  'top_brands': '🏢 顶级厂牌',
  'opensource_geeks': '🛠️ 开源与极客',
  'industry_intel': '📰 行业内参',
};

final discoverEntitiesProvider = FutureProvider<List<Entity>>((ref) async {
  final api = ref.read(apiClientProvider);
  return api.getEntities();
});

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitiesAsync = ref.watch(discoverEntitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('发现'),
        centerTitle: false,
      ),
      body: entitiesAsync.when(
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
                onPressed: () => ref.invalidate(discoverEntitiesProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (entities) {
          final grouped = <String, List<Entity>>{};
          for (final entity in entities) {
            grouped.putIfAbsent(entity.category, () => []).add(entity);
          }

          final categoryOrder = categoryLabels.keys.toList();
          final sortedCategories = grouped.keys.toList()
            ..sort((a, b) {
              final ai = categoryOrder.indexOf(a);
              final bi = categoryOrder.indexOf(b);
              return (ai == -1 ? 999 : ai).compareTo(bi == -1 ? 999 : bi);
            });

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            itemCount: sortedCategories.length,
            itemBuilder: (context, index) {
              final cat = sortedCategories[index];
              final catEntities = grouped[cat]!;
              final label =
                  categoryLabels[cat] ?? cat;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  ...catEntities.map(
                    (entity) => EntityCard(
                      entity: entity,
                      onTap: () => showEntityDetailSheet(context, entity),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
