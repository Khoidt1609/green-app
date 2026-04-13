import 'package:cloud_firestore/cloud_firestore.dart';
import 'bank_info_model.dart';
import 'user_model.dart'; // Bắt buộc phải có dòng này

class TransactionModel {
  final String id;
  final String userId;
  final String userName;
  final String? rewardId;
  final int amountVND;
  final String type;
  final String status;
  final BankInfoModel? bankDetails;
  final DateTime createdAt;
  final DateTime? paidAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.rewardId,
    required this.amountVND,
    required this.type,
    this.status = 'pending',
    this.bankDetails,
    required this.createdAt,
    this.paidAt,
  });

  TransactionModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? rewardId,
    int? amountVND,
    String? type,
    String? status,
    BankInfoModel? bankDetails,
    DateTime? createdAt,
    DateTime? paidAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      rewardId: rewardId ?? this.rewardId,
      amountVND: amountVND ?? this.amountVND,
      type: type ?? this.type,
      status: status ?? this.status,
      bankDetails: bankDetails ?? this.bankDetails,
      createdAt: createdAt ?? this.createdAt,
      paidAt: paidAt ?? this.paidAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'rewardId': rewardId,
      'amountVND': amountVND,
      'type': type,
      'status': status,
      'bankDetails': bankDetails?.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
    };
  }

  factory TransactionModel.fromDocument(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return TransactionModel(
      id: doc.id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      rewardId: map['rewardId'],
      amountVND: map['amountVND']?.toInt() ?? 0,
      type: map['type'] ?? 'earn',
      status: map['status'] ?? 'pending',
      bankDetails: map['bankDetails'] != null
          ? BankInfoModel.fromMap(map['bankDetails'] as Map<String, dynamic>)
          : null,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paidAt: (map['paidAt'] as Timestamp?)?.toDate(),
    );
  }
}