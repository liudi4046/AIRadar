enum EntityType { person, org, opensource, media }

class Entity {
  final String id;
  final String name;
  final String avatar;
  final String identityTag;
  final EntityType type;
  final String bio;
  final List<String> activityTags;
  final Map<String, String> influence;
  final List<String> recentHighlights;
  final String category;

  Entity({
    required this.id,
    required this.name,
    this.avatar = '',
    this.identityTag = '',
    required this.type,
    this.bio = '',
    this.activityTags = const [],
    this.influence = const {},
    this.recentHighlights = const [],
    this.category = 'core_leaders',
  });

  factory Entity.fromJson(Map<String, dynamic> json) {
    return Entity(
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String? ?? '',
      identityTag: json['identity_tag'] as String? ?? '',
      type: EntityType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EntityType.person,
      ),
      bio: json['bio'] as String? ?? '',
      activityTags: (json['activity_tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      influence: (json['influence'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v.toString())) ??
          {},
      recentHighlights: (json['recent_highlights'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      category: json['category'] as String? ?? 'core_leaders',
    );
  }
}
