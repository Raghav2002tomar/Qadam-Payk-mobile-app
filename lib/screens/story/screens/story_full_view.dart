import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../api_service/app_constocter.dart';
import '../../../api_service/logger.dart';
import '../../../providers/translate_provider.dart';
import '../../../service/local_cache.dart';
import '../controller/StoryVideoCache.dart';
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

class _StoryFullViewState extends State<StoryFullView>with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoCtl;
  Timer? _imageTimer;
  bool _isError = false;
  bool _isVideoInitialized = false;
  bool _disposed = false;
  // final Map<int, VideoPlayerController> _videoControllerCache = {};
  late AnimationController _loadingController;
  late Animation<double> _loadingAnimation;

  @override
  void initState() {
    super.initState();

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _loadingAnimation = Tween<double>(
      begin: -1.0, // start off-screen left
      end: 1.0,    // move to off-screen right
    ).animate(
      CurvedAnimation(
        parent: _loadingController,
        curve: Curves.linear, // smooth constant speed
      ),
    );


    final mediaUrl = STORY_MEDIA_BASE + widget.story.media;

    if (widget.story.type == 'video' && _isVideoFile(widget.story.media)) {
      _initVideo(mediaUrl);
    } else {
      _imageTimer = Timer(const Duration(seconds: 5), widget.onCompleted);
    }
  }


  /// Check if file is actual video
  bool _isVideoFile(String media) {
    return media.toLowerCase().endsWith('.mp4') ||
        media.toLowerCase().endsWith('.mov') ||
        media.toLowerCase().endsWith('.webm');
  }


  Future<File> downloadVideo(String url, String fileName) async {
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/$fileName';

    final file = File(filePath);
    if (await file.exists()) return file; // skip if already downloaded

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } else {
      throw Exception('Failed to download video');
    }
  }

  Future<void> _initVideo(String url) async {
    try {
      VideoPlayerController controller;

      // iOS workaround
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // Download video first
        final fileName = url.split('/').last;
        final file = await downloadVideo(url, fileName);
        controller = VideoPlayerController.file(file);
      } else {
        // Android plays directly from network
        controller = VideoPlayerController.network(url);
      }

      _videoCtl = controller;
      await _videoCtl!.initialize();

      _videoCtl!
        ..seekTo(Duration.zero)
        ..play();

      _videoCtl!.addListener(_videoListener);

      if (mounted) setState(() => _isVideoInitialized = true);
    } catch (e) {
      appLog("Video init error: $e");
      if (mounted) setState(() => _isError = true);
    }
  }
  void _videoListener() {
    if (_disposed || _videoCtl == null) return;

    final value = _videoCtl!.value;

    // Stop loader when playback starts
    if (value.isInitialized && !value.isBuffering) {
      if (_loadingController.isAnimating) {
        _loadingController.stop();
      }
    } else {
      if (!_loadingController.isAnimating) {
        _loadingController.repeat();
      }
    }

    if (value.position >= value.duration &&
        value.duration.inMilliseconds > 0) {
      widget.onCompleted();
    }
  }

  Widget _bottomVideoLoader() {
    return Positioned(
      bottom: 1,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 4, // thickness of the line
        child: AnimatedBuilder(
          animation: _loadingAnimation,
          builder: (context, _) {
            return FractionalTranslation(
              // Move from left (−1) → right (+1)
              translation: Offset(_loadingAnimation.value, 0),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.35,
                height: 4,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Colors.red,
                      Colors.orange,
                      Colors.yellow,
                      Colors.green,
                      Colors.blue,
                      Colors.indigo,
                      Colors.purple,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showStoryActions() {
    final t = context.read<TranslateProvider>().t;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white54,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // ================= DELETE (MY STORY)
              if (widget.story.isMine)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title:  Text(
                      t('txt_delete_story'),
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete();
                  },
                ),

              // ================= REPORT (OTHER STORY)
              if (!widget.story.isMine)
                ListTile(
                  leading: const Icon(Icons.flag, color: Colors.orange),
                  title:  Text(
        t('txt_report_story'),
                    style: TextStyle(color: Colors.orange),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmReport();
                  },
                ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    ).whenComplete(_resumeStory);
  }
  Future<void> _confirmDelete() async {
    final t = context.read<TranslateProvider>().t;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title:  Text(t('txt_delete_story')),
        content:  Text(t('txt_delete_confirm')),
        actions: [
          TextButton(
            child:  Text(t('txt_cancel')),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child:  Text(t('txt_delete'), style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteStory();
    }
  }

  Future<void> _deleteStory() async {
    final t = context.read<TranslateProvider>().t;
    final token = await LocalCache.getToken();
    final uri = Uri.parse(
        "${App_Constructor().BaseURL}/api/stories/${widget.story.id}/delete");

    final res = await http.post(uri, headers: {
      "Authorization": "Bearer $token",
    });

    if (res.statusCode == 200) {
      widget.onCompleted();
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(t('txt_story_deleted'))),
      );
      Navigator.popUntil(context, (route) => route.isFirst);

    }
  }
  Future<void> _confirmReport() async {
    final controller = TextEditingController();
    final t = context.read<TranslateProvider>().t;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title:  Text(t('txt_report_story')),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration:  InputDecoration(
            hintText: t('txt_reason_optional'),
          ),
        ),
        actions: [
          TextButton(
            child:  Text(t('txt_cancel')),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child:  Text(t('txt_report')),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _reportStory(controller.text.trim());
    }
  }

  Future<void> _reportStory(String reason) async {
    final token = await LocalCache.getToken();
    final t = context.read<TranslateProvider>().t;
    final uri = Uri.parse(
        "${App_Constructor().BaseURL}/api/stories/${widget.story.id}/report");

    await http.post(
      uri,
      headers: {
        "Authorization": "Bearer $token",
      },
      body: {
        "reason": reason.isEmpty ? "Inappropriate content" : reason,
      },
    );

    ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text(t('txt_story_reported'))),
    );
    Navigator.popUntil(context, (route) => route.isFirst);

  }

  @override
  void dispose() {
    _disposed = true;

    if (_videoCtl != null) {
      _videoCtl!.removeListener(_videoListener);
      _videoCtl!.pause(); // ✅ pause only
    }
    _loadingController.dispose();

    _imageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.story;
    final mediaUrl = STORY_MEDIA_BASE + s.media;
    final t = context.watch<TranslateProvider>().t;

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
                ?
            Text(
              t('txt_cannot_play_media'),
              style: TextStyle(color: Colors.white),
            )
                : (_isVideoFile(s.media))

    ? Stack(
              alignment: Alignment.center,
              children: [
                if (_videoCtl != null &&
                    !_disposed &&
                    _videoCtl!.value.isInitialized)
                  AspectRatio(
                    aspectRatio: _videoCtl!.value.aspectRatio,
                    child: VideoPlayer(_videoCtl!),
                  )
                else
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),


                //
                // // 🔻 Bottom loading line (Instagram style)
                // if (_videoCtl == null ||
                //     !_videoCtl!.value.isInitialized ||
                //     _videoCtl!.value.isBuffering)
                //   _bottomVideoLoader(),
              ],
            )
                : Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  mediaUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      // child: Icon(
                      //   Icons.broken_image,
                      //   color: Colors.white,
                      //   size: 48,
                      // ),
                    );
                  },
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                ),


                // ⏳ Loader before video initializes
                if (s.type == 'video')
                  const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),

          // Bottom text
          // Viewers count
