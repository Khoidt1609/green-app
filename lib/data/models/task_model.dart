import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final int pointsReward;
  final String category;
  final String imageUrl;
  final bool isActive;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsReward,
    required this.category,
    required this.imageUrl,
    this.isActive = true,
  });

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    int? pointsReward,
    String? category,
    String? imageUrl,
    bool? isActive,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      pointsReward: pointsReward ?? this.pointsReward,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'pointsReward': pointsReward,
      'category': category,
      'imageUrl': imageUrl,
      'isActive': isActive,
    };
  }

  factory TaskModel.fromDocument(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return TaskModel(
      id: doc.id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      pointsReward: map['pointsReward']?.toInt() ?? 0,
      category: map['category'] ?? 'Khác',
      imageUrl: map['imageUrl'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }
}