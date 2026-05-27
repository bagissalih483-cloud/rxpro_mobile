import '../data/business_profile_post_interaction_repository.dart';
import '../data/business_profile_post_session_repository.dart';
import 'package:flutter/material.dart';

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
  bool busy = false;

  String get _uid => _sessionRepository.currentUid() ?? '';
  Stream<bool> _likeStream() {
    return _interactionRepository.watchLikeActive(
      postId: widget.postId,
      uid: _uid,
    );
  }

  Stream<bool> _saveStream() {
    return _interactionRepository.watchSaveActive(
      postId: widget.postId,
      uid: _uid,
    );
  }

  Future<void> _toggleLike() async {
    final uid = _sessionRepository.currentUid();

    if (uid == null) {
      _snack('Beğenmek için giriş yapın.');
      return;
    }

    if (busy) return;
    setState(() => busy = true);

    try {
      final result = await _interactionRepository.toggleLike(
        postId: widget.postId,
        uid: uid,
      );

      _snack(result.wasActive ? 'Beğeni kaldırıldı.' : 'Beğenildi.');
    } catch (e) {
      _snack('Beğeni işlemi yapılamadı: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _toggleSave() async {
    final uid = _sessionRepository.currentUid();

    if (uid == null) {
      _snack('Kaydetmek için giriş yapın.');
      return;
    }

    if (busy) return;
    setState(() => busy = true);

    try {
      final result = await _interactionRepository.toggleSave(
        postId: widget.postId,
        uid: uid,
      );

      _snack(
        result.wasActive ? 'Kaydetme kaldırıldı.' : 'Paylaşım kaydedildi.',
      );
    } catch (e) {
      _snack('Kaydetme işlemi yapılamadı: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _reportPost() async {
    final uid = _sessionRepository.currentUid();

    if (uid == null) {
      _snack('Raporlamak için giriş yapın.');
      return;
    }

    final approved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Paylaşımı raporla'),
          content: const Text(
            'Bu paylaşımı uygunsuz içerik olarak raporlamak istiyor musunuz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Raporla'),
            ),
          ],
        );
      },
    );

    if (approved != true) return;
    if (busy) return;

    setState(() => busy = true);

    try {
      final created = await _interactionRepository.reportPost(
        postId: widget.postId,
        uid: uid,
      );

      _snack(
        created ? 'Raporunuz alındı.' : 'Bu paylaşımı zaten raporladınız.',
      );
    } catch (e) {
      _snack('Raporlama yapılamadı: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

class _RoundIconCounter extends StatelessWidget {
  const _RoundIconCounter({
    required this.icon,
    required this.count,
    required this.active,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final int count;
  final bool active;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF18B7C9) : const Color(0xFF6B7280);
    final bg = active ? const Color(0xFFE0F7FA) : const Color(0xFFF9FAFB);
    final border = active ? const Color(0xFF18B7C9) : const Color(0xFFE5E7EB);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Text(
                  count.toString(),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
