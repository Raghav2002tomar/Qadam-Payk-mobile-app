




import 'dart:async';
import 'package:bla_bla_car/screens/story/screens/story_pager_screen.dart';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../api_service/app_constocter.dart';
import '../../../service/local_cache.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _future = _loadStories();
  }

  /// =======================
  /// LOAD STORIES SEPARATELY
  /// =======================
  Future<void> _loadStories() async {
    final token = await LocalCache.getToken();
    _myStories = await _fetchMyStories(token!);
    _otherStories = await _fetchOtherStories(token, "", "");
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

  /// =======================
  /// OTHER STORIES
  /// =======================
  Future<List<Story>> _fetchOtherStories(
      String token, String route, String city) async {
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

  /// =======================
  /// UI
  /// =======================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Road Stories")),
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
              children: [
                /// 🔥 TOP STORIES (MY + OTHER)
                _storyBubbles(),

                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    "Recent Stories",
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                /// 🔥 RECENT STORIES (ONLY OTHER USERS)
                _storyGrid(_otherStories),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF008955),
        icon: const Icon(Icons.add_a_photo, color: Colors.white),
        label:
        const Text("New Story", style: TextStyle(color: Colors.white)),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateStoryScreen()),
          );
          _future = _loadStories();
          setState(() {});
        },
      ),
    );
  }

  /// =======================
  /// STORY BUBBLES
  /// =======================
  Widget _storyBubbles() {
    // Show only one "My Story" bubble if there are any
    final topBubbles = <Widget>[];

    if (_myStories.isNotEmpty) {
      topBubbles.add(
        GestureDetector(
          onTap: () => _openStory(_myStories, 0), // Open first story of my stories
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 33,
                  backgroundColor: Colors.green,
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: _myStories[0].type == "photo"
                        ? NetworkImage(STORY_MEDIA_BASE + _myStories[0].media)
                        : null,
                    child: _myStories[0].type == "video"
                        ? const Icon(Icons.play_circle_fill, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "My Story",
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Add all other users' stories
    for (var s in _otherStories) {
      topBubbles.add(
        GestureDetector(
          onTap: () {
            final index = _otherStories.indexOf(s);
            _openStory(_otherStories, index);
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 33,
                  backgroundColor: Colors.blue,
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: s.type == "photo"
                        ? NetworkImage(STORY_MEDIA_BASE + s.media)
                        : null,
                    child: s.type == "video"
                        ? const Icon(Icons.play_circle_fill, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  s.city,
                  style: const TextStyle(fontSize: 12),
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
        children: topBubbles,
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
              children: [
                Image.network(
                  mediaUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
                if (s.type == "video")
                  const Positioned(
                    bottom: 6,
                    right: 6,
                    child: Icon(Icons.play_circle_fill,
                        color: Colors.white, size: 28),
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
  void _openStory(List<Story> stories, int index) {
    if (!stories[index].isMine) {
      _markViewed(stories[index].id);
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

