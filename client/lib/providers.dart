import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final subscribedEntityIdsProvider = StateProvider<List<String>>((ref) {
  return [
    'sam-altman', 'andrej-karpathy', 'openai', 'anthropic', 'huggingface',
  ];
});

final trendingRecommendationProvider = StateProvider<bool>((ref) => true);
