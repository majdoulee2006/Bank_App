class UserModel {
  final String id;
  final String accountNumber; // 9-digit unique
  String fullName;
  String phone;
  String pin;
  double balance;
  String? nationalId;
  bool isVerified;
  bool isFrozen;
  final String? createdAt;
  final List<TransactionModel> transactions;

  UserModel({
    required this.id,
    required this.accountNumber,
    required this.fullName,
    required this.phone,
    required this.pin,
    this.balance = 0.0,
    this.nationalId,
    this.isVerified = false,
    this.isFrozen = false,
    this.createdAt,
    List<TransactionModel>? transactions,
  }) : transactions = transactions ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'accountNumber': accountNumber,
        'fullName': fullName,
        'phone': phone,
        'pin': pin,
        'balance': balance,
        'nationalId': nationalId,
        'isVerified': isVerified,
        'createdAt': createdAt,
        'transactions': transactions.map((t) => t.toJson()).toList(),
      };

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'],
        accountNumber: j['accountNumber'] ?? _legacyId(j['id']),
        fullName: j['fullName'],
        phone: j['phone'],
        pin: j['pin'] ?? '',
        balance: (j['balance'] as num).toDouble(),
        nationalId: j['nationalId'],
        isVerified: j['isVerified'] == true || j['isVerified'] == 1,
        isFrozen: j['isFrozen'] == true || j['isFrozen'] == 1,
        createdAt: j['createdAt'],
        transactions: (j['transactions'] as List? ?? [])
            .map((t) => TransactionModel.fromJson(t))
            .toList(),
      );

  // backward-compat: old accounts without accountNumber get last 9 digits of id
  static String _legacyId(String id) =>
      id.length >= 9 ? id.substring(id.length - 9) : id.padLeft(9, '0');
}

class TransactionModel {
  final String id;
  final String type; // 'sent' | 'received'
  final String counterPartyName;
  final String counterPartyPhone;
  final String counterPartyAccount;
  final double amount;
  final double fee;
  final DateTime date;
  final String? note;

  TransactionModel({
    required this.id,
    required this.type,
    required this.counterPartyName,
    required this.counterPartyPhone,
    required this.counterPartyAccount,
    required this.amount,
    this.fee = 0.0,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'counterPartyName': counterPartyName,
        'counterPartyPhone': counterPartyPhone,
        'counterPartyAccount': counterPartyAccount,
        'amount': amount,
        'fee': fee,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory TransactionModel.fromJson(Map<String, dynamic> j) =>
      TransactionModel(
        id: j['id'],
        type: j['type'],
        counterPartyName: j['counterPartyName'],
        counterPartyPhone: j['counterPartyPhone'] ?? '',
        counterPartyAccount: j['counterPartyAccount'] ?? '',
        amount: (j['amount'] as num).toDouble(),
        fee: (j['fee'] as num? ?? 0).toDouble(),
        date: DateTime.parse(j['date'].toString().replaceFirst(' ', 'T')),
        note: j['note'],
      );
}
