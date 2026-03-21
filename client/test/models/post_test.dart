import 'package:flutter_test/flutter_test.dart';
import 'package:ai_radar/models/post.dart';

void main() {
  test('Post.fromJson parses correctly', () {
    final json = {
      'id': 'post-001',
      'entity_id': 'karpathy',
      'source_type': 'twitter',
      'source_url': 'https://x.com/karpathy/1',
      'original_text': 'LLMs are amazing',
      'summary_zh': '测试摘要',
      'insight_zh': '测试洞察',
      'interpretation_zh': '测试解读',
      'published_at': '2026-03-20T10:00:00Z',
      'is_trending': false,
      'entities': {
        'id': 'karpathy',
        'name': 'Andrej Karpathy',
        'avatar': '',
        'identity_tag': '前特斯拉AI总监',
      },
    };

    final post = Post.fromJson(json);
    expect(post.id, 'post-001');
    expect(post.entityId, 'karpathy');
    expect(post.summaryZh, '测试摘要');
    expect(post.entity?.name, 'Andrej Karpathy');
  });
}
