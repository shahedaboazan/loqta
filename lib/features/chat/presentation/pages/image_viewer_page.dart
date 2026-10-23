import 'package:flutter/material.dart';

import 'package:loqta/core/theme/app_theme.dart';

/// Screen 15 — Image Viewer.
///
/// A full-screen, pinch-to-zoom view of the chat attachments. When the
/// conversation has more than one attachment the viewer swipes between them and
/// shows the "2 / 3" counter and page dots from the reference.
///
/// Pushed from the Chat screen, so Back always returns to that same
/// conversation: nothing here creates or switches conversation, and there is no
/// path to the Chat List.
class ImageViewerPage extends StatefulWidget {
  const ImageViewerPage({
    super.key,
    required this.imageUrl,
    required this.position,
    this.itemCount = 1,
    this.imageUrls = const [],
  });

  /// A signed URL from Supabase Storage; the bucket is private.
  final String imageUrl;

  /// 1-based position within the conversation's attachments.
  final int position;

  final int itemCount;

  /// Every resolvable attachment in the conversation, so the viewer can swipe
  /// between them. Empty falls back to showing [imageUrl] on its own.
  final List<String> imageUrls;

  @override
  State<ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  late final PageController _pageController;
  late final List<String> _urls;

  int _index = 0;

  /// Page indexes whose image failed to load, kept per page so one broken
  /// attachment does not blank the whole viewer.
  final Set<int> _failed = <int>{};

  @override
  void initState() {
    super.initState();
    _urls = widget.imageUrls.isEmpty ? [widget.imageUrl] : widget.imageUrls;
    _index = (widget.position - 1).clamp(0, _urls.length - 1);
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Clears one page's failure so it is requested again.
  void _retry(int index) => setState(() => _failed.remove(index));

  @override
  Widget build(BuildContext context) {
    final count = _urls.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1220),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Image Viewer',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontFamily: LoqtaText.family,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Center(
            child: PageView.builder(
              controller: _pageController,
              itemCount: count,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: (context, index) {
                if (_failed.contains(index)) {
                  return _FailureState(onRetry: () => _retry(index));
                }

                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Image.network(
                    _urls[index],
                    fit: BoxFit.contain,
                    // The spinner is the loading state; there is no separate
                    // flag to keep in sync with it.
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                        ? child
                        : const SizedBox(
                            height: 26,
                            width: 26,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                    errorBuilder: (_, _, _) {
                      // Recorded on the next frame so the builder itself stays a
                      // pure build-time function.
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _failed.add(index));
                      });
                      return const SizedBox.shrink();
                    },
                  ),
                );
              },
            ),
          ),
          // The "1 / 3" counter from the reference.
          if (count > 1)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_index + 1} / $count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: LoqtaText.family,
                    ),
                  ),
                ),
              ),
            ),
          // The page dots, only when there is more than one attachment.
          if (count > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < count; i++)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _index
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                ],
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: IgnorePointer(
              child: Text(
                count > 1
                    ? 'Swipe or tap arrows to inspect fabric quality'
                    : 'Pinch to zoom in on fabric quality',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontFamily: LoqtaText.family,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FailureState extends StatelessWidget {
  const _FailureState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.broken_image_outlined,
          size: 44,
          color: Colors.white54,
        ),
        const SizedBox(height: 12),
        const Text(
          'This image could not be loaded.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontFamily: LoqtaText.family,
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton(
          onPressed: onRetry,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white38),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Try again',
            style: TextStyle(color: Colors.white, fontFamily: LoqtaText.family),
          ),
        ),
      ],
    );
  }
}
