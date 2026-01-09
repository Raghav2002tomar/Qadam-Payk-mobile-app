// story_video_cache.dart
import 'package:video_player/video_player.dart';

class StoryVideoCache {
  static final Map<String, VideoPlayerController> _cache = {};

  static VideoPlayerController? get(String url) {
    return _cache[url];
  }

  static Future<VideoPlayerController> load(String url) async {
    if (_cache.containsKey(url)) {
      return _cache[url]!;
    }

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    await controller.initialize();
    controller.setLooping(false);
    controller.setVolume(1.0);

    _cache[url] = controller;
    return controller;
  }

  static void pauseAll() {
    for (final c in _cache.values) {
      if (c.value.isInitialized) {
        c.pause();
      }
    }
  }

  static void clear() {
    for (final c in _cache.values) {
      c.dispose();
    }
    _cache.clear();
  }
}
