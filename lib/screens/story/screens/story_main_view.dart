
import 'dart:async';
import 'dart:io';
// import 'dart:nativewrappers/_internal/vm/lib/typed_data_patch.dart';
import 'package:bla_bla_car/screens/story/screens/story_pager_screen.dart';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
// import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:http/http.dart' as http;
// import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../../api_service/app_constocter.dart';
import '../../../api_service/logger.dart';
import '../../../providers/translate_provider.dart';
import '../../../service/local_cache.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../auth/SignInScreen.dart';
import 'create_story.dart';
/// =======================
/// CONSTANT MEDIA BASE URL
/// =======================
const String STORY_MEDIA_BASE =
    "https://qadampayk.com/assets/story_media/";

/// =======================
/// STORY MODEL
/// =======================
class Story {
  final int id;
  final String media;
  final String type; // photo / video
  final String route;
  final String city;
  final String description;
  final DateTime createdAt;
  final int viewsCount;
  final bool isMine;
  final List<dynamic> viewers; // <- NEW FIELD

  Story({
    required this.id,
    required this.media,
    required this.type,
    required this.route,
    required this.city,
    required this.description,
    required this.createdAt,
    required this.viewsCount,
    required this.isMine,
    required this.viewers, // <- include in constructor
  });

  factory Story.fromJson(Map<String, dynamic> json, bool isMine) {
    return Story(
      id: json['id'],
      media: json['media'],
      type: json['type'],
      route: json['route'] ?? '',
      city: json['city'] ?? '',
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      viewsCount: json['views_count'] ?? 0,
      isMine: isMine,
      viewers: json['viewers'] != null ? List.from(json['viewers']) : [], // <- safe
    );
  }
}

/// =======================
/// STORY MAIN VIEW
/// =======================
class StoryMainView extends StatefulWidget {
  const StoryMainView({super.key});

  @override
  State<StoryMainView> createState() => _StoryMainViewState();
}

class _StoryMainViewState extends State<StoryMainView> {
  late Future<void> _future;
  List<Story> _myStories = [];
  List<Story> _otherStories = [];
  final Map<String, Future<Uint8List?>> _videoThumbCache = {};
  final Map<String, Uint8List> _thumbnailMemoryCache = {};
  final Set<int> _locallyViewedStories = {};

  @override
  void initState() {
    super.initState();
    _future = _loadStories();
  }

  /// =======================
  /// LOAD STORIES SEPARATELY
  /// =======================
  // Future<void> _loadStories() async {
  //   final token = await LocalCache.getToken();
  //   final my = await _fetchMyStories(token!);
  //   final other = await _fetchOtherStories(token, "", "");
  //
  //   if (!mounted) return;
  //
  //   setState(() {
  //     _myStories = my;
  //     _otherStories = other;
  //   });
  // }
  Future<void> _loadStories() async {
    final token = await LocalCache.getToken();
    final loggedIn = await LocalCache.isUserLoggedIn();

    List<Story> my = [];
    List<Story> other = [];

    if (loggedIn && token != null) {
      my = await _fetchMyStories(token);
    }

    other = await _fetchOtherStories(token, "","");

    if (!mounted) return;

    setState(() {
      _myStories = my;
      _otherStories = other;
    });

    await _precacheStoryImages(context);

  }

  Future<void> _precacheStoryImages(BuildContext context) async {
    final allStories = [..._myStories, ..._otherStories];

    for (final story in allStories) {
      if (story.type == "photo") {
        final imageProvider =
        NetworkImage(STORY_MEDIA_BASE + story.media);

        await precacheImage(imageProvider, context);
      }
    }
  }

