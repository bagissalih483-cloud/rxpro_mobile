import 'package:flutter/material.dart';

import '../businesses/business_profile_page.dart';
import 'business_story_model.dart';
import 'business_story_service.dart';

class BusinessStoryViewerPage extends StatefulWidget {
  const BusinessStoryViewerPage({
    super.key,
    required this.stories,
    required this.initialIndex,
  });

  final List<BusinessStoryModel> stories;
  final int initialIndex;

  @override
  State<BusinessStoryViewerPage> createState() =>
      _BusinessStoryViewerPageState();
}

class _BusinessStoryViewerPageState extends State<BusinessStoryViewerPage> {
  late PageController controller;
  late int index;

  @override
  void initState() {
    super.initState();
    index = widget.initialIndex.clamp(0, widget.stories.length - 1);
    controller = PageController(initialPage: index);
    _markCurrentViewed();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _markCurrentViewed() {
    if (widget.stories.isEmpty) return;
    BusinessStoryService.markViewed(widget.stories[index].id);
  }

  void _openBusiness(BusinessStoryModel story) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BusinessProfilePage(
          businessId: story.businessId,
          businessName: story.businessName,
          category: story.category,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stories.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Hikâye bulunamadı',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: PageView.builder(
          controller: controller,
          itemCount: widget.stories.length,
          onPageChanged: (value) {
            setState(() => index = value);
            _markCurrentViewed();
          },
          itemBuilder: (context, i) {
            final story = widget.stories[i];

            return Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    child: Image.network(
                      story.mediaUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) {
                        return const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white70,
                            size: 52,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  top: 12,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        backgroundImage: story.businessLogoUrl.trim().isEmpty
                            ? null
                            : NetworkImage(story.businessLogoUrl),
                        child: story.businessLogoUrl.trim().isEmpty
                            ? Text(
                                story.businessName.trim().isEmpty
                                    ? 'R'
                                    : story.businessName
                                          .trim()[0]
                                          .toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF17384A),
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          story.businessName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                if (story.caption.trim().isNotEmpty)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 86,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.42),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        story.caption,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 22,
                  child: FilledButton.icon(
                    onPressed: () => _openBusiness(story),
                    icon: const Icon(Icons.storefront_rounded),
                    label: const Text('Kurumsal Profili Gör'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
