import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/models/task_model.dart';
import '../widgets/task_card.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {

//Search
  final TextEditingController _searchController = TextEditingController();

  // Giải phóng bộ nhớ khi không dùng nữa
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  String selectedCategory = 'Tất cả';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      //  AppBar
      appBar: AppBar(
        title: const Text(
          'Nhiệm vụ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.primaryGreen,
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ĐÃ XÓA: Phần Padding chứa text "Greenstep - Hành động xanh" đã được bỏ đi để dùng AppBar bên trên

            // Thanh tìm kiếm
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm nhiệm vụ...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                ),
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // Lấy toàn bộ nhiệm vụ đang hoạt động từ Firebase
                stream: FirebaseFirestore.instance
                    .collection('tasks')
                    .where('isActive', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('Không có dữ liệu nhiệm vụ.'));
                  }

                  //Chuyển đổi dữ liệu sang List<TaskModel>
                  final allTasks = snapshot.data!.docs
                      .map((doc) => TaskModel.fromDocument(doc))
                      .toList();

                  // Lấy danh sách Category
                  final Set<String> dbCategories = allTasks.map((t) => t.category).toSet();
                  final List<String> categories = dbCategories.toList()..sort();
                  categories.insert(0, 'Tất cả');

                  //Lọc nhiệm vụ
                  final searchTerms = _searchController.text.toLowerCase().trim().split(' ');
                  final filteredTasks = allTasks.where((task) {
                    final bool matchesActive = task.isActive;
                    final bool matchesCategory = selectedCategory == 'Tất cả' || task.category == selectedCategory;
                    final bool matchesSearch = searchTerms.every((term) {
                      return task.title.toLowerCase().contains(term);
                    });

                    return matchesActive && matchesCategory && matchesSearch;
                  }).toList();

                  return Column(
                    children: [
                      // Thanh lọc Category
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            bool isSelected = selectedCategory == categories[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: SizedBox(
                                width: 105,
                                child: GestureDetector(
                                  onTap: () => setState(() => selectedCategory = categories[index]),
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.primaryGreen : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade300),
                                    ),
                                    child: Text(
                                      categories[index],
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.black54,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Lưới hiển thị nhiệm vụ
                      Expanded(
                        child: filteredTasks.isEmpty
                            ? const Center(
                          child: Text(
                            'Chưa có nhiệm vụ phù hợp',
                            style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                          ),
                        )
                            : GridView.builder(
                          padding: const EdgeInsets.all(20),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.65,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: filteredTasks.length,
                          itemBuilder: (context, index) {
                            return TaskCard(task: filteredTasks[index]);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}