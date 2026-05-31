import '../data/business_profile_post_interaction_repository.dart';
import '../data/business_profile_post_session_repository.dart';
import '../presentation/business_profile_post_interaction_controller.dart';
import 'package:flutter/material.dart';

part 'business_profile_post_interactions_part.dart';
part 'business_profile_post_counter_part.dart';
class BusinessProfilePostInteractiveCard extends StatefulWidget {
  const BusinessProfilePostInteractiveCard({
    super.key,
    required this.postId,
    required this.text,
    required this.imageUrl,
    required this.createdAt,
    required this.likeCount,
    required this.saveCount,
    required this.reportCount,
  });

  final String postId;
  final String text;
  final String imageUrl;
  final String createdAt;
  final int likeCount;
  final int saveCount;
  final int reportCount;

  @override
  State<BusinessProfilePostInteractiveCard> createState() =>
      _BusinessProfilePostInteractiveCardState();
}

class _BusinessProfilePostInteractiveCardState
    extends State<BusinessProfilePostInteractiveCard> {
  final BusinessProfilePostInteractionRepository _interactionRepository =
      BusinessProfilePostInteractionRepository();
  final BusinessProfilePostSessionRepository _sessionRepository =
      BusinessProfilePostSessionRepository();
  final BusinessProfilePostInteractionController _controller =
      BusinessProfilePostInteractionController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.imageUrl.trim().isNotEmpty;
    final hasText = widget.text.trim().isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                widget.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFFF3F4F6),
                    child: const Center(
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasText ? widget.text : 'Fotoğraf paylaşımı',
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        _formatDate(widget.createdAt),
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    StreamBuilder<bool>(
                      stream: _likeStream(),
                      builder: (context, snapshot) {
                        final liked = snapshot.data == true;

                        return _RoundIconCounter(
                          icon: liked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          count: widget.likeCount,
                          active: liked,
                          tooltip: 'Beğen',
                          onTap: _toggleLike,
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    StreamBuilder<bool>(
                      stream: _saveStream(),
                      builder: (context, snapshot) {
                        final saved = snapshot.data == true;

                        return _RoundIconCounter(
                          icon: saved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          count: widget.saveCount,
                          active: saved,
                          tooltip: 'Kaydet',
                          onTap: _toggleSave,
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: _reportPost,
                      tooltip: 'Raporla',
                      icon: const Icon(
                        Icons.flag_outlined,
                        size: 21,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(String raw) {
    if (raw.trim().isEmpty) return 'Tarih yok';

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;

    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');

    return '$day.$month.${parsed.year}';
  }
}