  Future<File> downloadVideoFile(String url) async {
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/${url.hashCode}.mp4';
    final file = File(filePath);

    if (await file.exists()) return file; // use cached file

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } else {
      throw Exception('Failed to download video');
    }
  }

  /// =======================
  /// MY STORIES
  /// =======================
  Future<List<Story>> _fetchMyStories(String token) async {
    final uri =
    Uri.parse("${App_Constructor().BaseURL}/api/my-stories");

    final res = await http.get(uri, headers: {
      "Authorization": "Bearer $token",
      "Accept": "application/json",
    });

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data['stories'] as List)
          .map((e) => Story.fromJson(e, true))
          .toList();
    }
    return [];
  }

  Future<void> _createStoryOrLogin(BuildContext context) async {
    final loggedIn = await LocalCache.isUserLoggedIn();

    if (!loggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const PhoneNumberScreen(),
        ),
      );
      return;
    }

    // ✅ Navigate to Create Story screen
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateStoryScreen(),
      ),
    );
    _future = _loadStories();

  }
  /// =======================
  /// OTHER STORIES
  /// =======================
  Future<List<Story>> _fetchOtherStories(
      String? token, String route, String city) async {
    final uri = Uri.parse(
        "${App_Constructor().BaseURL}/api/others-stories?route=$route&city=$city");

    final res = await http.get(uri, headers: {
      "Authorization": "Bearer $token",
      "Accept": "application/json",
    });

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data['stories'] as List)
          .map((e) => Story.fromJson(e, false))
          .toList();
    }
    return [];
  }

  /// =======================
  /// VIEW API
  /// =======================
  Future<void> _markViewed(int id) async {
    final token = await LocalCache.getToken();
    final uri =
    Uri.parse("${App_Constructor().BaseURL}/api/stories/$id/view");

    await http.post(uri, headers: {
      "Authorization": "Bearer $token",
    });
  }
  Widget _storyAvatarMedia(Story story) {
    final mediaUrl = STORY_MEDIA_BASE + story.media;

    /// PHOTO STORY (already fine)
    if (story.type == "photo") {
      return CircleAvatar(
        radius: 30,
        backgroundImage: NetworkImage(mediaUrl),
      );
    }

    /// VIDEO STORY (FIXED)
    // return ClipOval(
    //   child: SizedBox(
    //     width: 60,
    //     height: 60,
    //     child: FutureBuilder<Uint8List?>(
    //       // future: _getVideoThumbnail(mediaUrl),
    //       future: mediaUrl.toString(),
    //       builder: (_, snap) {
    //         if (snap.connectionState == ConnectionState.waiting) {
    //           return Container(color: Colors.grey.shade300);
    //         }
    //
    //         if (!snap.hasData) {
    //           return Container(
    //             color: Colors.black12,
    //             child: const Icon(
    //               Icons.video_library,
    //               color: Colors.white54,
    //               size: 28,
    //             ),
    //           );
    //         }
    //
    //         return Stack(
    //           fit: StackFit.expand,
    //           children: [
    //             Image.memory(
    //               snap.data!,
    //               fit: BoxFit.cover,
    //             ),
    //             const Center(
    //               child: Icon(
    //                 Icons.play_circle_fill,
    //                 color: Colors.white,
    //                 size: 28,
    //               ),
    //             ),
    //           ],
    //         );
    //       },
    //     ),
    //   ),
    // );
    // VIDEO (NO THUMBNAIL)
    // return ClipOval(
    //   child: Container(
    //     width: 60,
    //     height: 60,
    //     color: Colors.black87,
    //     child: const Center(
    //       child: Icon(
    //         Icons.play_circle_fill,
    //         color: Colors.white,
    //         size: 30,
    //       ),
    //     ),
    //   ),
    // );

    // VIDEO
    return ClipOval(
      child: SizedBox(
        width: 60,
        height: 60,
        child: FutureBuilder<Uint8List?>(
          future: _getVideoThumbnail(mediaUrl),
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Container(color: Colors.grey.shade300);
            }

            if (!snap.hasData) {
              return Container(
                color: Colors.black12,
                child: const Icon(
                  Icons.video_library,
                  color: Colors.white54,
                  size: 28,
                ),
              );
            }

            return Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(
                  snap.data!,
                  fit: BoxFit.cover,
                ),
                const Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _emptyStoriesView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_stories,
              size: 90,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
             Text(
              context.watch<TranslateProvider>().t('txt_no_stories'),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
             Text(
              context.watch<TranslateProvider>().t('txt_story_empty_desc'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008955),
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label:  Text(
                context.watch<TranslateProvider>().t('txt_create_story'),
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              onPressed: () async {
                await _createStoryOrLogin (context);
                _future = _loadStories();
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _noOtherStoriesView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.travel_explore_rounded,
            size: 120,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 20),
           Text(
            context.watch<TranslateProvider>().t('txt_no_recent_stories'),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
           Text(
            context.watch<TranslateProvider>().t('txt_story_ahead'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// =======================
  /// UI
  /// =======================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title:  Text(    context.watch<TranslateProvider>().t('txt_road_stories'),
      )
      ),
      body: FutureBuilder(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              _future = _loadStories();
              setState(() {});
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // =========================
                // STORY BUBBLES (TOP)
                // =========================
                if (_myStories.isNotEmpty || _otherStories.isNotEmpty)
                  _storyBubbles(),

                // =========================
                // MY STORY EXISTS, OTHERS EMPTY
                // =========================
                if (_myStories.isNotEmpty && _otherStories.isEmpty)
                  _noOtherStoriesView(),

                // =========================
                // OTHER STORIES EXIST
                // =========================
                if (_otherStories.isNotEmpty) ...[
                   Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      context.watch<TranslateProvider>().t('txt_recent_stories'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _storyGrid(_otherStories),
                ],

                // =========================
                // COMPLETELY EMPTY STATE
                // =========================
                if (_myStories.isEmpty && _otherStories.isEmpty)
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.75,
                    child: _emptyStoriesView(),
                  ),
              ],
            ),
          );

        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF008955),
        icon: const Icon(Icons.add_a_photo, color: Colors.white),
        label:
         Text( context.watch<TranslateProvider>().t('txt_new_story'), style: TextStyle(color: Colors.white)),
        onPressed: () async {
          // await Navigator.push(
          //   context,
          //   MaterialPageRoute(builder: (_) => const CreateStoryScreen()),
          // );
          await _createStoryOrLogin(context);
          _future = _loadStories();
          setState(() {});
        },
      ),
    );
  }

  // Future<Uint8List?> getVideoThumbnail(String videoUrl) async {
  //   try {
  //     String? videoPath = videoUrl;
  //
  //     // iOS workaround: download video first
  //     if (defaultTargetPlatform == TargetPlatform.iOS) {
  //       final file = await downloadVideoFile(videoUrl);
  //       videoPath = file.path;
  //     }
  //
  //     final uint8list = await VideoThumbnail.thumbnailData(
  //       video: videoPath,
  //       imageFormat: ImageFormat.JPEG,
  //       maxWidth: 300,
  //       quality: 75,
  //     );
  //
  //     return uint8list;
  //   } catch (e) {
  //     appLog("Thumbnail error: $e");
  //     return null;
  //   }
  // }

  Future<Uint8List?> _getVideoThumbnail(String videoUrl) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final thumbPath = '${tempDir.path}/${videoUrl.hashCode}.jpg';

      final thumbFile = File(thumbPath);
      if (await thumbFile.exists()) {
        return await thumbFile.readAsBytes();
      }

      final resultPath =
      await FcNativeVideoThumbnail().getVideoThumbnail(
        srcFile: videoUrl,     // 🔥 REQUIRED
        destFile: thumbPath,   // 🔥 REQUIRED
        width: 400,            // 🔥 REQUIRED
        height: 400,           // 🔥 REQUIRED
        quality: 80,
      );

      if (resultPath == null) return null;

      return await File(resultPath as String).readAsBytes();
    } catch (e) {
      appLog("Thumbnail error: $e");
      return null;
    }
  }

  /// =======================
  /// STORY BUBBLES
  /// =======================
  Widget _storyBubbles() {
    final List<Widget> bubbles = [];

    /// =========================
    /// MY STORY (ONLY ONE BUBBLE)
    /// =========================
    if (_myStories.isNotEmpty) {
      bubbles.add(
        GestureDetector(
          onTap: () => _openStory(_myStories, 0),
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 33,
                  backgroundColor: Colors.green,
                  child: _storyAvatarMedia(_myStories[0]),
                ),
                const SizedBox(height: 6),
                 Text(
                  context.watch<TranslateProvider>().t('txt_my_story'),
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    /// =========================
    /// OTHER USERS STORIES
    /// =========================
    for (int i = 0; i < _otherStories.length; i++) {
      final story = _otherStories[i];

      bubbles.add(
        GestureDetector(
          onTap: () => _openStory(_otherStories, i),
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 33,
                  backgroundColor: Colors.blue,
                  child: _storyAvatarMedia(story),
                ),
                const SizedBox(height: 6),
                Text(
                  story.city,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        children: bubbles,
      ),
    );
  }
  Widget _imageError() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(
          Icons.broken_image_rounded,
          color: Colors.grey,
          size: 40,
        ),
      ),
    );
  }

  /// =======================
  /// STORY GRID (OTHER USERS ONLY)
  /// =======================
  Widget _storyGrid(List<Story> stories) {
    return GridView.builder(
      itemCount: stories.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (_, i) {
        final s = stories[i];
        final mediaUrl = STORY_MEDIA_BASE + s.media;

        return GestureDetector(
          onTap: () => _openStory(stories, i),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                /// ======================
                /// PHOTO
                /// ======================
                if (s.type == "photo")
                  Image.network(
                    mediaUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imageError(),
                  ),

                /// ======================
                /// VIDEO THUMBNAIL (SAFE)
                /// ======================
                if (s.type == "video")
                  FutureBuilder<Uint8List?>(
                    future: _getVideoThumbnail(mediaUrl),
                    builder: (_, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return Container(color: Colors.grey.shade300);
                      }

                      /// ❗ Thumbnail FAILED → show fallback poster
                      if (!snap.hasData) {
                        return Container(
                          color: Colors.black12,
                          child: const Center(
                            child: Icon(
                              Icons.video_library,
                              color: Colors.white54,
                              size: 48,
                            ),
                          ),
                        );
                      }

                      return Image.memory(
                        snap.data!,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                  // if (s.type == "video")
                  //   Container(
                  //     color: Colors.black87,
                  //     child: const Center(
                  //       child: Icon(
                  //         Icons.play_circle_fill,
                  //         color: Colors.white,
                  //         size: 48,
                  //       ),
                  //     ),
                  //   ),
                /// ======================
                /// PLAY ICON
                /// ======================
                if (s.type == "video")
                  const Positioned(
                    bottom: 8,
                    right: 8,
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// =======================
  /// OPEN STORY
  /// =======================
  // void _openStory(List<Story> stories, int index) {
  //   if (!stories[index].isMine) {
  //     _markViewed(stories[index].id);
  //   }
  //
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (_) => StoryPagerScreen(
  //         stories: stories,
  //         initialIndex: index,
  //       ),
  //     ),
  //   );
  // }
  void _openStory(List<Story> stories, int index) async {
    final loggedIn = await LocalCache.isUserLoggedIn();
    final story = stories[index];

    if (loggedIn && !story.isMine && !_locallyViewedStories.contains(story.id)) {
      _locallyViewedStories.add(story.id);
      _markViewed(story.id);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryPagerScreen(
          stories: stories,
          initialIndex: index,
        ),
      ),
    );
  }


}

