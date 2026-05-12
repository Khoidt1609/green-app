import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

// Khai báo Provider để toàn app có thể gọi Service này
final imageUploadServiceProvider = Provider((ref) => ImageUploadService());

class ImageUploadService {
  final _picker = ImagePicker();
  final _dio = Dio();

  // Dùng chung cấu hình Cloudinary
  static const _cloudName = 'dfvtfibtx';
  static const _uploadPreset = 'greenstep_preset';
  static const _cloudinaryUrl = 'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  // Mở thư viện để chọn 1 ảnh
  Future<File?> pickSingleImage() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 60, // Nén ảnh giảm dung lượng
      );
      if (photo != null) return File(photo.path);
    } catch (e) {
      print("Lỗi chọn ảnh: $e");
    }
    return null;
  }

  // Upload ảnh lên Cloudinary và trả về URL
  Future<String?> uploadImage(File image, {String folder = 'greenstep/admin'}) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(image.path),
        'upload_preset': _uploadPreset,
        'folder': folder, // Thư mục lưu ảnh trên Cloudinary
      });

      final response = await _dio.post(_cloudinaryUrl, data: formData);

      if (response.statusCode == 200) {
        return response.data['secure_url'] as String?;
      }
    } catch (e) {
      print("Lỗi upload ảnh: $e");
    }
    return null;
  }
}