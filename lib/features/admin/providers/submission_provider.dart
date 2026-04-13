// Khởi tạo Repository
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/submission_model.dart';
import '../../../data/repositories/admin_repository.dart';

final adminRepoProvider = Provider((ref) => AdminRepository());
// Lưu trữ trạng thái bộ lọc
final statusFilterProvider = StateProvider<String>((ref) => 'pending');

//  Lưu trữ từ khóa tìm kiếm
final searchQueryProvider = StateProvider<String>((ref) => '');

// Stream tự động đẩy danh sách ra màn hình
final submissionsStreamProvider = StreamProvider<List<SubmissionModel>>((ref) {
  final repo = ref.watch(adminRepoProvider);
  final status = ref.watch(statusFilterProvider);
  return repo.getSubmissions(status);
});

final filteredSubmissionsProvider = Provider<AsyncValue<List<SubmissionModel>>>((ref) {
  final asyncList = ref.watch(submissionsStreamProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  return asyncList.whenData((list) {
    if (query.isEmpty) return list; // Nếu không gõ gì thì trả về toàn bộ

    // Lọc
    return list.where((sub) {
      // 2 trường userName và taskTitle
      return sub.userName.toLowerCase().contains(query) ||
          sub.taskTitle.toLowerCase().contains(query);
    }).toList();
  });
});
