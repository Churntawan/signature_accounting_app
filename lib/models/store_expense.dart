class StoreExpense {
  final dynamic id;
  final String date; // YYYY-MM-DD
  final String storeName; // Signature สาขา Big Shop, Signature สาขา Cabana, Seaside, กองกลาง/ทุกร้าน
  final String category; // วัตถุดิบ, ค่าเช่า, น้ำไฟ, ฯลฯ
  final String payer; // Nantaporn, Thayakorn, Churntawan, Kanthong, กองกลางร้าน (Store Cash)
  final double amount;
  final String note;
  final String period; // YYYY-MM
  final String status; // Pending, Settled, Reimbursed

  StoreExpense({
    this.id,
    required this.date,
    this.storeName = 'กองกลาง / ทุกร้าน',
    required this.category,
    required this.payer,
    required this.amount,
    this.note = '',
    required this.period,
    this.status = 'Settled',
  });

  factory StoreExpense.fromJson(Map<String, dynamic> json) {
    return StoreExpense(
      id: json['id'],
      date: json['date'] ?? '',
      storeName: json['store_name'] ?? 'กองกลาง / ทุกร้าน',
      category: json['category'] ?? 'วัตถุดิบ/สต็อก',
      payer: json['payer'] ?? 'Nantaporn',
      amount: (json['amount'] ?? 0.0).toDouble(),
      note: json['note'] ?? '',
      period: json['period'] ?? '',
      status: json['status'] ?? 'Settled',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'store_name': storeName,
      'category': category,
      'payer': payer,
      'amount': amount,
      'note': note,
      'period': period,
      'status': status,
    };
  }
}
