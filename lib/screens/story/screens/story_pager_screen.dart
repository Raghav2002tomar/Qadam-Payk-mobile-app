
import 'dart:async';
import 'dart:io';

import 'package:bla_bla_car/screens/story/screens/story_full_view.dart';
import 'package:bla_bla_car/screens/story/screens/story_main_view.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../controller/story_controller.dart';
import 'create_story.dart';

/// STORY PAGER SCREEN (auto next / prev)
class StoryPagerScreen extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;

  const StoryPagerScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  State<StoryPagerScreen> createState() => _StoryPagerScreenState();
}

class _StoryPagerScreenState extends State<StoryPagerScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      _currentIndex++;
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _prevStory() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.stories.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: total,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (context, index) {
                final story = widget.stories[index];
                return StoryFullView(
                  story: story,
                  onCompleted: _nextStory,
                  onPrevious: _prevStory,
                );
              },
            ),
            // top progress + header
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Column(
                children: [
                  Row(
                    children: List.generate(
                      total,
                          (i) => Expanded(
                        child: Container(
                          height: 3,
                          margin: EdgeInsets.only(
                            left: i == 0 ? 0 : 3,
                            right: i == total - 1 ? 0 : 3,
                          ),
                          decoration: BoxDecoration(
                            color: i <= _currentIndex
                                ? Colors.white
                                : Colors.white24,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white24,
                        child:
                        Icon(Icons.person, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.stories[_currentIndex].route ??
                              widget.stories[_currentIndex].city ??
                              'Route',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
