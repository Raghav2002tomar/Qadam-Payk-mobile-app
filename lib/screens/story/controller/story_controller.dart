// import 'dart:io';
// import 'package:bla_bla_car/api_service/app_constocter.dart';
// import '../screens/story_main_view.dart';
// import 'package:http/http.dart' as http;
// import 'package:path/path.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:video_compress/video_compress.dart';
// import 'package:path_provider/path_provider.dart';
// class StoryRepo {
//   StoryRepo._private();
//   static final StoryRepo instance = StoryRepo._private();
//
//   final List<Story> _stories = [];
//
//
//   /// ================= IMAGE COMPRESSION =================
//   static Future<Object> _compressImage(File file) async {
//     final dir = await getTemporaryDirectory();
//     final targetPath =
//         "${dir.path}/img_${DateTime.now().millisecondsSinceEpoch}.jpg";
//
//     final result = await FlutterImageCompress.compressAndGetFile(
//       file.path,
//       targetPath,
//       quality: 75,
//       format: CompressFormat.jpeg,
//     );
//
//     return result ?? file;
//   }
//
//   /// ================= VIDEO COMPRESSION =================
//   static Future<File> _compressVideo(File file) async {
//     await VideoCompress.setLogLevel(0);
//
//     final info = await VideoCompress.compressVideo(
//       file.path,
//       quality: VideoQuality.MediumQuality,
//       deleteOrigin: false,
//       includeAudio: true,
//     );
//
//     return info?.file ?? file;
//   }

//   /// ================= MAIN UPLOAD FUNCTION =================
//   static Future<bool> uploadStory({
//     required String token,
//     required File file,
//     required String mediaType, // photo | video
//     required String route,
//     required String city,
//     required String description,
//     required String category,
//   }) async {
//     try {
//       File uploadFile = file;
//
//       /// 📏 SIZE CHECK
//       final sizeMB = file.lengthSync() / (1024 * 1024);
//       if (mediaType == "video" && sizeMB > 300) {
//         throw Exception("Video too large");
//       }
//
//       /// 🔥 COMPRESS
//       if (mediaType == "photo") {
//         uploadFile =  _compressImage(file) as File;
//       } else {
//         uploadFile = await _compressVideo(file);
//       }
//
//       final compressedSize =
//           uploadFile.lengthSync() / (1024 * 1024);
//       appLog("📦 Upload size: ${compressedSize.toStringAsFixed(2)} MB");
//
//       final uri = Uri.parse("${App_Constructor().BaseURL}/api/stories");
//       final request = http.MultipartRequest("POST", uri);
//
//       /// 🔐 HEADERS
//       request.headers.addAll({
//         "Authorization": "Bearer $token",
//         "Accept": "application/json",
//       });
//
//       /// 📝 FORM FIELDS (MATCH POSTMAN)
//       request.fields.addAll({
//         "category": category,
//         "description": description,
//         "city": city,
//         "route": route,
//         "type": mediaType == "image" ? "photo" : "video",
//       });
//
//       /// 📎 FILE
//       request.files.add(
//         await http.MultipartFile.fromPath(
//           "media",
//           uploadFile.path,
//           filename: basename(uploadFile.path),
//         ),
//       );
//
//       /// 🚀 SEND
//       final response = await request.send();
//       final body = await http.Response.fromStream(response);
//
//       appLog("✅ Status: ${response.statusCode}");
//       appLog(body.body);
//
//       return response.statusCode == 200 ||
//           response.statusCode == 201;
//     } catch (e) {
//       appLog("❌ Upload error: $e");
//       return false;
//     } finally {
//       VideoCompress.deleteAllCache();
//     }
//   }
//
// }



import 'dart:io';
import 'dart:math';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:video_compress/video_compress.dart';

import 'package:bla_bla_car/api_service/app_constocter.dart';

import '../../../api_service/logger.dart';

class StoryRepo {
  StoryRepo._();
  static final StoryRepo instance = StoryRepo._();

  // ==========================================================
  // 🔧 CHUNK SIZE (720 KB)
  // ==========================================================
  static const int _chunkSize = 720 * 1024;

  // ==========================================================
  // 🖼️ IMAGE COMPRESSION (MAX 720px)
  // ==========================================================
  Future<File> compressImage720(File file) async {
    final targetPath =
        "${file.parent.path}/compressed_${basename(file.path)}";

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      minWidth: 720,
      minHeight: 720,
      quality: 80,
      format: CompressFormat.jpeg,
    );

    if (result == null) {
      throw Exception("Image compression failed");
    }

