part of '../../business_profile_page.dart';

class _BusinessProfilePostItem {
  const _BusinessProfilePostItem({
    required this.id,
    required this.text,
    required this.imageUrl,
    required this.mediaType,
    required this.createdAt,
    required this.likeCount,
    required this.saveCount,
    required this.reportCount,
  });

  final String id;
  final String text;
  final String imageUrl;
  final String mediaType;
  final String createdAt;
  final int likeCount;
  final int saveCount;
  final int reportCount;
}

// ignore: unused_element
class _BusinessProfilePostCard extends StatelessWidget {
  const _BusinessProfilePostCard({required this.post});

  final _BusinessProfilePostItem post;

  @override
  Widget build(BuildContext context) {
    final hasImage = post.imageUrl.trim().isNotEmpty;
    final hasText = post.text.trim().isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                post.imageUrl,
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
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasText)
                  Text(post.text, style: RxText.body)
                else
                  const Text('Fotoğraf paylaşımı', style: RxText.body),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 15,
                      color: RxColors.muted,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        _formatDate(post.createdAt),
                        style: const TextStyle(
                          color: RxColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.favorite_border_rounded,
                      size: 17,
                      color: RxColors.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.likeCount}',
                      style: const TextStyle(
                        color: RxColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
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

int _postInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();

  return int.tryParse(value?.toString() ?? '') ?? 0;
}
