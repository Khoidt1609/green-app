import 'package:cloud_firestore/cloud_firestore.dart';

class SubmissionModel {
  final String id;
  final String userId;
  final String taskId;
  final String taskTitle;
  final String userName;
  final List<String> proofUrls;
  final int pointsReward;
  final String status;
  final String? adminNote;
  final DateTime createdAt;

  SubmissionModel({
    required this.id,
    required this.userId,
    required this.taskId,
    required this.taskTitle,
    required this.userName,
    required this.proofUrls,
    required this.pointsReward,
    this.status = 'pending',
    this.adminNote,
    required this.createdAt,
  });

  SubmissionModel copyWith({
    String? id,
    String? userId,
    String? taskId,
    String? taskTitle,
    String? userName,
    List<String>? proofUrls,
    int? pointReward,
    String? status,
    String? adminNote,
    DateTime? createdAt,
  }) {
    return SubmissionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      taskId: taskId ?? this.taskId,
      taskTitle: taskTitle ?? this.taskTitle,
      userName: userName ?? this.userName,
      proofUrls: proofUrls ?? this.proofUrls,
      pointsReward: pointsReward ?? this.pointsReward,
      status: status ?? this.status,
      adminNote: adminNote ?? this.adminNote,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'taskId': taskId,
      'taskTitle': taskTitle,
      'userName': userName,
      'proofUrls': proofUrls,
      'pointsReward': pointsReward,
      'status': status,
      'adminNote': adminNote,
      // Chuyển DateTime của app thành Timestamp của Firebase
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory SubmissionModel.fromDocument(DocumentSnapshot doc) {
    print("Đang đọc document ID: ${doc.id}");
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return SubmissionModel(
      id: doc.id,
      userId: map['userId'] ?? '',
      taskId: map['taskId'] ?? '',
      taskTitle: map['taskTitle'] ?? '',
      userName: map['userName'] ?? '',
      // Ép kiểu mảng an toàn từ Firebase
      proofUrls: List<String>.from(map['proofUrls'] ?? []),
      pointsReward: map['pointsReward'] ?? 0,
      status: map['status'] ?? 'pending',
      adminNote: map['adminNote'],
      // Chuyển Timestamp của Firebase thành DateTime cho app dễ dùng
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}