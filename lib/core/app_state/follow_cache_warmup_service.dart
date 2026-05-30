import '../app_cache/app_cache_service.dart';
import 'data/follow_cache_warmup_repository.dart';

class FollowCacheWarmupService {
  FollowCacheWarmupService({
    FollowCacheWarmupRepository? repository,
    AppCacheService? cache,
  }) : _repository = repository ?? FollowCacheWarmupRepository(),
       _cache = cache ?? AppCacheService();

  final FollowCacheWarmupRepository _repository;
  final AppCacheService _cache;

  Future<void> syncCurrentUserFollows() async {
    final uid = _repository.currentUid;

    if (uid == null) {
      await _cache.saveFollowedBusinessIds(const []);
      return;
    }

    final ids = await _repository.loadFollowedBusinessIds(uid);
    await _cache.saveFollowedBusinessIds(ids);
  }
}
