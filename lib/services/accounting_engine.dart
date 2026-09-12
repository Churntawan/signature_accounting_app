import '../models/daily_sale.dart';
import '../models/store_expense.dart';
import '../models/profit_distribution.dart';
import '../models/staff_payroll_item.dart';

class AccountingEngine {
  static const List<String> stores = [
    'Signature สาขา Big Shop',
    'Signature สาขา Cabana',
    'Seaside',
  ];

  static const List<String> payers = [
    'Nantaporn',
    'Thayakorn',
    'Churntawan',
    'Kanthong',
    'กองกลางร้าน (Store Cash)',
  ];

  static const List<String> categories = [
    'วัตถุดิบและสต็อกสินค้า (Ingredients/Stock)',
    'ค่าเช่าสถานที่ (Rent)',
    'สาธารณูปโภค ค่าน้ำ/ค่าไฟ (Utilities)',
    'บรรจุภัณฑ์และของใช้ (Packaging & Supplies)',
    'ซ่อมบำรุงและงานช่าง (Maintenance)',
    'ค่าขนส่งและเดินทาง (Logistics)',
    'การตลาดและโฆษณา (Marketing)',
    'เบ็ดเตล็ดและค่าใช้จ่ายทั่วไป (Miscellaneous)',
  ];

  static ProfitDistribution compute({
    required List<DailySale> sales,
    required List<StoreExpense> expenses,
    required List<StaffPayrollItem> staffPayroll,
    List<Map<String, dynamic>> payrollAdjustments = const [],
  }) {
    // 1. Compute Revenue
    double totalRevenue = 0.0;
    final Map<String, double> salesByStore = {
      for (var s in stores) s: 0.0,
    };

    for (var sale in sales) {
      totalRevenue += sale.totalAmount;
      salesByStore[sale.storeName] =
          (salesByStore[sale.storeName] ?? 0.0) + sale.totalAmount;
    }

    // 2. Compute Operating Expenses
    double totalOperatingExpenses = 0.0;
    final Map<String, double> expensesByPayer = {
      for (var p in payers) p: 0.0,
    };
    final Map<String, double> expensesByCategory = {};

    for (var exp in expenses) {
      totalOperatingExpenses += exp.amount;
      expensesByPayer[exp.payer] =
          (expensesByPayer[exp.payer] ?? 0.0) + exp.amount;
      expensesByCategory[exp.category] =
          (expensesByCategory[exp.category] ?? 0.0) + exp.amount;
    }

    // 3. Compute Staff Payroll
    double totalStaffPayroll = 0.0;
    double totalStaffAdvances = 0.0;

    for (var item in staffPayroll) {
      totalStaffPayroll += item.netPay;
      totalStaffAdvances += item.advanceDeduction;
    }

    // Include any additional advances for non-active staff in period adjustments
    for (var a in payrollAdjustments) {
      final type = (a['type'] ?? '').toString();
      final cat = (a['category'] ?? '').toString();
      final ep = a['ep_code']?.toString() ?? '';
      if (type == 'Advance' || cat == 'Advance') {
        final alreadyInStaff = staffPayroll.any((s) => s.epCode == ep && s.advanceDeduction > 0);
        if (!alreadyInStaff) {
          totalStaffAdvances += (a['amount'] ?? 0.0).toDouble();
        }
      }
    }

    return ProfitDistribution(
      totalRevenue: totalRevenue,
      salesByStore: salesByStore,
      totalOperatingExpenses: totalOperatingExpenses,
      expensesByPayer: expensesByPayer,
      expensesByCategory: expensesByCategory,
      totalStaffPayroll: totalStaffPayroll,
      totalStaffAdvances: totalStaffAdvances,
      staffCount: staffPayroll.length,
    );
  }
}
