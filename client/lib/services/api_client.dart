import 'package:dio/dio.dart';
import '../models/entity.dart';
import '../models/post.dart';
import 'api_config.dart';

class ApiClient {
  final Dio _dio;

  ApiClient({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

  Future<List<Entity>> getEntities({String? category}) async {
    final params = <String, dynamic>{};
    if (category != null) params['category'] = category;
    final resp = await _dio.get('/api/entities', queryParameters: params);
    return (resp.data as List).map((e) => Entity.fromJson(e)).toList();
  }

  Future<Entity> getEntity(String entityId) async {
    final resp = await _dio.get('/api/entities/$entityId');
    return Entity.fromJson(resp.data);
  }

  Future<List<Post>> getTimeline(List<String> entityIds,
      {int page = 0}) async {
    final resp = await _dio.get('/api/posts/timeline', queryParameters: {
      'entity_ids': entityIds.join(','),
      'page': page,
    });
    return (resp.data as List).map((e) => Post.fromJson(e)).toList();
  }

  Future<List<Post>> getTrending({int page = 0}) async {
    final resp = await _dio.get('/api/posts/trending',
        queryParameters: {'page': page});
    return (resp.data as List).map((e) => Post.fromJson(e)).toList();
  }

  Future<List<Post>> getEntityPosts(String entityId, {int page = 0}) async {
    final resp = await _dio.get('/api/posts/entity/$entityId',
        queryParameters: {'page': page});
    return (resp.data as List).map((e) => Post.fromJson(e)).toList();
  }

  Future<Post> getPostDetail(String postId) async {
    final resp = await _dio.get('/api/posts/$postId');
    return Post.fromJson(resp.data);
  }
}
