import 'package:flutter_test/flutter_test.dart';
import 'package:signature_accounting_app/models/daily_sale.dart';
import 'package:signature_accounting_app/models/store_expense.dart';
import 'package:signature_accounting_app/models/staff_payroll_item.dart';
import 'package:signature_accounting_app/models/employee.dart';
import 'package:signature_accounting_app/services/accounting_engine.dart';
import 'package:signature_accounting_app/services/payroll_calculation_service.dart';

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

      // 3. Setup sample staff payroll items
      final staffPayroll = [
        StaffPayrollItem(
          epCode: 'EP01',
          nickname: 'Chujai',
          payGroup: 'Date : 1',
          period: '2026-03',
          baseSalary: 17000.0,
          basePay: 17000.0,
          netPay: 17000.0,
        ),
        StaffPayrollItem(
          epCode: 'EP04',
          nickname: 'Zin',
          payGroup: 'Date : 10',
          period: '2026-03',
          baseSalary: 12000.0,
          basePay: 12000.0,
          advanceDeduction: 1500.0,
          netPay: 10500.0,
        ),
        StaffPayrollItem(
          epCode: 'EP05',
          nickname: 'Min',
          payGroup: 'Date : 10',
          period: '2026-03',
          baseSalary: 14000.0,
          basePay: 14000.0,
          netPay: 14000.0,
        ),
        StaffPayrollItem(
          epCode: 'EP06',
          nickname: 'Soe',
          payGroup: 'Date : 10',
          period: '2026-03',
          baseSalary: 12000.0,
          basePay: 12000.0,
          netPay: 12000.0,
        ),
      ];
      // Total Staff Payroll Net Pay = 17k + 10.5k + 14k + 12k = 53,500 THB
      // Advances = 1,500 THB

      final payrollAdjustments = [
        {'ep_code': 'EP01', 'type': 'Deduction', 'category': 'Advance', 'amount': 2000.0},
      ];

      // Execute computation
      final profit = AccountingEngine.compute(
        sales: sales,
        expenses: expenses,
        staffPayroll: staffPayroll,
        payrollAdjustments: payrollAdjustments,
      );

      // Check revenue
      expect(profit.totalRevenue, 350000.0);
      expect(profit.salesByStore['Signature สาขา Big Shop'], 150000.0);
      expect(profit.salesByStore['Signature สาขา Cabana'], 120000.0);
      expect(profit.salesByStore['Seaside'], 80000.0);

      // Check operating expenses
      expect(profit.totalOperatingExpenses, 100000.0);
      expect(profit.totalStaffPayroll, 53500.0);
      expect(profit.totalStaffAdvances, 3500.0); // 1500 in staff + 2000 in adj
      expect(profit.staffCount, 4);

      // Operating Profit = 350,000 - (100,000 + 53,500) = 196,500 THB
      expect(profit.operatingProfit, 196500.0);

      // Executive Salaries = 85,000 THB
      // Net Distributable Profit = 196,500 - 85,000 = 111,500 THB
      expect(profit.netDistributableProfit, 111500.0);

      // 50/50 Profit Sharing
      expect(profit.group1Share, 55750.0);
      expect(profit.nantapornProfitShare, 27875.0);
      expect(profit.thayakornProfitShare, 27875.0);

      expect(profit.group2Share, 55750.0);
      expect(profit.churntawanProfitShare, 27875.0);
      expect(profit.kanthongProfitShare, 27875.0);
    });

    test('PayrollCalculationService computes cycle dates and employee records accurately', () {
      final employees = [
        Employee(
          epCode: 'EP04',
          nickname: 'Zin',
          status: 'Active',
          baseSalary: 12000.0,
          payGroup: 'Date : 10',
        ),
        Employee(
          epCode: 'EP16',
          nickname: 'T',
          status: 'Active',
          baseSalary: 13000.0,
          payGroup: 'Date : 20',
        ),
        Employee(
          epCode: 'EP31',
          nickname: 'Kat',
          status: 'Active',
          baseSalary: 14000.0,
          payGroup: 'Date : 1',
        ),
      ];

      final adjs = [
        {'ep_code': 'EP04', 'type': 'Deduction', 'category': 'Advance (เบิกเงิน)', 'amount': 1500.0},
        {'ep_code': 'EP31', 'type': 'Deduction', 'category': 'Passport / CI', 'amount': 3000.0},
      ];

      final att = [
        {'ep_code': 'EP16', 'category': 'OT Days', 'units': 2.0, 'date': '2026-09-05'},
      ];

      final items = PayrollCalculationService.computeStaffPayroll(
        employees: employees,
        period: '2026-09',
        attendanceLogs: att,
        adjustments: adjs,
      );

      expect(items.length, 3);

      final zin = items.firstWhere((i) => i.epCode == 'EP04');
      expect(zin.baseSalary, 12000.0);
      expect(zin.advanceDeduction, 1500.0);
      expect(zin.netPay, 10500.0);

      final t = items.firstWhere((i) => i.epCode == 'EP16');
      expect(t.baseSalary, 13000.0);
      expect(t.otDays, 2);
      expect(t.overtimePay, 360.0);
      expect(t.netPay, 13360.0);

      final kat = items.firstWhere((i) => i.epCode == 'EP31');
      expect(kat.baseSalary, 14000.0);
      expect(kat.workPermitDeduction, 3000.0);
      expect(kat.netPay, 11000.0);
    });
  });
}
