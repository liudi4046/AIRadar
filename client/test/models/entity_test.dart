import 'package:flutter_test/flutter_test.dart';
import 'package:ai_radar/models/entity.dart';

void main() {
  test('Entity.fromJson parses correctly', () {
    final json = {
      'id': 'karpathy',
      'name': 'Andrej Karpathy',
      'avatar': 'https://example.com/avatar.jpg',
      'identity_tag': '前特斯拉AI总监',
      'type': 'person',
      'bio': '计算机视觉传奇人物',
      'activity_tags': ['🔥 高频更新'],
      'influence': {'twitter_followers': '1.2M'},
      'recent_highlights': ['发布新视频'],
      'category': 'core_leaders',
    };

    final entity = Entity.fromJson(json);
    expect(entity.id, 'karpathy');
    expect(entity.name, 'Andrej Karpathy');
    expect(entity.type, EntityType.person);
    expect(entity.activityTags.length, 1);
  });
}
