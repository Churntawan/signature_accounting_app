import '../models/employee.dart';
import '../models/staff_payroll_item.dart';

class CycleDateRange {
  final DateTime startDate;
  final DateTime endDate;
  final DateTime payDate;

  CycleDateRange({
    required this.startDate,
    required this.endDate,
    required this.payDate,
  });
}

class PayrollCalculationService {
  static const double standardOtDailyRate = 180.0;

  static CycleDateRange getCycleRange(String period, String payGroup) {
    final parts = period.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);

    if (payGroup.contains('10')) {
      // 11th of previous month -> 10th of current month
      final startDate = DateTime(year, month - 1, 11);
      final endDate = DateTime(year, month, 10);
      return CycleDateRange(startDate: startDate, endDate: endDate, payDate: endDate);
    } else if (payGroup.contains('20')) {
      // 21st of previous month -> 20th of current month
      final startDate = DateTime(year, month - 1, 21);
      final endDate = DateTime(year, month, 20);
      return CycleDateRange(startDate: startDate, endDate: endDate, payDate: endDate);
    } else {
      // 2nd of previous month -> 1st of current month
      final startDate = DateTime(year, month - 1, 2);
      final endDate = DateTime(year, month, 1);
      return CycleDateRange(startDate: startDate, endDate: endDate, payDate: endDate);
    }
  }

  static List<StaffPayrollItem> computeStaffPayroll({
    required List<Employee> employees,
    required String period,
    required List<Map<String, dynamic>> attendanceLogs,
    required List<Map<String, dynamic>> adjustments,
    List<Map<String, dynamic>>? savedSummary,
  }) {
    final List<StaffPayrollItem> items = [];

    // Map saved summaries by ep_code for fast lookup
    final Map<String, Map<String, dynamic>> summaryMap = {};
    if (savedSummary != null) {
      for (var s in savedSummary) {
        final ep = s['ep_code']?.toString() ?? '';
        if (ep.isNotEmpty) {
          summaryMap[ep] = s;
        }
      }
    }

    for (var emp in employees) {
      final cycle = getCycleRange(period, emp.payGroup);

      // Check if employee has resigned before cycle start
      if (emp.resignDate != null) {
        if (emp.resignDate!.isBefore(cycle.startDate)) continue;
      } else if (!emp.isActive) {
        continue;
      }

      // Check if employee starts after cycle end
      if (emp.startDate != null) {
        if (emp.startDate!.isAfter(cycle.endDate)) continue;
      }

      // Check if already in savedSummary with full details
      final saved = summaryMap[emp.epCode];

      DateTime effectiveStart = cycle.startDate;
      DateTime effectiveEnd = cycle.endDate;
      bool isProrate = false;
      final List<String> reasons = [];

      if (emp.startDate != null && emp.startDate!.isAfter(cycle.startDate)) {
        effectiveStart = emp.startDate!;
        isProrate = true;
        reasons.add('เริ่มงาน ${effectiveStart.day}/${effectiveStart.month}/${effectiveStart.year}');
      }

      if (emp.resignDate != null && emp.resignDate!.isBefore(cycle.endDate)) {
        effectiveEnd = emp.resignDate!;
        isProrate = true;
        reasons.add('ลาออก ${effectiveEnd.day}/${effectiveEnd.month}/${effectiveEnd.year}');
      }

      final double dailyRate = emp.baseSalary / 30.0;
      final int totalCycleDays = cycle.endDate.difference(cycle.startDate).inDays + 1;
      int workedDays = 30;
      double basePay = emp.baseSalary;

      if (isProrate) {
        final calendarWorked = effectiveEnd.difference(effectiveStart).inDays + 1;
        if (calendarWorked <= 15) {
          workedDays = calendarWorked;
        } else {
          final missed = totalCycleDays - calendarWorked;
          workedDays = (30 - missed).clamp(0, 30);
        }
        basePay = (dailyRate * workedDays).roundToDouble();
      }

      // Attendance logs matching cycle dates
      final empAtt = attendanceLogs.where((a) {
        if (a['ep_code']?.toString() != emp.epCode) return false;
        final dStr = a['date']?.toString() ?? '';
        if (dStr.isEmpty) return false;
        try {
          final d = DateTime.parse(dStr);
          final dOnly = DateTime(d.year, d.month, d.day);
          final sOnly = DateTime(cycle.startDate.year, cycle.startDate.month, cycle.startDate.day);
          final eOnly = DateTime(cycle.endDate.year, cycle.endDate.month, cycle.endDate.day);
          return (dOnly.isAtSameMomentAs(sOnly) || dOnly.isAfter(sOnly)) &&
              (dOnly.isAtSameMomentAs(eOnly) || dOnly.isBefore(eOnly));
        } catch (_) {
          return false;
        }
      }).toList();

      final loggedDayOffs = empAtt
          .where((a) => a['category'] == 'Day-off')
          .fold<double>(0.0, (sum, a) => sum + ((a['units'] as num?)?.toDouble() ?? 1.0))
          .round();
      final sickLeave = empAtt
          .where((a) => a['category'] == 'Sick')
          .fold<double>(0.0, (sum, a) => sum + ((a['units'] as num?)?.toDouble() ?? 1.0))
          .round();
      final otUnits = empAtt
          .where((a) => a['category'] == 'OT Days' || a['category'] == 'OT')
          .fold<double>(0.0, (sum, a) => sum + ((a['units'] as num?)?.toDouble() ?? 1.0));
      final int otDays = otUnits.round();
      final double overtimePay = (otUnits * standardOtDailyRate).roundToDouble();

      int dayOff = 4;
      if (loggedDayOffs > 0) {
        dayOff = loggedDayOffs;
      } else if (isProrate) {
        dayOff = 0;
      }

      // Adjustments matching this employee
      final empAdjs = adjustments.where((a) => a['ep_code']?.toString() == emp.epCode).toList();
      double advanceDeduction = 0.0;
      double workPermitDeduction = 0.0;
      double otherDeduction = 0.0;
      double bonusPay = 0.0;
      double otherExtra = 0.0;

      for (var a in empAdjs) {
        final amt = (a['amount'] as num?)?.toDouble() ?? 0.0;
        final type = (a['type'] ?? '').toString();
        final cat = (a['category'] ?? '').toString();

        if (type == 'Income') {
          if (cat.contains('Bonus')) {
            bonusPay += amt;
          } else {
            otherExtra += amt;
          }
        } else {
          if (cat.contains('Advance') || type == 'Advance') {
            advanceDeduction += amt;
          } else if (cat.contains('Passport') || cat.contains('CI') || cat.contains('Permit')) {
            workPermitDeduction += amt;
          } else {
            otherDeduction += amt;
          }
        }
      }

      // Housing Allowance
      double housingAllowance = 0.0;
      if (emp.stayOutside.toLowerCase() == 'yes') {
        bool eligible = true;
        if (emp.startDate != null) {
          final oneMonth = DateTime(emp.startDate!.year, emp.startDate!.month + 1, emp.startDate!.day);
          if (oneMonth.isAfter(cycle.startDate)) eligible = false;
        }
        if (emp.resignDate != null && emp.resignDate!.isBefore(cycle.endDate)) eligible = false;
        if (eligible) housingAllowance = 1000.0;
      }

      // If saved in Supabase payroll_summary, we can use its net_pay if explicitly recorded
      double finalNetPay = basePay + overtimePay + bonusPay + otherExtra + housingAllowance -
          advanceDeduction - workPermitDeduction - otherDeduction;

      if (saved != null && saved['net_pay'] != null) {
        final savedNet = (saved['net_pay'] as num?)?.toDouble() ?? 0.0;
        if (savedNet > 0 && empAdjs.isEmpty && empAtt.isEmpty) {
          finalNetPay = savedNet;
        }
      }

      items.add(StaffPayrollItem(
        epCode: emp.epCode,
        nickname: emp.nickname,
        payGroup: emp.payGroup,
        period: period,
        baseSalary: emp.baseSalary,
        basePay: basePay,
        workedDays: workedDays,
        dayOff: dayOff,
        sickLeave: sickLeave,
        otDays: otDays,
        overtimePay: overtimePay,
        bonusPay: bonusPay,
        otherExtra: otherExtra,
        housingAllowance: housingAllowance,
        advanceDeduction: advanceDeduction,
        workPermitDeduction: workPermitDeduction,
        otherDeduction: otherDeduction,
        netPay: finalNetPay,
        status: emp.status,
        note: reasons.join(' | '),
        isProrate: isProrate,
      ));
    }

    return items;
  }
}
