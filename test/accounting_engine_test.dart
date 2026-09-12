import 'package:flutter_test/flutter_test.dart';
import 'package:signature_accounting_app/models/daily_sale.dart';
import 'package:signature_accounting_app/models/store_expense.dart';
import 'package:signature_accounting_app/services/accounting_engine.dart';

void main() {
  group('AccountingEngine & Profit Sharing Tests', () {
    test('Calculates Revenue, Expenses, Payroll, Exec Salaries, and 50/50 Split correctly', () {
      // 1. Setup sample sales for 3 stores
      final sales = [
        DailySale(
          date: '2026-03-01',
          storeName: 'Signature สาขา Big Shop',
          totalAmount: 150000.0,
          period: '2026-03',
        ),
        DailySale(
          date: '2026-03-02',
          storeName: 'Signature สาขา Cabana',
          totalAmount: 120000.0,
          period: '2026-03',
        ),
        DailySale(
          date: '2026-03-03',
          storeName: 'Seaside',
          totalAmount: 80000.0,
          period: '2026-03',
        ),
      ];

      // Total Revenue = 150k + 120k + 80k = 350,000 THB
      expect(sales.fold<double>(0, (sum, s) => sum + s.totalAmount), 350000.0);

      // 2. Setup sample expenses
      final expenses = [
        StoreExpense(
          date: '2026-03-05',
          category: 'วัตถุดิบและสต็อกสินค้า',
          payer: 'Nantaporn',
          amount: 50000.0,
          period: '2026-03',
        ),
        StoreExpense(
          date: '2026-03-06',
          category: 'ค่าเช่าสถานที่',
          payer: 'Thayakorn',
          amount: 30000.0,
          period: '2026-03',
        ),
        StoreExpense(
          date: '2026-03-07',
          category: 'สาธารณูปโภค',
          payer: 'Churntawan',
          amount: 20000.0,
          period: '2026-03',
        ),
      ];
      // Total Operating Expenses = 50k + 30k + 20k = 100,000 THB

      // 3. Setup sample payroll summary
      final payrollSummary = [
        {'ep_code': 'EP01', 'nickname': 'Chujai', 'net_pay': 17000.0, 'base_pay': 17000.0},
        {'ep_code': 'EP04', 'nickname': 'Zin', 'net_pay': 12000.0, 'base_pay': 12000.0},
        {'ep_code': 'EP05', 'nickname': 'Min', 'net_pay': 14000.0, 'base_pay': 14000.0},
        {'ep_code': 'EP06', 'nickname': 'Soe', 'net_pay': 12000.0, 'base_pay': 12000.0},
      ];
      // Total Staff Payroll = 17k + 12k + 14k + 12k = 55,000 THB

      final payrollAdjustments = [
        {'ep_code': 'EP01', 'type': 'Deduction', 'category': 'Advance', 'amount': 2000.0},
        {'ep_code': 'EP04', 'type': 'Deduction', 'category': 'Advance', 'amount': 1500.0},
      ];
      // Total Advances = 3,500 THB

      // Execute computation
      final profit = AccountingEngine.compute(
        sales: sales,
        expenses: expenses,
        payrollSummary: payrollSummary,
        payrollAdjustments: payrollAdjustments,
      );

      // Check revenue
      expect(profit.totalRevenue, 350000.0);
      expect(profit.salesByStore['Signature สาขา Big Shop'], 150000.0);
      expect(profit.salesByStore['Signature สาขา Cabana'], 120000.0);
      expect(profit.salesByStore['Seaside'], 80000.0);

      // Check operating expenses
      expect(profit.totalOperatingExpenses, 100000.0);
      expect(profit.totalStaffPayroll, 55000.0);
      expect(profit.totalStaffAdvances, 3500.0);

      // Operating Profit = 350,000 - (100,000 + 55,000) = 195,000 THB
      expect(profit.operatingProfit, 195000.0);

      // Executive Salaries = 85,000 THB (Nantaporn: 30k, Thayakorn: 30k, Churntawan: 25k, Kanthong: 0)
      // Net Distributable Profit = 195,000 - 85,000 = 110,000 THB
      expect(profit.netDistributableProfit, 110000.0);

      // 50/50 Profit Sharing
      // Group 1 (Nantaporn & Thayakorn): 50% of 110,000 = 55,000 THB
      expect(profit.group1Share, 55000.0);
      expect(profit.nantapornProfitShare, 27500.0);
      expect(profit.thayakornProfitShare, 27500.0);

      // Group 2 (Churntawan & Kanthong): 50% of 110,000 = 55,000 THB
      expect(profit.group2Share, 55000.0);
      expect(profit.churntawanProfitShare, 27500.0);
      expect(profit.kanthongProfitShare, 27500.0);

      // Net Payouts:
      // Nantaporn: Reimbursement 50k + Salary 30k + Profit 27.5k = 107,500 THB
      expect(profit.nantapornNetPayout, 107500.0);

      // Thayakorn: Reimbursement 30k + Salary 30k + Profit 27.5k = 87,500 THB
      expect(profit.thayakornNetPayout, 87500.0);

      // Churntawan: Reimbursement 20k + Salary 25k + Profit 27.5k = 72,500 THB
      expect(profit.churntawanNetPayout, 72500.0);

      // Kanthong: Reimbursement 0k + Salary 0k + Profit 27.5k = 27,500 THB
      expect(profit.kanthongNetPayout, 27500.0);
    });
  });
}
