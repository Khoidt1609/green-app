import 'package:cloud_firestore/cloud_firestore.dart';

class RewardModel {
  final String id;
  final String name;
  final String description;
  final int pointCost;
  final int valueVND;
  final String type;
  final String imageUrl;

  RewardModel({
    required this.id,
    required this.name,
    required this.description,
    required this.pointCost,
    required this.valueVND,
    required this.type,
    required this.imageUrl,
  });

  RewardModel copyWith({
    String? id,
    String? name,
    String? description,
    int? pointCost,
    int? valueVND,
    String? type,
    String? imageUrl,
  }) {
    return RewardModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      pointCost: pointCost ?? this.pointCost,
      valueVND: valueVND ?? this.valueVND,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'pointCost': pointCost,
      'valueVND': valueVND,
      'type': type,
      'imageUrl': imageUrl,
    };
  }

  factory RewardModel.fromDocument(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return RewardModel(
      id: doc.id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      pointCost: map['pointCost']?.toInt() ?? 0,
      valueVND: map['valueVND']?.toInt() ?? 0,
      type: map['type'] ?? 'cash',
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}