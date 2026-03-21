class PostEntity {
  final String id;
  final String name;
  final String avatar;
  final String identityTag;

  PostEntity({
    required this.id,
    required this.name,
    this.avatar = '',
    this.identityTag = '',
  });

  factory PostEntity.fromJson(Map<String, dynamic> json) {
    return PostEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String? ?? '',
      identityTag: json['identity_tag'] as String? ?? '',
    );
  }
}

class Post {
  final String id;
  final String entityId;
  final String sourceType;
  final String sourceUrl;
  final String originalText;
  final String summaryZh;
  final String insightZh;
  final String interpretationZh;
  final String publishedAt;
  final bool isTrending;
  final String trendingSource;
  final PostEntity? entity;

  Post({
    required this.id,
    required this.entityId,
    this.sourceType = '',
    this.sourceUrl = '',
    this.originalText = '',
    this.summaryZh = '',
    this.insightZh = '',
    this.interpretationZh = '',
    this.publishedAt = '',
    this.isTrending = false,
    this.trendingSource = '',
    this.entity,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      entityId: json['entity_id'] as String,
      sourceType: json['source_type'] as String? ?? '',
      sourceUrl: json['source_url'] as String? ?? '',
      originalText: json['original_text'] as String? ?? '',
      summaryZh: json['summary_zh'] as String? ?? '',
      insightZh: json['insight_zh'] as String? ?? '',
      interpretationZh: json['interpretation_zh'] as String? ?? '',
      publishedAt: json['published_at'] as String? ?? '',
      isTrending: json['is_trending'] as bool? ?? false,
      trendingSource: json['trending_source'] as String? ?? '',
      entity: json['entities'] != null
          ? PostEntity.fromJson(json['entities'] as Map<String, dynamic>)
          : null,
    );
  }
}
