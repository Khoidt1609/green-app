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

class TransactionRecord {
  final String id;
  final String rewardId;
  final String rewardName;
  final int pointCost;
  final int amountVND;
  final String type;
  final String status; // pending | completed | cancelled
  final DateTime createdAt;
  final DateTime? paidAt;

  const TransactionRecord({
    required this.id,
    required this.rewardId,
    required this.rewardName,
    required this.pointCost,
    required this.amountVND,
    required this.type,
    required this.status,
    required this.createdAt,
    this.paidAt,
  });

  factory TransactionRecord.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TransactionRecord(
      id: doc.id,
      rewardId: d['rewardId'] as String? ?? '',
      rewardName: d['rewardName'] as String? ?? '',
      pointCost: (d['pointCost'] as num?)?.toInt() ?? 0,
      amountVND: (d['amountVND'] as num?)?.toInt() ?? 0,
      type: d['type'] as String? ?? 'redeem',
      status: d['status'] as String? ?? 'pending',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paidAt: (d['paidAt'] as Timestamp?)?.toDate(),
    );
  }

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
}
