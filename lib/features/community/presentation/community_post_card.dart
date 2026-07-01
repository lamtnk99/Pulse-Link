import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/pulse_link_theme.dart';
import '../domain/community_post.dart';

class CommunityPostCard extends StatelessWidget {
  const CommunityPostCard({
    super.key,
    required this.post,
    required this.onTap,
  });

  final CommunityPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: PulseLinkTheme.cardBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Row(
              children: [
                SizedBox(
                  width: 104,
                  height: 120,
                  child: Image.network(
                    post.imageUrl ??
                        'https://images.unsplash.com/photo-1530026405186-ed1f139313f8?auto=format&fit=crop&q=80&w=900',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        color: Colors.white10,
                        alignment: Alignment.center,
                        child: const Icon(Icons.article_outlined),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.audienceLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: PulseLinkTheme.primaryRed,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          post.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          post.excerpt ?? 'Cập nhật từ cộng đồng Pulse Link.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: PulseLinkTheme.mutedText,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          post.publishedAt == null
                              ? 'Vừa cập nhật'
                              : DateFormat('dd/MM/yyyy').format(post.publishedAt!),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
