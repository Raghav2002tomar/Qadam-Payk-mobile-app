import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'story_main_view.dart';

const String STORY_MEDIA_BASE = "https://qadampayk.com/assets/story_media/";
const String PROFILE_MEDIA_BASE = "https://qadampayk.com/assets/profile_image/";

class StoryFullView extends StatefulWidget {
  final Story story;
  final VoidCallback onCompleted;
  final VoidCallback onPrevious;

  const StoryFullView({
    super.key,
    required this.story,
    required this.onCompleted,
    required this.onPrevious,
  });

  @override
  State<StoryFullView> createState() => _StoryFullViewState();
}

class _StoryFullViewState extends State<StoryFullView> {
  VideoPlayerController? _videoCtl;
  Timer? _imageTimer;
  bool _isError = false;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    final mediaUrl = STORY_MEDIA_BASE + widget.story.media;

    if (widget.story.type == 'video' && _isVideoFile(widget.story.media)) {
      _initVideo(mediaUrl); // Play real video
    } else {
      // Show image/thumbnail for 5 seconds
      _imageTimer = Timer(const Duration(seconds: 5), widget.onCompleted);
    }
  }

  /// Check if file is actual video
  bool _isVideoFile(String media) {
    return media.toLowerCase().endsWith('.mp4') ||
        media.toLowerCase().endsWith('.mov') ||
        media.toLowerCase().endsWith('.webm');
  }

  Future<void> _initVideo(String url) async {
    try {
      _videoCtl = VideoPlayerController.network(url);
      await _videoCtl!.initialize();
      _videoCtl!
        ..setLooping(false)
        ..play();
      _videoCtl!.addListener(_videoListener);

      if (mounted) setState(() {
        _isVideoInitialized = true;
      });
    } catch (e) {
      print("Video init error: $e");
      if (mounted) setState(() {
        _isError = true;
      });
    }
  }

  void _videoListener() {
    if (_videoCtl == null) return;
    final value = _videoCtl!.value;
    if (value.position >= value.duration && value.duration.inMilliseconds > 0) {
      widget.onCompleted();
    }
  }

  @override
  void dispose() {
    _videoCtl?.removeListener(_videoListener);
    _videoCtl?.dispose();
    _imageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.story;
    final mediaUrl = STORY_MEDIA_BASE + s.media;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        final width = MediaQuery.of(context).size.width;
        if (details.localPosition.dx < width / 3) {
          widget.onPrevious();
        } else {
          widget.onCompleted();
        }
      },
      child: Stack(
        children: [
          Center(
            child: _isError
                ? const Text(
              'Cannot play media',
              style: TextStyle(color: Colors.white),
            )
                : (_isVideoFile(s.media) && _isVideoInitialized)
                ? AspectRatio(
              aspectRatio: _videoCtl!.value.aspectRatio,
              child: VideoPlayer(_videoCtl!),
            )
                : Stack(
              children: [
                Image.network(
                  mediaUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                if (s.type == 'video')
                  const Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
              ],
            ),
          ),
          // Bottom text
          // Viewers count
// Viewers count
          if (s.isMine)
          Positioned(
            left: 8,
            bottom: 80,
            child: GestureDetector(
              onTap: () {
                if (widget.story.viewers.isNotEmpty) {
                  _pauseStory();
                  _showViewersList(widget.story.viewers);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.remove_red_eye, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.story.viewers.length} views',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${s.description} • ${_timeAgo(s.createdAt)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  void _pauseStory() {
    _videoCtl?.pause();
    _imageTimer?.cancel();
  }

  void _resumeStory() {
    if (_isVideoFile(widget.story.media) && _isVideoInitialized) {
      _videoCtl?.play();
    } else {
      _imageTimer = Timer(const Duration(seconds: 5), widget.onCompleted);
    }
  }
  void _showViewersList(List viewers) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      isScrollControlled: true, // full height
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            children: [
              // Top bar handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white54,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Viewed by',
                style: TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: viewers.length,
                  separatorBuilder: (_, __) => const Divider(color: Colors.white24),
                  itemBuilder: (_, index) {
                    final v = viewers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: v['image'] != null && v['image'].toString().isNotEmpty
                            ? NetworkImage(PROFILE_MEDIA_BASE + v['image'])
                            : null,
                        backgroundColor: Colors.grey,
                        child: v['image'] == null ? const Icon(Icons.person, color: Colors.white) : null,
                      ),
                      title: Text(
                        v['name'] ?? 'Unknown',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      // Resume story when bottom sheet closes
      _resumeStory();
    });
  }

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
