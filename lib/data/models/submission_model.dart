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
  final String? userNote;
  final DateTime createdAt;
  // MỚI: kết quả AI — đều optional, không ảnh hưởng code cũ
  final String? aiVerdict;
  final String? aiExplanation;
  final double? aiConfidence;

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
    this.userNote,
    required this.createdAt,
    // MỚI: optional, mặc định null
    this.aiVerdict,
    this.aiExplanation,
    this.aiConfidence,
  });

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
    String? userNote,
    DateTime? createdAt,
    String? aiVerdict,
    String? aiExplanation,
    double? aiConfidence,
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
      userNote: userNote ?? this.userNote,
      createdAt: createdAt ?? this.createdAt,
      aiVerdict: aiVerdict ?? this.aiVerdict,
      aiExplanation: aiExplanation ?? this.aiExplanation,
      aiConfidence: aiConfidence ?? this.aiConfidence,
    );
  }

  Map<String, dynamic> toMap() {
    // BUG FIX: Không ghi null vào Firestore — các field nullable chỉ
    // được thêm vào map khi thực sự có giá trị, tránh lỗi ghi document.
    final map = <String, dynamic>{
      'userId': userId,
      'taskId': taskId,
      'taskTitle': taskTitle,
      'userName': userName,
      'proofUrls': proofUrls,
      'pointsReward': pointsReward,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };

    // Các field nullable — chỉ ghi khi có giá trị
    if (userAvatar != null) map['userAvatar'] = userAvatar;
    if (adminNote != null) map['adminNote'] = adminNote;
    if (userNote != null && userNote!.isNotEmpty) map['userNote'] = userNote;

    // MỚI: field AI — chỉ ghi khi Gemini trả về kết quả thực sự
    if (aiVerdict != null) map['aiVerdict'] = aiVerdict;
    if (aiExplanation != null) map['aiExplanation'] = aiExplanation;
    if (aiConfidence != null) map['aiConfidence'] = aiConfidence;

    return map;
  }

  factory SubmissionModel.fromDocument(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return SubmissionModel(
      id: doc.id,
      userId: map['userId'] as String? ?? '',
      taskId: map['taskId'] as String? ?? '',
      taskTitle: map['taskTitle'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      userAvatar: map['userAvatar'] as String?,
      proofUrls: List<String>.from(map['proofUrls'] as List? ?? []),
      pointsReward: (map['pointsReward'] as num?)?.toInt() ?? 0,
      status: map['status'] as String? ?? 'pending',
      adminNote: map['adminNote'] as String?,
      userNote: map['userNote'] as String? ?? '',
      createdAt:
      (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      // MỚI: đọc từ Firestore, null nếu chưa có
      aiVerdict: map['aiVerdict'] as String?,
      aiExplanation: map['aiExplanation'] as String?,
      aiConfidence: (map['aiConfidence'] as num?)?.toDouble(),
    );
  }
}