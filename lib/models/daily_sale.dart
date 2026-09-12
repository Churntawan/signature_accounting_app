class DailySale {
  final dynamic id;
  final String date; // YYYY-MM-DD
  final String storeName; // Signature สาขา Big Shop, Signature สาขา Cabana, Seaside
  final double totalAmount;
  final double cashAmount;
  final double qrAmount;
  final double creditAmount;
  final double alipayAmount;
  final String note;
  final String period; // YYYY-MM

  DailySale({
    this.id,
    required this.date,
    required this.storeName,
    required this.totalAmount,
    this.cashAmount = 0.0,
    this.qrAmount = 0.0,
    this.creditAmount = 0.0,
    this.alipayAmount = 0.0,
    this.note = '',
    required this.period,
  });

  factory DailySale.fromJson(Map<String, dynamic> json) {
    return DailySale(
      id: json['id'],
      date: json['date'] ?? '',
      storeName: json['store_name'] ?? '',
      totalAmount: (json['amount'] ?? json['total_amount'] ?? 0.0).toDouble(),
      cashAmount: (json['cash_amount'] ?? 0.0).toDouble(),
      qrAmount: (json['qr_amount'] ?? 0.0).toDouble(),
      creditAmount: (json['credit_amount'] ?? 0.0).toDouble(),
      alipayAmount: (json['alipay_amount'] ?? 0.0).toDouble(),
      note: json['note'] ?? '',
      period: json['period'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'store_name': storeName,
      'amount': totalAmount,
      'cash_amount': cashAmount,
      'qr_amount': qrAmount,
      'credit_amount': creditAmount,
      'alipay_amount': alipayAmount,
      'note': note,
      'period': period,
    };
  }
}
