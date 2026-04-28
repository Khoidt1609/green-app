import 'package:cloud_firestore/cloud_firestore.dart';
import 'address_model.dart';
import 'bank_info_model.dart';

class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final AddressModel address;
  final int totalPoints;
  final int currentPoints;
  final int weekPoints;
  final int monthPoints;
  final String role;
  final BankInfoModel? bankInfo;

  UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.address,
    this.totalPoints = 0,
    this.currentPoints = 0,
    this.weekPoints = 0,
    this.monthPoints = 0,
    this.role = 'user',
    this.bankInfo,
  });

  UserModel copyWith({
    String? uid,
    String? displayName,
    String? email,
    AddressModel? address,
    int? totalPoints,
    int? currentPoints,
    int? weekPoints,
    int? monthPoints,
    String? role,
    BankInfoModel? bankInfo,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      address: address ?? this.address,
      totalPoints: totalPoints ?? this.totalPoints,
      currentPoints: currentPoints ?? this.currentPoints,
      weekPoints: weekPoints ?? this.weekPoints,
      monthPoints: monthPoints ?? this.monthPoints,
      role: role ?? this.role,
      bankInfo: bankInfo ?? this.bankInfo,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'address': address.toMap(),
      'totalPoints': totalPoints,
      'currentPoints': currentPoints,
      'weekPoints': weekPoints,
      'monthPoints': monthPoints,
      'role': role,
      'bankInfo': bankInfo?.toMap(),
    };
  }

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      displayName: map['displayName'] ?? 'Người dùng',
      email: map['email'] ?? '',
      address: AddressModel.fromMap(map['address'] as Map<String, dynamic>?),
      totalPoints: map['totalPoints']?.toInt() ?? 0,
      currentPoints: map['currentPoints']?.toInt() ?? 0,
      weekPoints: map['weekPoints']?.toInt() ?? 0,
      monthPoints: map['monthPoints']?.toInt() ?? 0,
      role: map['role'] ?? 'user',
      bankInfo: map['bankInfo'] != null
          ? BankInfoModel.fromMap(map['bankInfo'] as Map<String, dynamic>)
          : null,
    );
  }
}