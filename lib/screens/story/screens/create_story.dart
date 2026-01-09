import 'dart:async';
import 'dart:io';
import 'package:bla_bla_car/screens/story/screens/story_main_view.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_trimmer/video_trimmer.dart';

import '../../../api_service/logger.dart';
import '../../../main.dart';
import '../../../providers/translate_provider.dart';
import '../../../service/colors.dart';
import '../../../service/local_cache.dart';
import '../../mainView/search/controller/search_provoder.dart';
import '../controller/story_controller.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  int _cameraIndex = 0;

  bool _isRecording = false;
  Timer? _timer;
  int _secondsLeft = 30;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(
      cameras[_cameraIndex],
      ResolutionPreset.max,
      enableAudio: true,
    );
    await _cameraController!.initialize();
    if (mounted) setState(() => _isCameraInitialized = true);
  }

  Future<void> _switchCamera() async {
    final cameras = await availableCameras();
    if (cameras.length < 2) return;

    _cameraIndex = _cameraIndex == 0 ? 1 : 0;
    await _cameraController!.dispose();

    _cameraController = CameraController(
      cameras[_cameraIndex],
      ResolutionPreset.max,
      enableAudio: true,
    );

    await _cameraController!.initialize();
    setState(() {});
  }

  Future<void> _takePhoto() async {
    if (!_isCameraInitialized) return;

    final XFile file = await _cameraController!.takePicture();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            StoryPreviewScreen(file: File(file.path), mediaType: "image"),
      ),
    );
  }

  Future<File> copyVideoToTemp(File original) async {
    final Directory tempDir = await Directory.systemTemp.createTemp('story_video_');
    final String newPath =
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';

    return original.copy(newPath);
  }

  Future<File> trimVideoTo30Sec(File inputFile) async {
    final Trimmer trimmer = Trimmer();

    await trimmer.loadVideo(videoFile: inputFile);

    final int durationMs =
        trimmer.videoPlayerController!.value.duration.inMilliseconds;

    // 🔥 ALWAYS return a NEW FILE (critical for VideoPlayer)
    if (durationMs <= 30000) {
      return await copyVideoToTemp(inputFile);
    }

    final Completer<File> completer = Completer<File>();

    await trimmer.saveTrimmedVideo(
      startValue: 0,
      endValue: 30,
      storageDir: StorageDir.temporaryDirectory,
      onSave: (String? outputPath) async {
        if (outputPath == null) {
          completer.complete(await copyVideoToTemp(inputFile));
        } else {
          completer.complete(File(outputPath));
        }
      },
    );

    return completer.future;
  }

  Future<void> _startVideo() async {
    if (_cameraController == null) return;
    if (!_cameraController!.value.isInitialized) return;
    if (_cameraController!.value.isRecordingVideo) return;

    setState(() {
      _isRecording = true;
      _secondsLeft = 30;
    });

    await _cameraController!.startVideoRecording();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        _stopVideo();
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  Future<void> _stopVideo() async {
    try {
      if (_cameraController == null) return;
      if (!_cameraController!.value.isInitialized) return;
      if (!_cameraController!.value.isRecordingVideo) return;

      _timer?.cancel();
      _timer = null;

      setState(() => _isRecording = false);

      final XFile xFile = await _cameraController!.stopVideoRecording();

      // 🔥 FORCE NEW FILE
      File videoFile = await copyVideoToTemp(File(xFile.path));

      // 🔥 SAFE TRIM
      videoFile = await trimVideoTo30Sec(videoFile);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StoryPreviewScreen(
            key: UniqueKey(),
            file: videoFile,
            mediaType: "video",
          ),
        ),
      );
    } on CameraException catch (e) {
      appLog("Camera stop error: ${e.code} | ${e.description}");
    } catch (e) {
      appLog("Unexpected stop error: $e");
    }
  }

  // Future<void> _pickGallery() async {
  //   final ImagePicker picker = ImagePicker();
  //   final XFile? file = await picker.pickMedia();
  //
  //   if (file == null) return;
  //
  //   bool isVideo =
  //       file.path.endsWith(".mp4") || file.path.endsWith(".mov");
  //
  //   File finalFile = File(file.path);
  //
  //   if (isVideo) {
  //     finalFile = await trimVideoTo30Sec(finalFile);
  //   }
  //
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (_) => StoryPreviewScreen(
  //         file: finalFile,
  //         mediaType: isVideo ? "video" : "image",
  //       ),
  //     ),
  //   );
  // }

  Future<void> _pickGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? picked = await picker.pickMedia();

    if (picked == null) return;

    File file = File(picked.path);

    final String? mimeType = lookupMimeType(picked.path);
    final bool isVideo =
        mimeType?.startsWith('video/') == true ||
            picked.path.toLowerCase().endsWith('.mp4') ||
            picked.path.toLowerCase().endsWith('.mov');

    if (isVideo) {
      // 🔥 STEP 1: force new file
      file = await forceNewVideoFile(file);

      // 🔥 STEP 2: trim safely
      file = await trimVideoTo30Sec(file);

      // 🔥 STEP 3: force AGAIN (important)
      file = await forceNewVideoFile(file);
    }

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryPreviewScreen(
          file: file,
          mediaType: isVideo ? "video" : "image",
        ),
      ),
    );
  }
  Future<File> forceNewVideoFile(File original) async {
    final dir = await Directory.systemTemp.createTemp('story_video_final_');
    final newPath =
        '${dir.path}/${DateTime.now().microsecondsSinceEpoch}.mp4';
    return original.copy(newPath);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isCameraInitialized
          ? Stack(
              children: [
                // 📌 FULL SCREEN CAMERA
                Positioned.fill(child: CameraPreview(_cameraController!)),

                // 🔙 Close Button
                Positioned(
                  top: 40,
                  left: 20,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                // 📸 Capture Controls
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      if (_isRecording)
                        Text(
                          "$_secondsLeft s",
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 📁 Gallery Button
                          GestureDetector(
                            onTap: _pickGallery,
                            child: CircleAvatar(
                              backgroundColor: Colors.white24,
                              radius: 28,
                              child: const Icon(
                                Icons.photo_library,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(width: 30),

                          // 🎥 Capture Button
                          GestureDetector(
                            onTap: _isRecording ? _stopVideo : _takePhoto,
                            onLongPress: !_isRecording ? _startVideo : null,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _isRecording
                                      ? Colors.red
                                      : Colors.white,
                                  width: 5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 30),

                          // 🔄 Switch Camera
                          GestureDetector(
                            onTap: _switchCamera,
                            child: const CircleAvatar(
                              backgroundColor: Colors.white24,
                              radius: 28,
                              child: Icon(
                                Icons.cameraswitch,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}

class StoryPreviewScreen extends StatefulWidget {
  final File file;
  final String mediaType;

  const StoryPreviewScreen({
    super.key,
    required this.file,
    required this.mediaType,
  });

  @override
  State<StoryPreviewScreen> createState() => _StoryPreviewScreenState();
}

class _StoryPreviewScreenState extends State<StoryPreviewScreen>
    with RouteAware {

  VideoPlayerController? vc;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    vc?.pause();
    vc?.dispose();
    vc = null;
    super.dispose();
  }


  // 🔥 WHEN A NEW SCREEN OPENS (Details screen)
  @override
  void didPushNext() {
    vc?.pause(); // ✅ DO NOT DISPOSE
  }


  void _initVideo() async {
    if (widget.mediaType != "video") return;

    // 🔥 ensure old texture is fully gone
    await Future.delayed(const Duration(milliseconds: 50));

    vc = VideoPlayerController.file(widget.file);

    await vc!.initialize();

    if (!mounted) return;

    vc!
      ..setLooping(true)
      ..play();

    setState(() {});
  }

  void _disposeVideo() {
    vc?.pause();
    vc?.dispose();
    vc = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: InkWell(onTap: (){Navigator.pop(context);}, child: Icon(Icons.arrow_back_ios,color: Colors.white,)),
        actions: [
          InkWell(onTap: (){
            vc?.pause(); // ✅ stop video before navigating
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StoryDetailsScreen(
                  file: widget.file,
                  mediaType: widget.mediaType,
                ),
              ),
            );          }, child: Text(  context.watch<TranslateProvider>().t('txt_next'),
        style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 16),)),SizedBox(width: 16,)

        ],
      ),
       backgroundColor: Colors.black,

      body: SafeArea(
        child: Stack(
          children: [
            // FULL MEDIA PREVIEW
            Positioned.fill(
              child: widget.mediaType == "image"
                  ? Image.file(widget.file, fit: BoxFit.cover)
                  : (vc != null && vc!.value.isInitialized)
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: vc!.value.size.width,
                        height: vc!.value.size.height,
                        child: VideoPlayer(vc!),
                      ),
                    )
                  : const Center(child: CircularProgressIndicator(color: Colors.red,)),
            ),


            // NEXT BUTTON
            Positioned(
              bottom: 20,
              right: 20,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF008955),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                ),
                onPressed: () {
                  vc?.pause(); // ✅ stop video before navigating
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StoryDetailsScreen(
                        file: widget.file,
                        mediaType: widget.mediaType,
                      ),
                    ),
                  );
                },
                child: const Text(
                  "Next",
                  style: TextStyle(fontSize: 20, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StoryDetailsScreen extends StatefulWidget {
  final File file;
  final String mediaType;

  const StoryDetailsScreen({
    super.key,
    required this.file,
    required this.mediaType,
  });

  @override
  State<StoryDetailsScreen> createState() => _StoryDetailsScreenState();
}

class _StoryDetailsScreenState extends State<StoryDetailsScreen> {
  final TextEditingController title = TextEditingController();
  final TextEditingController desc = TextEditingController();
  String category = "Weather";
  bool posting = false;
  final GlobalKey<_LocationFieldState> _toFieldKey = GlobalKey();
  double uploadProgress = 0;

  List<String> _cityNames = [];
  bool _isLoadingCities = true;
  final GlobalKey<_LocationFieldState> _fromFieldKey = GlobalKey();
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {

    final provider = SearchProvider();
    await provider.fetchCities(context);
    setState(() {
      _cityNames = provider.cities.map((e) => e.cityName).toList();
      _isLoadingCities = false;
    });
  }




  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title:  Text(
          context.watch<TranslateProvider>().t('txt_story_details'),
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// STORY MEDIA PREVIEW CARD
            Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: widget.mediaType == "image"
                  ? Image.file(widget.file, fit: BoxFit.cover)
                  : Center(
                child: Icon(Icons.play_circle_fill,
                    color: Colors.white, size: 60),
              ),
            ),

            const SizedBox(height: 20),
            // _LocationField(
            //   key: _fromFieldKey,
            //   label: context.watch<TranslateProvider>().t('txt_where'),
            //   controller: _fromController,
            //   options: _cityNames,
            //   icon: "assets/images/red_icon.svg",
            //   cs: cs,
            // ),
            TextField(
              // focusNode: _focusNode,
              controller: _fromController,
              decoration: InputDecoration(
                labelText: context.watch<TranslateProvider>().t('txt_where'),
                prefixIconConstraints: const BoxConstraints(minWidth: 40),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(6),
                  child: SvgPicture.asset("assets/images/red_icon.svg", height: 20),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                // fillColor: Theme.of(context).colorScheme,
              ),
              // onTap: () {
              //   _focusNode.requestFocus();
              //   Future.delayed(const Duration(microseconds: 800), () {
              //     if (_filteredOptions.isNotEmpty && _focusNode.hasFocus) {
              //       _showOverlay();
              //     }
              //   });
              // },
            ),
            // const SizedBox(height: 16),
            // _LocationField(
            //   key: _toFieldKey,
            //   label: context.watch<TranslateProvider>().t('txt_going_to'),
            //   controller: _toController,
            //   options: _cityNames,
            //   icon: "assets/images/blue_icon.svg",
            //   cs: cs,
            // ),


            const SizedBox(height: 20),

            /// DESCRIPTION FIELD
             Text(
              context.watch<TranslateProvider>().t('txt_description'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: desc,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: context.watch<TranslateProvider>().t('txt_description_hint'),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 20),

            /// CATEGORY DROPDOWN
             Text(
              context.watch<TranslateProvider>().t('txt_category'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField(
                value: category,
                decoration: const InputDecoration(border: InputBorder.none),
                items: [
                  DropdownMenuItem(
                    value: "Weather",
                    child: Text(context.watch<TranslateProvider>().t('txt_weather')),
                  ),
                  DropdownMenuItem(
                    value: "Accident",
                    child: Text(context.watch<TranslateProvider>().t('txt_accident')),
                  ),
                  DropdownMenuItem(
                    value: "Repair",
                    child: Text(context.watch<TranslateProvider>().t('txt_road_repair')),
                  ),
                  DropdownMenuItem(
                    value: "Traffic",
                    child: Text(context.watch<TranslateProvider>().t('txt_traffic')),
                  ),
                ],

                onChanged: (v) => setState(() => category = v!),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            minimumSize: const Size(double.infinity, 55),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
          ),
          onPressed: posting
              ? null
              : () async {
            // ================= VALIDATION =================


            setState(() {
              posting = true;
              uploadProgress = 0;
            });

            try {
              final token = await LocalCache.getToken();
              if (token == null) {
                throw Exception("User not authenticated");
              }

              final route =
                  "${_fromController.text.trim()} - ${_toController.text.trim()}";
              final city = _toController.text.trim();

              bool success = false;

              // ==================================================
              // 🖼 IMAGE FLOW (NO CHUNKS)
              // ==================================================
              if (widget.mediaType == "image") {
                // Normalize image
                final File compressedImage =
                await StoryRepo.instance.compressImage720(widget.file);

                success = await StoryRepo.uploadImageNormal(
                  token: token,
                  file: compressedImage,
                  route: route,
                  city: city,
                  description: desc.text.trim(),
                  category: category,
                );
              }

              // ==================================================
              // 🎥 VIDEO FLOW (CHUNKED)
              // ==================================================
              else {
                File videoFile =
                await StoryRepo.instance.ensureMp4File(widget.file);
                videoFile =
                await StoryRepo.instance.compressVideo720(videoFile);

                success = await StoryRepo.uploadStoryInChunks(
                  token: token,
                  file: videoFile,
                  mediaType: "video",
                  route: route,
                  city: city,
                  description: desc.text.trim(),
                  category: category,
                  onProgress: (progress) {
                    setState(() {
                      uploadProgress = progress;
                    });
                  },
                );
              }

              setState(() => posting = false);

              // ================= RESULT =================
              if (success) {
                Navigator.popUntil(context, (route) => route.isFirst);

                ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                    content: Text(    context.watch<TranslateProvider>().t('txt_story_published'),
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                    content: Text(    context.watch<TranslateProvider>().t('txt_story_publish_failed'),
                    ),
                  ),
                );
              }
            } catch (e) {
              setState(() => posting = false);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(    "${context.watch<TranslateProvider>().t('txt_upload_error')}: $e",
                  ),
                ),
              );
            }
          },


          child:  posting
              ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: uploadProgress / 100,
                minHeight: 6,
                backgroundColor: Colors.grey.shade300,
                color: Colors.green.shade600,
              ),
              const SizedBox(height: 8),
              Text(
                "${context.watch<TranslateProvider>().t('txt_uploading')} ${uploadProgress.toStringAsFixed(0)}%",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          )
              :  Text(
            context.watch<TranslateProvider>().t('txt_publish_story'),
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),

        ),
      ),
    );
  }
}



class _LocationField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String icon;
  final List<String> options;
  final ColorScheme cs;

  const _LocationField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.options,
    required this.cs,
  });

  @override
  State<_LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<_LocationField> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<String> _filteredOptions = [];
  final FocusNode _focusNode = FocusNode();
  ScrollPosition? _scrollPosition;

  @override
  void initState() {
    super.initState();
    _filteredOptions = widget.options;
    widget.controller.addListener(_filterOptions);
  }

  void _filterOptions() {
    final query = widget.controller.text.toLowerCase();
    setState(() {
      _filteredOptions = query.isEmpty
          ? widget.options
          : widget.options
          .where((city) => city.toLowerCase().contains(query))
          .toList();
    });
    if (_filteredOptions.isNotEmpty && _focusNode.hasFocus) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }

    _overlayEntry = _createOverlay();
    Overlay.of(context).insert(_overlayEntry!);

    // Listen to scrolling to hide dropdown
    _scrollPosition = Scrollable.of(context)?.position;
    _scrollPosition?.addListener(_removeOverlay);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;

    // Remove scroll listener
    _scrollPosition?.removeListener(_removeOverlay);
    _scrollPosition = null;
  }

  OverlayEntry _createOverlay() {
    return OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32, // adjust padding
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60), // height of TextField + margin
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _filteredOptions.length,
                itemBuilder: (context, index) {
                  final city = _filteredOptions[index];
                  return ListTile(
                    leading: const Icon(Icons.location_city,
                        color: AppTheme.seedPrimary),
                    title: Text(city),
                    onTap: () {
                      widget.controller.text = city;
                      _removeOverlay();
                      FocusScope.of(context).unfocus(); // ✅ hide keyboard

                      // _focusNode.requestFocus(); // keep keyboard open
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        focusNode: _focusNode,
        controller: widget.controller,
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(6),
            child: SvgPicture.asset(widget.icon, height: 20),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: widget.cs.surface,
        ),
        onTap: () {
          _focusNode.requestFocus();
          Future.delayed(const Duration(microseconds: 800), () {
            if (_filteredOptions.isNotEmpty && _focusNode.hasFocus) {
              _showOverlay();
            }
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_filterOptions);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }
}


