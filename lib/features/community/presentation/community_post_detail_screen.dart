import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/pulse_link_controller.dart';
import '../../../core/theme/pulse_link_theme.dart';
import '../domain/community_post.dart';

class CommunityPostDetailScreen extends StatefulWidget {
  const CommunityPostDetailScreen({
    super.key,
    required this.controller,
    required this.initialPost,
  });

  final PulseLinkController controller;
  final CommunityPost initialPost;

  @override
  State<CommunityPostDetailScreen> createState() =>
      _CommunityPostDetailScreenState();
}

class _CommunityPostDetailScreenState extends State<CommunityPostDetailScreen> {
  late Future<CommunityPost> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.controller.loadCommunityPost(widget.initialPost.slug);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết bài viết'),
      ),
      body: FutureBuilder<CommunityPost>(
        future: _future,
        initialData: widget.initialPost,
        builder: (context, snapshot) {
          final post = snapshot.data ?? widget.initialPost;
          final paragraphs = post.content
              .split(RegExp(r'\n+'))
              .where((line) => line.trim().isNotEmpty)
              .toList(growable: false);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 1.55,
                  child: Image.network(
                    post.imageUrl ??
                        'https://images.unsplash.com/photo-1530026405186-ed1f139313f8?auto=format&fit=crop&q=80&w=900',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.white10,
                      alignment: Alignment.center,
                      child: const Icon(Icons.article_outlined, size: 42),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                post.audienceLabel,
                style: const TextStyle(
                  color: PulseLinkTheme.primaryRed,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                post.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                post.publishedAt == null
                    ? 'Vừa cập nhật'
                    : 'Đăng ngày ${DateFormat('dd/MM/yyyy - HH:mm').format(post.publishedAt!)}',
                style: const TextStyle(color: PulseLinkTheme.mutedText),
              ),
              if (post.excerpt != null && post.excerpt!.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  post.excerpt!,
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              for (final paragraph in paragraphs) ...[
                Text(
                  paragraph,
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.55,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ],
          );
        },
      ),
    );
  }
}