// Viewers count
          if (_videoCtl == null ||
              !_videoCtl!.value.isInitialized ||
              _videoCtl!.value.isBuffering)  Positioned(bottom: 0, child:
    _bottomVideoLoader(),),
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
                      '${widget.story.viewers.length} ${t('txt_views')}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 60,
            right: 20,
            child: GestureDetector(
              onTap: () {
                _pauseStory();
                _showStoryActions();
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 20,
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
    if (_videoCtl?.value.isInitialized == true) {
      _videoCtl?.pause();
    }
    _imageTimer?.cancel();
  }

  void _resumeStory() {
    if (_videoCtl?.value.isInitialized == true) {
      _videoCtl?.play();
    } else {
      _imageTimer = Timer(const Duration(seconds: 5), widget.onCompleted);
    }
  }

  void _showViewersList(List viewers) {
    final t = context.read<TranslateProvider>().t;
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
               Text(
                t('txt_viewed_by'),
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
    final t = context.read<TranslateProvider>().t;
    final diff = DateTime.now().difference(d);

    if (diff.inMinutes < 1) return t('txt_just_now');
    if (diff.inHours < 1) {
      return t('txt_minutes_ago')
          .replaceFirst('{}', diff.inMinutes.toString());
    }
    if (diff.inDays < 1) {
      return t('txt_hours_ago')
          .replaceFirst('{}', diff.inHours.toString());
    }
    return t('txt_days_ago')
        .replaceFirst('{}', diff.inDays.toString());
  }

}
