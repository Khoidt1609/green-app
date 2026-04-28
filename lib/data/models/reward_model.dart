// lib/data/models/reward_model.dart
//
// Chỉ chứa RewardItem.
// TransactionRecord đã bị xóa — dùng TransactionModel từ transaction_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class RewardItem {
  final String id;
  final String name;
  final String description;
  final int pointCost;
  final int valueVND;
  final String type; // 'cash' | 'voucher'
  final String? imageUrl;

  const RewardItem({
    required this.id,
    required this.name,
    required this.description,
    required this.pointCost,
    required this.valueVND,
    required this.type,
    this.imageUrl,
  });

  factory RewardItem.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return RewardItem(
      id: doc.id,
      name: d['name'] as String? ?? '',
      description: d['description'] as String? ?? '',
      pointCost: (d['pointCost'] as num?)?.toInt() ?? 0,
      valueVND: (d['valueVND'] as num?)?.toInt() ?? 0,
      type: d['type'] as String? ?? 'cash',
      imageUrl: d['imageUrl'] as String?,
    );
  }

  bool get isCash => type == 'cash';
}