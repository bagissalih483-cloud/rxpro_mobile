import 'package:flutter/material.dart';
import 'package:rxpro_mobile/app/app_route_catalog.dart';

import 'business_story_model.dart';
import 'business_story_service.dart';

class BusinessStoryRail extends StatefulWidget {
  const BusinessStoryRail({super.key, this.compact = false});

  final bool compact;

  @override
  State<BusinessStoryRail> createState() => _BusinessStoryRailState();
}

class _BusinessStoryRailState extends State<BusinessStoryRail>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<List<BusinessStoryModel>>(
      stream: BusinessStoryService.watchActiveStories(),
      builder: (context, snapshot) {
        final rawStories = snapshot.data ?? const <BusinessStoryModel>[];

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _StoryRailSkeleton(compact: widget.compact);
        }

        if (rawStories.isEmpty) {
          return const SizedBox.shrink();
        }

        return FutureBuilder<List<BusinessStoryModel>>(
          future: BusinessStoryService.prioritizeForCurrentUser(rawStories),
          builder: (context, prioritizedSnapshot) {
            final stories = prioritizedSnapshot.data ?? rawStories;

            if (stories.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 2, right: 2, bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Hikayeler',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF123447),
                          ),
                        ),
                      ),
                      Text(
                        'Takip ve yakin cevre',
                        style: TextStyle(
                          fontSize: 11.2,
                          color: Color(0xFF77858D),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: widget.compact ? 82 : 94,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: stories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final story = stories[index];

                      return _StoryBubble(
                        story: story,
                        compact: widget.compact,
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.storyViewer,
                            arguments: BusinessStoryViewerRouteArgs(
                              stories: stories,
                              initialIndex: index,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _StoryRailSkeleton extends StatelessWidget {
  const _StoryRailSkeleton({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 112 : 124,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 82,
            height: 12,
            margin: const EdgeInsets.only(left: 2, bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          SizedBox(
            height: compact ? 82 : 94,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: compact ? 66 : 74,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: compact ? 25 : 29,
                        backgroundColor: const Color(0xFFE2E8F0),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 44,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryBubble extends StatelessWidget {
  const _StoryBubble({
    required this.story,
    required this.compact,
    required this.onTap,
  });

  final BusinessStoryModel story;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = compact ? 23.0 : 27.0;
    final previewUrl = _firstNonEmpty([
      story.thumbnailUrl,
      story.businessLogoUrl,
      story.mediaUrl,
    ]);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: SizedBox(
        width: compact ? 66 : 74,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF70C8F3), Color(0xFF5AD29D)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5AD29D).withValues(alpha: 0.24),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: radius,
                backgroundColor: Colors.white,
                backgroundImage: previewUrl.isEmpty
                    ? null
                    : NetworkImage(previewUrl),
                child: previewUrl.isEmpty
                    ? Text(
                        _initials(story.businessName),
                        style: const TextStyle(
                          color: Color(0xFF1F4E68),
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              story.businessName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10.5,
                color: Color(0xFF55666F),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'RX';

    final parts = clean
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _firstNonEmpty(Iterable<String> values) {
    for (final value in values) {
      final clean = value.trim();
      if (clean.isNotEmpty) return clean;
    }

    return '';
  }
}
