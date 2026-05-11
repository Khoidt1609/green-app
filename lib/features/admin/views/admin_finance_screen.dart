// Thay vì gọi trực tiếp AdminWithdrawalsTab, hãy dùng một Widget bao bọc có TabBar
import 'package:flutter/material.dart';
import 'package:green_app/features/admin/views/admin_reward_screen.dart';
import 'package:green_app/features/admin/views/admin_tasks_tab.dart';
import 'package:green_app/features/admin/views/admin_transaction_tab.dart';

import '../../../core/constants/app_colors.dart';

class AdminFinanceScreen extends StatelessWidget {
  const AdminFinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // 2 Tab con
      child: Scaffold(
        body:Column(
          children: [
            Container(
              color: Colors.white,
              child: const TabBar(
                labelColor: AppColors.primaryGreen,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.primaryGreen,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.receipt_long, size: 20),
                    text: "Yêu cầu rút tiền",
                  ),
                  Tab(
                    icon: Icon(Icons.card_giftcard, size: 20),
                    text: "Danh mục thưởng",
                  ),
                ],
              ),
            ),

            const Expanded(
              child: TabBarView(
                children: [
                  AdminTransactionsTab(),
                  AdminRewardsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}