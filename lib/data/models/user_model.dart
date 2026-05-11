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

// --- 1. XỬ LÝ AN TOÀN CHO ADDRESS ---
AddressModel parsedAddress = AddressModel(district: '', city: '');
final addressRaw = map['address'];

if (addressRaw is Map<String, dynamic>) {
// Nếu dữ liệu chuẩn là Map
parsedAddress = AddressModel.fromMap(addressRaw);
} else if (addressRaw is List && addressRaw.isNotEmpty) {
// Nếu dữ liệu bị lưu nhầm thành List (ví dụ: ['Quận', 'Thành phố'])
String d = '';
String c = '';
if (addressRaw[0] is String) d = addressRaw[0];
if (addressRaw.length > 1 && addressRaw[1] is String) c = addressRaw[1];
parsedAddress = AddressModel(district: d, city: c);
} else if (addressRaw is String) {
// Nếu dữ liệu bị lưu thành String (ví dụ: "Đà Nẵng")
parsedAddress = AddressModel(district: addressRaw, city: '');
}

// --- 2. XỬ LÝ AN TOÀN CHO BANK INFO ---
BankInfoModel? parsedBankInfo;
final bankRaw = map['bankInfo'];

if (bankRaw is Map<String, dynamic>) {
parsedBankInfo = BankInfoModel.fromMap(bankRaw);
} else if (bankRaw is String) {
// Nếu lỡ bị lưu thành chuỗi (vd: "Chưa có thẻ")
parsedBankInfo = BankInfoModel(bankCode: bankRaw, accountNo: '', accountName: '');
}

return UserModel(
uid: doc.id,
displayName: map['displayName']?.toString() ?? 'Người dùng',
email: map['email']?.toString() ?? '',
address: parsedAddress,
totalPoints: (map['totalPoints'] as num?)?.toInt() ?? 0,
currentPoints: (map['currentPoints'] as num?)?.toInt() ?? 0,
weekPoints: (map['weekPoints'] as num?)?.toInt() ?? 0,
monthPoints: (map['monthPoints'] as num?)?.toInt() ?? 0,
role: map['role']?.toString() ?? 'user',
bankInfo: parsedBankInfo,
);
}
}