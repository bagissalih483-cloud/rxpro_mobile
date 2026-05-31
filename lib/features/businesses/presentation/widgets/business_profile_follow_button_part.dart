part of '../../business_profile_page.dart';

class _ProfileFollowButton extends StatefulWidget {
  const _ProfileFollowButton({
    required this.businessId,
    required this.businessName,
  });

  final String businessId;
  final String businessName;

  @override
  State<_ProfileFollowButton> createState() => _ProfileFollowButtonState();
}

class _ProfileFollowButtonState extends State<_ProfileFollowButton> {
  final AppCacheService cache = AppCacheService();
  final BusinessProfileFollowController _controller =
      BusinessProfileFollowController();
  final BusinessProfileRepository _followRepository =
      BusinessProfileRepository();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = _authService.currentUser;
    if (user == null) return;

    final cached = await cache.isBusinessFollowed(widget.businessId);
    if (mounted) {
      _controller.applyFollowing(cached);
    }

    final isFollowing = await _followRepository.isFollowingBusiness(
      businessId: widget.businessId,
      uid: user.uid,
    );
    await cache.setBusinessFollowed(
      businessId: widget.businessId,
      followed: isFollowing,
    );

    if (mounted) {
      _controller.applyFollowing(isFollowing);
    }
  }

  Future<void> _toggle() async {
    final user = _authService.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Takip için giriş yapın.')));
      return;
    }

    if (_controller.busy) return;

    final oldValue = _controller.following;
    final newValue = !oldValue;

    _controller.startToggle(newValue);

    await cache.setBusinessFollowed(
      businessId: widget.businessId,
      followed: newValue,
    );

    try {
      await _followRepository.setBusinessFollowing(
        businessId: widget.businessId,
        businessName: widget.businessName,
        uid: user.uid,
        followed: newValue,
      );
    } catch (_) {
      await cache.setBusinessFollowed(
        businessId: widget.businessId,
        followed: oldValue,
      );
      if (mounted) {
        _controller.applyFollowing(oldValue);
      }
    } finally {
      if (mounted) {
        _controller.setBusy(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => OutlinedButton.icon(
        onPressed: _controller.busy ? null : _toggle,
        icon: Icon(
          _controller.following ? Icons.favorite : Icons.favorite_border,
          color: _controller.following ? RxColors.red : null,
          size: 18,
        ),
        label: Text(_controller.following ? 'Takipte' : 'Takip'),
      ),
    );
  }
}
