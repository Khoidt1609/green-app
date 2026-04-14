import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/submission_model.dart';
import 'dart:typed_data';


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
    // [GIAI ĐOẠN 1]: KIỂM TRA ĐẦU VÀO
    final images = ref.read(pickedImagesProvider);
    if (images.isEmpty) return false;

    // Kích hoạt vòng xoay Loading trên UI
    ref.read(submissionLoadingProvider.notifier).state = true;

    try {
      // [GIAI ĐOẠN 2]: XÁC THỰC NGƯỜI DÙNG
      User? currentUser = FirebaseAuth.instance.currentUser;

      // Fallback: Tự động cấp quyền nếu đang test mà chưa đăng nhập
      if (currentUser == null) {
        print(">>> Hệ thống: Đang cấp quyền ẩn danh để test...");
        await FirebaseAuth.instance.signInAnonymously();
        currentUser = FirebaseAuth.instance.currentUser;
      }

      // Đặt biến UID mặc định là tài khoản thật của Bin nếu chạy ẩn danh
      String currentUid = currentUser?.uid ?? 'zX8uGGc0S0bItRhIsjppimhULdH2';
      String currentEmail = currentUser?.email ?? 'bin05062006@gmail.com';
      String currentName = currentUser?.displayName ?? 'Bin (bin05062006)';

      // [GIAI ĐOẠN 3]: UPLOAD ẢNH (Bảo mật 404)
      List<String> downloadUrls = [];

      for (int i = 0; i < images.length; i++) {
        // Tạo đường dẫn riêng biệt cho từng ảnh của user
        String fileName = 'submissions/$currentUid/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        Reference refStorage = FirebaseStorage.instance.ref().child(fileName);

        // THUẬT TOÁN BĂM BYTE: Ép máy ảo đọc file vật lý trước khi đẩy
        Uint8List fileBytes = await images[i].readAsBytes();

        print(">>> Đang đẩy ảnh $i lên máy chủ...");
        TaskSnapshot snapshot = await refStorage.putData(fileBytes);

        // Chỉ lấy link khi hệ thống xác nhận đã lưu xong 100%
        String url = await snapshot.ref.getDownloadURL();
        downloadUrls.add(url);
      }

      // [GIAI ĐOẠN 4]: ĐÓNG GÓI VÀ LƯU DATABASE GỐC
      final submission = SubmissionModel(
        id: '',
        userId: currentUid,
        userName: currentName,
        taskId: task.id,
        taskTitle: task.title,
        proofUrls: downloadUrls, // Mảng chứa các link ảnh đã upload
        pointsReward: task.pointsReward,
        createdAt: DateTime.now(),
      );

      // Chuyển Model thành Map để chuẩn bị lưu
      Map<String, dynamic> dataToSave = submission.toMap();

      // Bổ sung các trường Extra theo thiết kế ban đầu của bạn
      dataToSave['userNote'] = note;
      dataToSave['userEmail'] = currentEmail;

      // Thực thi lưu vào Firestore
      print("Đang ghi nhận dữ liệu vào CSDL...");
      await FirebaseFirestore.instance.collection('submissions').add(dataToSave);

      print("HOÀN TẤT: Nhiệm vụ cuối cùng đã thành công rực rỡ!");

      // Dọn dẹp RAM: Xóa ảnh đã chọn trên màn hình
      ref.read(pickedImagesProvider.notifier).state = [];
      return true;

    } catch (e) {
      // báo đỏ về UI
      print("LỖI HỆ THỐNG CRITICAL: $e");
      return false;
    } finally {
      // Luôn tắt vòng xoay Loading dù kết quả ra sao
      ref.read(submissionLoadingProvider.notifier).state = false;
    }
  }
}
