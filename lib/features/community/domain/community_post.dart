import '../../daily/domain/donation_event.dart';

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.slug,
    required this.title,
    required this.content,
    required this.audienceLabel,
    required this.viewsCount,
    required this.sharesCount,
    this.excerpt,
    this.imageUrl,
    this.publishedAt,
    this.province,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      excerpt: json['excerpt'] as String?,
      content: json['content'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      publishedAt: json['published_at'] == null
          ? null
          : DateTime.parse(json['published_at'] as String),
      audienceLabel: json['audience_label'] as String? ?? 'Tất cả người dùng',
      province: json['province'] is Map<String, dynamic>
          ? AdministrativeArea.fromJson(json['province'] as Map<String, dynamic>)
          : null,
      viewsCount: json['views_count'] as int? ?? 0,
      sharesCount: json['shares_count'] as int? ?? 0,
    );
  }

  final String id;
  final String slug;
  final String title;
  final String? excerpt;
  final String content;
  final String? imageUrl;
  final DateTime? publishedAt;
  final String audienceLabel;
  final AdministrativeArea? province;
  final int viewsCount;
  final int sharesCount;
}
