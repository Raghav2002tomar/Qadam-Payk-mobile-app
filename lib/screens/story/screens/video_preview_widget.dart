
import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../controller/story_controller.dart';
import 'create_story.dart';

/// VIDEO PREVIEW WIDGET (in create screen)
class VideoPreviewWidget extends StatefulWidget {
  final File file;
  const VideoPreviewWidget({super.key, required this.file});
  @override
  State<VideoPreviewWidget> createState() => _VideoPreviewWidgetState();
}

class _VideoPreviewWidgetState extends State<VideoPreviewWidget> {
  VideoPlayerController? _ctl;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _ctl = VideoPlayerController.file(widget.file);
      await _ctl!.initialize();
      _ctl!
        ..setLooping(true)
        ..play();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _ctl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ctl == null || !_ctl!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return AspectRatio(
      aspectRatio: _ctl!.value.aspectRatio,
      child: VideoPlayer(_ctl!),
    );
  }
}
