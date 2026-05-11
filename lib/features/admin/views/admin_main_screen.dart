import 'package:flutter/material.dart';
import 'package:green_app/core/constants/app_colors.dart';
import 'package:green_app/core/constants/app_text_styles.dart';
import 'package:green_app/features/admin/views/admin_finance_screen.dart';
import 'package:green_app/features/admin/views/admin_tasks_tab.dart';
import 'package:green_app/features/admin/views/admin_transaction_tab.dart';
import 'admin_submissions_tab.dart'; // Tab mình sẽ vẽ chi tiết bên dưới
import 'package:green_app/features/admin/views/admin_users_tab.dart';
class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const AdminSubmissionsTab(), // Tab Duyệt bài
    const AdminTasksTab(),
    const AdminUsersTab(),
    const AdminFinanceScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDarkGreen,
        title: Row(
          children: [
            Container(
              height: 35,
              width: 35,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.eco_outlined, color: Colors.white, size: 30,),
            ),
            SizedBox(width: 10,),
            Text('Quản Trị Viên', style: AppTextStyles.headingWhite,)
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close), // Nút thoát về giao diện User
          onPressed: () => Navigator.pop(context),
        ),
        
      ),
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (val) => setState(() => _currentIndex = val),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fact_check),
            label: "Duyệt bài",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.task), label: "Nhiệm vụ"),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: "Người dùng",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments),
            label: "Tài chính",
          ),
        ],
      ),
    );
  }
}
