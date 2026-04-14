import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/models/task_model.dart';
import '../../../../router/app_router.dart';
import '../widgets/task_card.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  int _currentTab = 2;
  String selectedCategory = 'Tất cả';

  void _onTapBottomNav(int index) {
    if (_currentTab == index) {
      return;
    }

    switch (index) {
      case 0:
        setState(() {
          _currentTab = index;
        });
        Navigator.of(context).pushReplacementNamed(AppRouter.home);
        break;
      case 1:
        break;
      case 2:
        setState(() {
          _currentTab = index;
        });
        break;
      case 3:
        break;
      case 4:
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          // Lấy toàn bộ nhiệm vụ đang hoạt động từ Firebase
          stream: FirebaseFirestore.instance
              .collection('tasks')
              .where('isActive', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryGreen),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('Không có dữ liệu nhiệm vụ.'));
            }

            //Chuyển đổi dữ liệu sang List<TaskModel>
            final allTasks = snapshot.data!.docs
                .map((doc) => TaskModel.fromDocument(doc))
                .toList();

            // Lấy danh sách Category
            final Set<String> dbCategories = allTasks
                .map((t) => t.category)
                .toSet();
            final List<String> categories = dbCategories.toList()..sort();
            categories.insert(0, 'Tất cả');
            //Lọc nhiệm vụ
            final filteredTasks = selectedCategory == 'Tất cả'
                ? allTasks
                : allTasks
                      .where((t) => t.category == selectedCategory)
                      .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GREENSTEP',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primaryDarkGreen,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hành Động Xanh',
                        style: AppTextStyles.heading1.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Thanh tìm kiếm
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm nhiệm vụ...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.textSecondary,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

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
                            onTap: () => setState(
                              () => selectedCategory = categories[index],
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryGreen
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                categories[index],
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black54,
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
                  child: GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentTab,
          onTap: _onTapBottomNav,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.primaryGreen,
          unselectedItemColor: AppColors.textSecondary,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined),
              label: 'Rank',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.task_alt_outlined),
              label: 'Tasks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              label: 'Store',
            ),
          ],
        ),
      ),
    );
  }
}
