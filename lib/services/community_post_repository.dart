import '../features/community/domain/community_post.dart';

abstract interface class CommunityPostRepository {
  Future<List<CommunityPost>> getPublishedPosts();

  Future<CommunityPost> getPostDetail(String slug);
}
