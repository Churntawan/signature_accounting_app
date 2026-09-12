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

  /// Check if employee is paid on daily wage basis
  bool get isDailyWage => note.contains('[Wage:Daily]');
  String get wageType => isDailyWage ? 'Daily' : 'Monthly';

  /// Daily wage rate: parses [DailyRate:xxx] or calculates baseSalary / 30 if baseSalary >= 1000
  double get dailyWageRate {
    final match = RegExp(r'\[DailyRate:([0-9.]+)\]').firstMatch(note);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '') ?? (baseSalary >= 1000 ? (baseSalary / 30.0).roundToDouble() : baseSalary);
    }
    if (baseSalary >= 1000) {
      return (baseSalary / 30.0).roundToDouble();
    }
    return baseSalary > 0 ? baseSalary : 400.0;
  }

  /// Housing allowance amount (defaults to 1000.0 if stayOutside is Yes, unless custom tag is set)
  double get housingAllowanceAmount {
    if (stayOutside.toLowerCase() != 'yes') return 0.0;
    final match = RegExp(r'\[Housing:([0-9.]+)\]').firstMatch(note);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '') ?? 1000.0;
    }
    return 1000.0;
  }

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
