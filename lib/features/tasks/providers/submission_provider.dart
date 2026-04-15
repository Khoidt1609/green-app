import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/submission_model.dart';
import 'package:dio/dio.dart';


// Quản lý file ảnh đang được chọn
final pickedImagesProvider = StateProvider.autoDispose<List<File>>((ref) => []);

// Quản lý trạng thái loading khi đang upload
final submissionLoadingProvider = StateProvider.autoDispose<bool>((ref) => false);

// Provider chính để thao tác
final submissionServiceProvider = Provider.autoDispose((ref) => SubmissionService(ref));

class SubmissionService {
  final Ref ref;

  SubmissionService(this.ref);

  final ImagePicker _picker = ImagePicker();

  // Mở Camera hoặc Bộ sưu tập
  Future<void> pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final XFile? photo = await _picker.pickImage(
          source: source, imageQuality: 60);
      if (photo != null) {
        final currentImages = ref.read(pickedImagesProvider);
        ref
            .read(pickedImagesProvider.notifier)
            .state = [...currentImages, File(photo.path)];
      }
    } else {
      final List<XFile> images = await _picker.pickMultiImage(imageQuality: 60);
      if (images.isNotEmpty) {
        final currentImages = ref.read(pickedImagesProvider);
        ref
            .read(pickedImagesProvider.notifier)
            .state = [
          ...currentImages,
          ...images.map((img) => File(img.path))
        ];
      }
    }
  }

  void removeImage(int index) {
    final currentImages = [...ref.read(pickedImagesProvider)];
    currentImages.removeAt(index);
    ref
        .read(pickedImagesProvider.notifier)
        .state = currentImages;
  }

  // Xử lý Upload và Lưu Database
  Future<bool> submitTask(TaskModel task, String note) async {
    final images = ref.read(pickedImagesProvider);
    if (images.isEmpty) return false;

    ref
        .read(submissionLoadingProvider.notifier)
        .state = true;

    try {
      // 1. LẤY THÔNG TIN USER ĐANG ĐĂNG NHẬP
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print(">>> Lỗi: Bạn cần đăng nhập để nộp bài!");
        return false;
      }

      // 2. THÔNG SỐ CLOUDINARY (Nhóm tự điền thông tin của mình nhé)
      const String cloudName = "dfvtfibtx";
      const String uploadPreset = "greenstep_preset";
      const String cloudinaryUrl = "https://api.cloudinary.com/v1_1/$cloudName/image/upload";

      List<String> downloadUrls = [];
      final dio = Dio();

      // 3. THUẬT TOÁN UPLOAD ẢNH
      for (var image in images) {
        FormData formData = FormData.fromMap({
          "file": await MultipartFile.fromFile(image.path),
          "upload_preset": uploadPreset,
          "folder": "greenstep/submissions/${user.uid}",
          // Phân loại ảnh theo UID thật
        });

        var response = await dio.post(cloudinaryUrl, data: formData);
        if (response.statusCode == 200) {
          downloadUrls.add(response.data['secure_url']);
        }
      }

      // 4. LƯU VÀO FIRESTORE (Khớp 100% các trường bạn yêu cầu)
      final submission = SubmissionModel(
        id: '',
        userId: user.uid,
        // Sử dụng UID từ Firebase Auth
        userName: user.displayName ?? user.email?.split('@')[0] ??
            'Người dùng GreenStep',
        taskId: task.id,
        taskTitle: task.title,
        proofUrls: downloadUrls,
        pointsReward: task.pointsReward,
        createdAt: DateTime.now(),
      );

      Map<String, dynamic> dataToSave = submission.toMap();
      dataToSave['userNote'] = note;
      dataToSave['userEmail'] =
          user.email; // Lưu email thật để thầy cô dễ kiểm tra

      await FirebaseFirestore.instance.collection('submissions').add(
          dataToSave);

      print(">>> THÀNH CÔNG: Bài nộp của ${user.email} đã lên hệ thống!");
      ref
          .read(pickedImagesProvider.notifier)
          .state = [];
      return true;
    } catch (e) {
      print("❌ LỖI HỆ THỐNG: $e");
      return false;
    } finally {
      ref
          .read(submissionLoadingProvider.notifier)
          .state = false;
    }
  }
}