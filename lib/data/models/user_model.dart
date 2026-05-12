import 'package:cloud_firestore/cloud_firestore.dart';

import 'address_model.dart';
import 'bank_info_model.dart';

class UserModel {
  final String uid;
  final String displayName;
  final String username;
  final String email;
  final String avatarUrl;
  final String provider;

  final AddressModel address;

  final int totalPoints;
  final int currentPoints;
  final int weekPoints;
  final int monthPoints;

  final String role;

  final BankInfoModel? bankInfo;

  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const UserModel({
    required this.uid,
    required this.displayName,
    required this.username,
    required this.email,
    required this.avatarUrl,
    required this.provider,
    required this.address,
    this.totalPoints = 0,
    this.currentPoints = 0,
    this.weekPoints = 0,
    this.monthPoints = 0,
    this.role = 'user',
    this.bankInfo,
    this.createdAt,
    this.updatedAt,
  });

  // =========================================================
  // COPY WITH
  // =========================================================

  UserModel copyWith({
    String? uid,
    String? displayName,
    String? username,
    String? email,
    String? avatarUrl,
    String? provider,
    AddressModel? address,
    int? totalPoints,
    int? currentPoints,
    int? weekPoints,
    int? monthPoints,
    String? role,
    BankInfoModel? bankInfo,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      provider: provider ?? this.provider,
      address: address ?? this.address,
      totalPoints: totalPoints ?? this.totalPoints,
      currentPoints: currentPoints ?? this.currentPoints,
      weekPoints: weekPoints ?? this.weekPoints,
      monthPoints: monthPoints ?? this.monthPoints,
      role: role ?? this.role,
      bankInfo: bankInfo ?? this.bankInfo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // =========================================================
  // TO MAP
  // =========================================================

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'username': username,
      'email': email,
      'avatarUrl': avatarUrl,
      'provider': provider,

      'address': address.toMap(),

      'totalPoints': totalPoints,
      'currentPoints': currentPoints,
      'weekPoints': weekPoints,
      'monthPoints': monthPoints,

      'role': role,

      'bankInfo': bankInfo?.toMap(),

      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // =========================================================
  // FROM DOCUMENT
  // =========================================================

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};

    return UserModel(
      uid: map['uid'] ?? doc.id,

      displayName: map['displayName'] ?? 'Người dùng',

      username: map['username'] ?? '',

      email: map['email'] ?? '',

      avatarUrl: map['avatarUrl'] ?? '',

      provider: map['provider'] ?? 'email_password',

      address: AddressModel.fromMap(
        map['address'] as Map<String, dynamic>?,
      ),

      totalPoints: (map['totalPoints'] ?? 0).toInt(),

      currentPoints: (map['currentPoints'] ?? 0).toInt(),

      weekPoints: (map['weekPoints'] ?? 0).toInt(),

      monthPoints: (map['monthPoints'] ?? 0).toInt(),

      role: map['role'] ?? 'user',

      bankInfo: map['bankInfo'] != null
          ? BankInfoModel.fromMap(
              map['bankInfo'] as Map<String, dynamic>,
            )
          : null,

      createdAt: map['createdAt'] as Timestamp?,

      updatedAt: map['updatedAt'] as Timestamp?,
    );
  }

  // =========================================================
  // FROM MAP
  // =========================================================

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',

      displayName: map['displayName'] ?? 'Người dùng',

      username: map['username'] ?? '',

      email: map['email'] ?? '',

      avatarUrl: map['avatarUrl'] ?? '',

      provider: map['provider'] ?? 'email_password',

      address: AddressModel.fromMap(
        map['address'] as Map<String, dynamic>?,
      ),

      totalPoints: (map['totalPoints'] ?? 0).toInt(),

      currentPoints: (map['currentPoints'] ?? 0).toInt(),

      weekPoints: (map['weekPoints'] ?? 0).toInt(),

      monthPoints: (map['monthPoints'] ?? 0).toInt(),

      role: map['role'] ?? 'user',

      bankInfo: map['bankInfo'] != null
          ? BankInfoModel.fromMap(
              map['bankInfo'] as Map<String, dynamic>,
            )
          : null,

      createdAt: map['createdAt'] as Timestamp?,

      updatedAt: map['updatedAt'] as Timestamp?,
    );
  }

  // =========================================================
  // EMPTY
  // =========================================================

  factory UserModel.empty() {
    return UserModel(
      uid: '',
      displayName: '',
      username: '',
      email: '',
      avatarUrl: '',
      provider: 'email_password',
      address: AddressModel.empty(),
      totalPoints: 0,
      currentPoints: 0,
      weekPoints: 0,
      monthPoints: 0,
      role: 'user',
    );
  }

  // =========================================================
  // HELPERS
  // =========================================================

  bool get hasAvatar => avatarUrl.trim().isNotEmpty;

  bool get isAdmin => role == 'admin';

  String get fullAddress {
    final city = address.city.trim();
    final district = address.district.trim();

    if (city.isEmpty && district.isEmpty) {
      return '';
    }

    if (city.isEmpty) {
      return district;
    }

    if (district.isEmpty) {
      return city;
    }

    return '$district, $city';
  }

  @override
  String toString() {
    return 'UserModel('
        'uid: $uid, '
        'displayName: $displayName, '
        'username: $username, '
        'email: $email'
        ')';
  }
}