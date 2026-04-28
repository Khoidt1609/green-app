// lib/features/tasks/providers/submission_provider.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/models/submission_model.dart';
import '../../../data/models/task_model.dart';

// ── Providers ──────────────────────────────────────────────────────────────────

/// Danh sách file ảnh đang chọn (tự reset khi sheet đóng)
final pickedImagesProvider =
    StateProvider.autoDispose<List<File>>((ref) => []);

/// Trạng thái đang upload / submit
final submissionLoadingProvider =
    StateProvider.autoDispose<bool>((ref) => false);

/// Service chính để thao tác ảnh & nộp bài
final submissionServiceProvider =
    Provider.autoDispose((ref) => SubmissionService(ref));

// ── Cloudinary config ──────────────────────────────────────────────────────────

const _cloudName = 'dfvtfibtx';
const _uploadPreset = 'greenstep_preset';
const _cloudinaryUrl =
    'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

// ── SubmissionService ──────────────────────────────────────────────────────────

class SubmissionService {
  SubmissionService(this._ref);

  final Ref _ref;
  final _picker = ImagePicker();
  final _dio = Dio();

  // ── Pick images ─────────────────────────────────────────────────────────────

  Future<void> pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final photo =
          await _picker.pickImage(source: source, imageQuality: 60);
      if (photo == null) return;
      _appendImages([File(photo.path)]);
    } else {
      final images = await _picker.pickMultiImage(imageQuality: 60);
      if (images.isEmpty) return;
      _appendImages(images.map((x) => File(x.path)).toList());
    }
  }

  void _appendImages(List<File> newFiles) {
    final current = _ref.read(pickedImagesProvider);
    _ref.read(pickedImagesProvider.notifier).state = [
      ...current,
      ...newFiles,
    ];
  }

  void removeImage(int index) {
    final current = [..._ref.read(pickedImagesProvider)];
    current.removeAt(index);
    _ref.read(pickedImagesProvider.notifier).state = current;
  }

  // ── Submit task ─────────────────────────────────────────────────────────────

  Future<bool> submitTask(TaskModel task, String note) async {
    final images = _ref.read(pickedImagesProvider);
    if (images.isEmpty) return false;

    _setLoading(true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      // 1. Upload ảnh lên Cloudinary
      final downloadUrls = await _uploadImages(images, user.uid);

      // 2. Lưu submission vào Firestore
      final submission = SubmissionModel(
        id: '',
        userId: user.uid,
        userName: user.displayName ??
            user.email?.split('@').first ??
            'Người dùng GreenStep',
        taskId: task.id,
        taskTitle: task.title,
        proofUrls: downloadUrls,
        pointsReward: task.pointsReward,
        createdAt: DateTime.now(),
      );

      final data = submission.toMap()
        ..['userNote'] = note.trim()
        ..['userEmail'] = user.email ?? '';

      await FirebaseFirestore.instance.collection('submissions').add(data);

      // 3. Reset ảnh đã chọn
      _ref.read(pickedImagesProvider.notifier).state = [];
      return true;
    } catch (_) {
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<List<String>> _uploadImages(
      List<File> images, String uid) async {
    final urls = <String>[];
    for (final image in images) {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(image.path),
        'upload_preset': _uploadPreset,
        'folder': 'greenstep/submissions/$uid',
      });
      final response = await _dio.post(_cloudinaryUrl, data: formData);
      if (response.statusCode == 200) {
        final url = response.data['secure_url'] as String?;
        if (url != null) urls.add(url);
      }
    }
    return urls;
  }

  void _setLoading(bool value) {
    _ref.read(submissionLoadingProvider.notifier).state = value;
  }
}