// lib/features/tasks/providers/submission_provider.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/gemini_service.dart';
import '../../../data/models/submission_model.dart';
import '../../../data/models/task_model.dart';

// Danh sách file ảnh đang chọn (tự reset khi sheet đóng)
final pickedImagesProvider =
StateProvider.autoDispose<List<File>>((ref) => []);

// Trạng thái đang upload / submit
final submissionLoadingProvider =
StateProvider.autoDispose<bool>((ref) => false);

// MỚI: Gemini đang phân tích ảnh
final isAnalyzingProvider =
StateProvider.autoDispose<bool>((ref) => false);

// MỚI: Kết quả phân tích của Gemini
final aiAnalysisResultProvider =
StateProvider.autoDispose<GeminiAnalysisResult?>((ref) => null);

// Service chính để thao tác ảnh & nộp bài
final submissionServiceProvider =
Provider.autoDispose((ref) => SubmissionService(ref));

// Cloudinary config
const _cloudName = 'dfvtfibtx';
const _uploadPreset = 'greenstep_preset';
const _cloudinaryUrl =
    'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

class SubmissionService {
  SubmissionService(this._ref);

  final Ref _ref;
  final _picker = ImagePicker();
  final _dio = Dio();

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
    _ref.read(aiAnalysisResultProvider.notifier).state = null;
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
    _ref.read(aiAnalysisResultProvider.notifier).state = null;
  }

  Future<bool> submitTask(TaskModel task, String note) async {
    final images = _ref.read(pickedImagesProvider);
    if (images.isEmpty) return false;

    _setLoading(true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      // Check duplicate
      final existing = await FirebaseFirestore.instance
          .collection('submissions')
          .where('userId', isEqualTo: user.uid)
          .where('taskId', isEqualTo: task.id)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        _setLoading(false);
        return false;
      }

      // Gemini phân tích ảnh
      GeminiAnalysisResult aiResult = GeminiAnalysisResult.error();
      try {
        _ref.read(isAnalyzingProvider.notifier).state = true;
        aiResult = await GeminiService().analyzeSubmission(
          imageFile: images.first,
          taskTitle: task.title,
          taskDescription: task.description,
        );
        _ref.read(aiAnalysisResultProvider.notifier).state = aiResult;
      } catch (e) {
        print('[Gemini] Lỗi, bỏ qua: $e');
      } finally {
        _ref.read(isAnalyzingProvider.notifier).state = false;
      }

      // Upload ảnh lên Cloudinary
      final downloadUrls = await _uploadImages(images, user.uid);

      // FIX: Đọc avatarUrl trực tiếp từ Firestore thay vì dùng
      // currentUserProvider.future (StreamProvider hay bị treo)
      String? avatarUrl;
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        avatarUrl = userDoc.data()?['avatarUrl'] as String?;
      } catch (e) {
        print('[submitTask] Không lấy được avatarUrl, dùng null: $e');
      }

      // Lưu vào Firestore
      final submission = SubmissionModel(
        id: '',
        userId: user.uid,
        userName: user.displayName ??
            user.email?.split('@').first ??
            'Người dùng GreenStep',
        userAvatar: avatarUrl,
        taskId: task.id,
        taskTitle: task.title,
        proofUrls: downloadUrls,
        pointsReward: task.pointsReward,
        userNote: note.trim(),
        createdAt: DateTime.now(),
        aiVerdict: aiResult.verdict,
        aiExplanation: aiResult.explanation,
        aiConfidence: aiResult.confidence,
      );

      final data = submission.toMap()
        ..['userEmail'] = user.email ?? '';

      await FirebaseFirestore.instance
          .collection('submissions')
          .add(data);

      _ref.read(pickedImagesProvider.notifier).state = [];
      return true;
    } catch (e) {
      print('[submitTask] Lỗi: $e');
      return false;
    } finally {
      _ref.read(isAnalyzingProvider.notifier).state = false;
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