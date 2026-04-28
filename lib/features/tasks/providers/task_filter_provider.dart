import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/task_model.dart';
import '../../../../data/providers/firebase_providers.dart';
// Category đang chọn (mặc định là 'Tất cả')
final selectedCategoryProvider = StateProvider<String>((ref) => 'Tất cả');
// tnội dung thanh tìm kiếm
final searchQueryProvider = StateProvider<String>((ref) => '');
// logic lọc
final filteredTasksProvider = Provider<List<TaskModel>>((ref) {
  //dữ liệu thô từ Data Provider
  final snapshot = ref.watch(rawTasksStreamProvider).value;
  if (snapshot == null) return [];
// Chuyển đổi sang List Model
  final allTasks = snapshot.docs.map((doc) => TaskModel.fromDocument(doc)).toList();
// Đọc trạng thái lọc hiện tại
  final category = ref.watch(selectedCategoryProvider);
  final search = ref.watch(searchQueryProvider).toLowerCase().trim();
  final searchTerms = search.split(' ');
// Thực hiện logic lọc
  return allTasks.where((task) {
    final matchesCategory = category == 'Tất cả' || task.category == category;
    final matchesSearch = searchTerms.every((term) => task.title.toLowerCase().contains(term));
    return task.isActive && matchesCategory && matchesSearch;
  }).toList();
});
// Lấy danh sách Category từ database
final categoryListProvider = Provider<List<String>>((ref) {
  final snapshot = ref.watch(rawTasksStreamProvider).value;
  if (snapshot == null) return ['Tất cả'];

  final allTasks = snapshot.docs.map((doc) => TaskModel.fromDocument(doc)).toList();
  final Set<String> dbCategories = allTasks.map((t) => t.category).toSet();
  final List<String> categories = dbCategories.toList()..sort();
  categories.insert(0, 'Tất cả');
  return categories;
});