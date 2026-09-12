class StaffPayrollItem {
  final String epCode;
  final String nickname;
  final String payGroup;
  final String period;
  final double baseSalary;
  final double basePay;
  final int workedDays;
  final int dayOff;
  final int sickLeave;
  final int otDays;
  final double overtimePay;
  final double bonusPay;
  final double otherExtra;
  final double housingAllowance;
  final double advanceDeduction;
  final double workPermitDeduction;
  final double otherDeduction;
  final double netPay;
  final String status;
  final String note;
  final bool isProrate;

  StaffPayrollItem({
    required this.epCode,
    required this.nickname,
    required this.payGroup,
    required this.period,
    required this.baseSalary,
    required this.basePay,
    this.workedDays = 30,
    this.dayOff = 4,
    this.sickLeave = 0,
    this.otDays = 0,
    this.overtimePay = 0.0,
    this.bonusPay = 0.0,
    this.otherExtra = 0.0,
    this.housingAllowance = 0.0,
    this.advanceDeduction = 0.0,
    this.workPermitDeduction = 0.0,
    this.otherDeduction = 0.0,
    required this.netPay,
    this.status = 'Active',
    this.note = '',
    this.isProrate = false,
  });

  double get totalExtra => overtimePay + bonusPay + otherExtra + housingAllowance;
  double get totalDeduction => advanceDeduction + workPermitDeduction + otherDeduction;

  factory StaffPayrollItem.fromJson(Map<String, dynamic> json) {
    return StaffPayrollItem(
      epCode: json['ep_code']?.toString() ?? '',
      nickname: json['nickname']?.toString() ?? '',
      payGroup: json['pay_group']?.toString() ?? 'Date : 10',
      period: json['period']?.toString() ?? '',
      baseSalary: (json['base_salary'] as num?)?.toDouble() ?? 0.0,
      basePay: (json['base_pay'] as num?)?.toDouble() ??
          (json['base_salary'] as num?)?.toDouble() ??
          0.0,
      workedDays: (json['work_days'] as num?)?.toInt() ?? 30,
      dayOff: (json['day_off'] as num?)?.toInt() ?? 4,
      sickLeave: (json['sick'] as num?)?.toInt() ?? 0,
      otDays: (json['ot_days'] as num?)?.toInt() ?? 0,
      overtimePay: (json['overtime_pay'] as num?)?.toDouble() ?? 0.0,
      bonusPay: (json['bonus_pay'] as num?)?.toDouble() ?? 0.0,
      otherExtra: (json['total_extra'] as num?)?.toDouble() ?? 0.0,
      housingAllowance: (json['housing_allowance'] as num?)?.toDouble() ?? 0.0,
      advanceDeduction: (json['advance_deduction'] as num?)?.toDouble() ?? 0.0,
      workPermitDeduction: (json['work_permit_deduction'] as num?)?.toDouble() ?? 0.0,
      otherDeduction: (json['total_deduction'] as num?)?.toDouble() ?? 0.0,
      netPay: (json['net_pay'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'Active',
      note: json['note']?.toString() ?? '',
      isProrate: json['pay_type']?.toString().toLowerCase() == 'prorated' ||
          (json['is_prorate'] == true),
    );
  }

  Map<String, dynamic> toJson() => {
        'ep_code': epCode,
        'nickname': nickname,
        'pay_group': payGroup,
        'period': period,
        'pay_type': isProrate ? 'Prorated' : 'Full Month',
        'base_salary': baseSalary,
        'base_pay': basePay,
        'work_days': workedDays,
        'day_off': dayOff,
        'sick': sickLeave,
        'ot_days': otDays,
        'total_extra': totalExtra,
        'total_deduction': totalDeduction,
        'advance_deduction': advanceDeduction,
        'net_pay': netPay,
        'status': status,
        'note': note,
      };
}
