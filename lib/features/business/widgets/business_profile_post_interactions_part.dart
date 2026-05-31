part of 'business_profile_post_interactive_card.dart';

extension _BusinessProfilePostInteractions on _BusinessProfilePostInteractiveCardState {
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

    if (!_controller.beginAction()) return;

    try {
      final result = await _interactionRepository.toggleLike(
        postId: widget.postId,
        uid: uid,
      );

      _snack(result.wasActive ? 'Beğeni kaldırıldı.' : 'Beğenildi.');
    } catch (e) {
      _snack('Beğeni işlemi yapılamadı: $e');
    } finally {
      if (mounted) _controller.finishAction();
    }
  }

  Future<void> _toggleSave() async {
    final uid = _sessionRepository.currentUid();

    if (uid == null) {
      _snack('Kaydetmek için giriş yapın.');
      return;
    }

    if (!_controller.beginAction()) return;

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
      if (mounted) _controller.finishAction();
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
    if (!_controller.beginAction()) return;

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
      if (mounted) _controller.finishAction();
    }
  }

  void _snack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
