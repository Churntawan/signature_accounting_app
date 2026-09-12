import '../models/daily_sale.dart';
import '../models/store_expense.dart';
import '../models/profit_distribution.dart';

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
    required List<Map<String, dynamic>> payrollSummary,
    required List<Map<String, dynamic>> payrollAdjustments,
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

    // 2. Compute Expenses
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
    for (var p in payrollSummary) {
      final netPay = (p['net_pay'] ?? 0.0).toDouble();
      final basePay = (p['base_pay'] ?? 0.0).toDouble();
      totalStaffPayroll += (netPay > 0 ? netPay : basePay);
    }

    // 4. Compute Staff Advances
    double totalStaffAdvances = 0.0;
    for (var a in payrollAdjustments) {
      final type = (a['type'] ?? '').toString();
      final cat = (a['category'] ?? '').toString();
      if (type == 'Advance' || cat == 'Advance') {
        totalStaffAdvances += (a['amount'] ?? 0.0).toDouble();
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
      staffCount: payrollSummary.length,
    );
  }
}