    return File(result.path);
  }

  // ==========================================================
  // 🎯 ENSURE MP4 FILE
  // ==========================================================
  Future<File> ensureMp4File(File file) async {
    if (extension(file.path).toLowerCase() == '.mp4') {
      return file;
    }

    final dir = Directory.systemTemp;
    return await file.copy(
      "${dir.path}/${basenameWithoutExtension(file.path)}.mp4",
    );
  }

  // ==========================================================
  // 🎥 VIDEO COMPRESSION (SAFE 720p)
  // ==========================================================
  Future<File> compressVideo720(File file) async {
    await VideoCompress.setLogLevel(0);

    final info = await VideoCompress.compressVideo(
      file.path,
      quality: VideoQuality.MediumQuality,
      deleteOrigin: false,
      includeAudio: true,
    );

    if (info == null || info.file == null) {
      throw Exception("Video compression failed");
    }

    return info.file!;
  }


  static Future<bool> uploadImageNormal({
    required String token,
    required File file,
    required String route,
    required String city,
    required String description,
    required String category,
  }) async {
    try {
      final uri = Uri.parse("${App_Constructor().BaseURL}/api/stories");
      final request = http.MultipartRequest("POST", uri);

      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      });

      request.fields.addAll({
        "type": "photo",
        "route": route,
        "city": city,
        "description": description,
        "category": category,
      });

      request.files.add(
        await http.MultipartFile.fromPath(
          "media", // IMPORTANT: backend expects "media"
          file.path,
          filename: basename(file.path),
        ),
      );

      final response = await request.send();
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      appLog("❌ Image upload error: $e");
      return false;
    }
  }


  // ==========================================================
  // 🚀 STORY UPLOAD (CHUNKED & SAFE)
  // ==========================================================
  static Future<bool> uploadStoryInChunks({
    required String token,
    required File file,
    required String mediaType,
    required String route,
    required String city,
    required String description,
    required String category,
    required Function(double progress) onProgress,
  }) async {
    try {
      final uri = Uri.parse("${App_Constructor().BaseURL}/api/stories");

      final fileSize = file.lengthSync();
      final totalChunks = (fileSize / _chunkSize).ceil();
      final fileName = basename(file.path);
      final fileExt = extension(file.path);

      final uploadId =
          "story_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}";

      appLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      appLog("📤 STORY UPLOAD START");
      appLog("📁 File Path       : ${file.path}");
      appLog("📄 File Name       : $fileName");
      appLog("📎 File Extension  : $fileExt");
      appLog("📦 File Size       : $fileSize bytes");
      appLog("🧩 Total Chunks    : $totalChunks");
      appLog("📏 Chunk Size      : $_chunkSize bytes");
      appLog("🎞 Media Type      : $mediaType");
      appLog("🆔 Upload ID       : $uploadId");
      appLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

      final raf = file.openSync(mode: FileMode.read);

      for (int i = 0; i < totalChunks; i++) {
        final start = i * _chunkSize;
        final end = min(start + _chunkSize, fileSize);
        final isLast = i == totalChunks - 1;

        raf.setPositionSync(start);
        final bytes = raf.readSync(end - start);

        appLog("\n⬆️ UPLOADING CHUNK ${i + 1}/$totalChunks");
        appLog("   ↳ Chunk Index   : $i");
        appLog("   ↳ Start Byte    : $start");
        appLog("   ↳ End Byte      : $end");
        appLog("   ↳ Bytes Length  : ${bytes.length}");
        appLog("   ↳ Is Last Chunk : $isLast");
        appLog("   ↳ Chunk File Path : ${basename(file.path)}");

        final request = http.MultipartRequest("POST", uri);

        // HEADERS
        request.headers.addAll({
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        });

        appLog("📨 Headers:");
        request.headers.forEach((k, v) => appLog("   $k : $v"));

        // FIELDS
        request.fields.addAll({
          "type": mediaType == "image" ? "photo" : "video",
          "upload_id": uploadId,
          "chunk_index": i.toString(),
          "total_chunks": totalChunks.toString(),
          // "is_last_chunk": isLast ? "1" : "0",
        });

        // Add story metadata ONLY for the last chunk
        if (isLast) {
          request.fields.addAll({
            "route": route,
            "city": city,
            "description": description,
            "category": category,
          });
        }

        appLog("📄 Fields:");
        request.fields.forEach((k, v) => appLog("   $k : $v"));

        // // FILE: Attach every chunk (important fix)
        request.files.add(
          http.MultipartFile.fromBytes(
            "chunk", // MUST match backend
            bytes,
            filename: basename(file.path),
          ),
        );

        appLog("📎 Attaching FILE (chunk) | Files Count: ${request.files.length}");

        final response = await request.send();
        final responseBody = await response.stream.bytesToString();

        appLog("✅ RESPONSE RECEIVED");
        appLog("   ↳ Status Code  : ${response.statusCode}");
        appLog("   ↳ Response    : $responseBody");

        if (response.statusCode != 200 && response.statusCode != 201) {
          throw Exception("❌ Upload failed at chunk $i");
        }

        final percent = ((i + 1) / totalChunks) * 100;
        appLog("📊 Progress      : ${percent.toStringAsFixed(2)}%");

        onProgress(percent);

        appLog("──────────────────────────────────────");
      }

      raf.closeSync();
      await VideoCompress.deleteAllCache();

      appLog("🎉 STORY UPLOAD COMPLETED SUCCESSFULLY");
      appLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

      return true;
    } catch (e, st) {
      appLog("❌ STORY UPLOAD ERROR");
      appLog("❌ Error: $e");
      appLog("📛 StackTrace: $st");
      return false;
    }
  }


}
