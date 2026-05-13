import 'package:cloud_firestore/cloud_firestore.dart';

class SubmissionModel {
  final String id;
  final String userId;
  final String taskId;
  final String taskTitle;
  final String userName;
  final String? userAvatar;
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
    required this.userAvatar,
    required this.proofUrls,
    required this.pointsReward,
    this.status = 'pending',
    this.adminNote,
    required this.createdAt,
  });

  // FIX: tên param đổi từ pointReward → pointsReward cho khớp field
  SubmissionModel copyWith({
    String? id,
    String? userId,
    String? taskId,
    String? taskTitle,
    String? userName,
    String? userAvatar,
    List<String>? proofUrls,
    int? pointsReward,
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
      userAvatar: userAvatar ?? this.userAvatar,
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
      'userAvatar': userAvatar,
      'proofUrls': proofUrls,
      'pointsReward': pointsReward,
      'status': status,
      'adminNote': adminNote,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // FIX: xóa print() debug
  factory SubmissionModel.fromDocument(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return SubmissionModel(
      id: doc.id,
      userId: map['userId'] as String? ?? '',
      taskId: map['taskId'] as String? ?? '',
      taskTitle: map['taskTitle'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      userAvatar: map['userAvatar'] as String? ?? '',
      proofUrls: List<String>.from(map['proofUrls'] as List? ?? []),
      pointsReward: (map['pointsReward'] as num?)?.toInt() ?? 0,
      status: map['status'] as String? ?? 'pending',
      adminNote: map['adminNote'] as String?,
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}