import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import 'package:lifeboard/models/task_model.dart';

/// Service for uploading files/images to Firebase Storage and returning
/// [Attachment] models ready to persist on a task document.
class StorageService {
  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;
  final ImagePicker _imagePicker = ImagePicker();

  /// Max file size: 10 MB.
  static const int maxFileSize = 10 * 1024 * 1024;

  // ── Image picking ────────────────────────────────────────────

  /// Pick an image from the camera.
  Future<XFile?> pickImageFromCamera() async {
    return _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
  }

  /// Pick an image from the gallery.
  Future<XFile?> pickImageFromGallery() async {
    return _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
  }

  /// Pick a file from the device.
  Future<PlatformFile?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'png', 'jpg', 'jpeg'],
      withData: kIsWeb, // On web we need bytes
    );
    if (result == null || result.files.isEmpty) return null;
    return result.files.first;
  }

  // ── Uploading ────────────────────────────────────────────────

  /// Uploads an [XFile] (image) to Firebase Storage under the task's path.
  /// Returns an [Attachment] with the download URL.
  Future<Attachment> uploadImage({
    required String spaceId,
    required String taskId,
    required XFile file,
  }) async {
    final length = await file.length();
    if (length > maxFileSize) {
      throw Exception(
        'File too large (${(length / 1024 / 1024).toStringAsFixed(1)} MB). '
        'Maximum allowed size is ${maxFileSize ~/ 1024 ~/ 1024} MB.',
      );
    }

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final ref = _storage.ref('spaces/$spaceId/tasks/$taskId/$fileName');

    UploadTask uploadTask;
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      uploadTask = ref.putData(bytes, SettableMetadata(contentType: file.mimeType));
    } else {
      uploadTask = ref.putFile(File(file.path));
    }

    final snapshot = await uploadTask;
    final url = await snapshot.ref.getDownloadURL();

    return Attachment(
      url: url,
      type: _typeFromName(file.name),
      name: file.name,
    );
  }

  /// Uploads a [PlatformFile] to Firebase Storage under the task's path.
  /// Returns an [Attachment] with the download URL.
  Future<Attachment> uploadFile({
    required String spaceId,
    required String taskId,
    required PlatformFile file,
  }) async {
    final fileSize = file.size;
    if (fileSize > maxFileSize) {
      throw Exception(
        'File too large (${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB). '
        'Maximum allowed size is ${maxFileSize ~/ 1024 ~/ 1024} MB.',
      );
    }

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final ref = _storage.ref('spaces/$spaceId/tasks/$taskId/$fileName');

    UploadTask uploadTask;
    if (kIsWeb && file.bytes != null) {
      uploadTask = ref.putData(file.bytes!);
    } else if (file.path != null) {
      uploadTask = ref.putFile(File(file.path!));
    } else {
      throw Exception('No file data available for upload');
    }

    final snapshot = await uploadTask;
    final url = await snapshot.ref.getDownloadURL();

    return Attachment(
      url: url,
      type: _typeFromName(file.name),
      name: file.name,
    );
  }

  /// Deletes a file from Firebase Storage by its download URL.
  Future<void> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('[StorageService] Failed to delete file: $e');
    }
  }

  // ── Helpers ──────────────────────────────────────────────────

  String _typeFromName(String name) {
    final ext = name.split('.').last.toLowerCase();
    const imageExts = {'png', 'jpg', 'jpeg', 'gif', 'webp', 'heic'};
    if (imageExts.contains(ext)) return 'image';
    return 'file';
  }
}

/// Provides the [StorageService] singleton.
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
