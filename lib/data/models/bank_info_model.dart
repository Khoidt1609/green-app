class BankInfoModel {
  final String bankCode;
  final String accountNo;
  final String accountName;

  BankInfoModel({
    required this.bankCode,
    required this.accountNo,
    required this.accountName,
  });

  BankInfoModel copyWith({
    String? bankCode,
    String? accountNo,
    String? accountName,
  }) {
    return BankInfoModel(
      bankCode: bankCode ?? this.bankCode,
      accountNo: accountNo ?? this.accountNo,
      accountName: accountName ?? this.accountName,
    );
  }

  Map<String, dynamic> toMap() => {
    'bankCode': bankCode,
    'accountNo': accountNo,
    'accountName': accountName,
  };

  factory BankInfoModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) return BankInfoModel(bankCode: '', accountNo: '', accountName: '');
    return BankInfoModel(
      bankCode: map['bankCode'] ?? '',
      accountNo: map['accountNo'] ?? '',
      accountName: map['accountName'] ?? '',
    );
  }
}