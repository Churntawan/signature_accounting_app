class Employee {
  final String epCode;
  final String nickname;
  final String status; // 'Active' or 'Resigned'
  final double baseSalary;
  final String payGroup; // 'Date : 1', 'Date : 10', 'Date : 20'
  final String stayOutside; // 'Yes' or 'No'
  final DateTime? startDate;
  final DateTime? resignDate;
  final String note;

  Employee({
    required this.epCode,
    required this.nickname,
    required this.status,
    required this.baseSalary,
    required this.payGroup,
    this.stayOutside = 'No',
    this.startDate,
    this.resignDate,
    this.note = '',
  });

  bool get isActive => status.toLowerCase() == 'active';

  factory Employee.fromJson(Map<String, dynamic> json) {
    DateTime? sDate;
    DateTime? rDate;
    if (json['start_date'] != null && json['start_date'].toString().isNotEmpty) {
      sDate = DateTime.tryParse(json['start_date'].toString());
    }
    if (json['resign_date'] != null && json['resign_date'].toString().isNotEmpty) {
      rDate = DateTime.tryParse(json['resign_date'].toString());
    }

    return Employee(
      epCode: json['ep_code']?.toString() ?? '',
      nickname: json['nickname']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Active',
      baseSalary: (json['base_salary'] as num?)?.toDouble() ?? 0.0,
      payGroup: json['pay_group']?.toString() ?? 'Date : 10',
      stayOutside: json['stay_outside']?.toString() ?? 'No',
      startDate: sDate,
      resignDate: rDate,
      note: json['note']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'ep_code': epCode,
        'nickname': nickname,
        'status': status,
        'base_salary': baseSalary,
        'pay_group': payGroup,
        'stay_outside': stayOutside,
        'start_date': startDate?.toIso8601String().split('T').first,
        'resign_date': resignDate?.toIso8601String().split('T').first,
        'note': note,
      };
}
