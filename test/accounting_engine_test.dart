import 'package:flutter_test/flutter_test.dart';
import 'package:signature_accounting_app/models/daily_sale.dart';
import 'package:signature_accounting_app/models/store_expense.dart';
import 'package:signature_accounting_app/models/staff_payroll_item.dart';
import 'package:signature_accounting_app/models/employee.dart';
import 'package:signature_accounting_app/services/accounting_engine.dart';
import 'package:signature_accounting_app/services/payroll_calculation_service.dart';
import 'package:signature_accounting_app/models/app_config.dart';

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

    test('PayrollCalculationService calculates excess day-off deductions and housing allowance correctly', () {
      final employees = [
        Employee(
          epCode: 'EP33',
          nickname: 'Tualek',
          status: 'Active',
          baseSalary: 12500.0,
          payGroup: 'Date : 1',
          stayOutside: 'Yes',
        ),
      ];

      // 10 days off -> 6 days excess
      final att = [
        for (int i = 8; i <= 17; i++)
          {'ep_code': 'EP33', 'category': 'Day-off', 'units': 1.0, 'date': '2026-08-${i.toString().padLeft(2, '0')}'},
      ];

      final items = PayrollCalculationService.computeStaffPayroll(
        employees: employees,
        period: '2026-09',
        attendanceLogs: att,
        adjustments: [],
      );

      expect(items.length, 1);
      final tualek = items.first;
      expect(tualek.dayOff, 10);
      expect(tualek.excessDayOffDays, 6);
      expect(tualek.excessDayOffDeduction, (6 * (12500.0 / 30.0)).roundToDouble()); // 2500.0
      expect(tualek.housingAllowance, 1000.0);
      expect(tualek.workDays, 21); // 31 - 10 = 21 work days in August cycle
    });

    test('PayrollCalculationService calculates Daily Wage employee accurately (Zin in 2026-09: 27 days = 10,800 THB)', () {
      final employees = [
        Employee(
          epCode: 'EP04',
          nickname: 'Zin',
          status: 'Active',
          baseSalary: 12000.0,
          payGroup: 'Date : 10',
          stayOutside: 'Yes',
          note: '[Wage:Daily] [Housing:1000]',
        ),
      ];

      // 4 days off in 31-day cycle (2026-08-11 to 2026-09-10) -> 31 - 4 = 27 days worked
      final att = [
        {'ep_code': 'EP04', 'category': 'Day-off', 'units': 1.0, 'date': '2026-08-12'},
        {'ep_code': 'EP04', 'category': 'Day-off', 'units': 1.0, 'date': '2026-08-15'},
        {'ep_code': 'EP04', 'category': 'Day-off', 'units': 1.0, 'date': '2026-08-19'},
        {'ep_code': 'EP04', 'category': 'Day-off', 'units': 1.0, 'date': '2026-09-02'},
      ];

      final adjs = [
        {'ep_code': 'EP04', 'type': 'Deduction', 'category': 'Advance (เบิกเงิน)', 'amount': 1500.0},
      ];

      final items = PayrollCalculationService.computeStaffPayroll(
        employees: employees,
        period: '2026-09',
        attendanceLogs: att,
        adjustments: adjs,
      );

      expect(items.length, 1);
      final zin = items.first;
      expect(zin.wageType, 'Daily');
      expect(zin.isDailyWage, true);
      expect(zin.dailyRate, 400.0);
      expect(zin.dayOff, 4);
      expect(zin.workDays, 27); // 31 - 4 = 27 days worked!
      expect(zin.basePay, 27 * 400.0); // 10,800 THB
      expect(zin.housingAllowance, 1000.0);
      expect(zin.advanceDeduction, 1500.0);
      expect(zin.excessDayOffDeduction, 0.0); // No excess day-off deduction for daily wage
      // Net Pay = 10,800 + 1,000 - 1,500 = 10,300 THB!
      expect(zin.netPay, 10300.0);
    });

    test('AppConfig serializes and deserializes correctly', () {
      final config = AppConfig.defaults();
      final serialized = config.serialize();
      final deserialized = AppConfig.deserialize(serialized);

      expect(deserialized.stores.length, 3);
      expect(deserialized.payers.length, 5);
      expect(deserialized.partners.length, 4);
      expect(deserialized.totalExecutiveSalaries, 85000.0);
      expect(deserialized.group1Percent, 50.0);
      expect(deserialized.group2Percent, 50.0);
    });

    test('AccountingEngine supports dynamic Executive Salaries, 4th Store, and custom shares', () {
      // 1. Setup custom config with 4 stores and custom executive salaries
      final customConfig = AppConfig(
        stores: [
          'Signature สาขา Big Shop',
          'Signature สาขา Cabana',
          'Seaside',
          'Signature สาขา Beachfront', // 4th store!
        ],
        payers: [
          'Nantaporn',
          'Thayakorn',
          'Churntawan',
          'Kanthong',
          'กองกลางร้าน (Store Cash)',
          'Manager Somchai', // New payer!
        ],
        partners: [
          PartnerConfig(
            name: 'Nantaporn',
            role: 'บริหารการเงิน',
            executiveSalary: 40000.0, // adjusted from 30k -> 40k
            groupIndex: 1,
            profitSharePercent: 30.0, // adjusted to 30%
          ),
          PartnerConfig(
            name: 'Thayakorn',
            role: 'ฝ่ายปฏิบัติการ',
            executiveSalary: 35000.0, // adjusted from 30k -> 35k
            groupIndex: 1,
            profitSharePercent: 20.0, // adjusted to 20%
          ),
          PartnerConfig(
            name: 'Churntawan',
            role: 'ฝ่ายบริหารทั่วไป',
            executiveSalary: 25000.0,
            groupIndex: 2,
            profitSharePercent: 25.0,
          ),
          PartnerConfig(
            name: 'Kanthong',
            role: 'ผู้ถือหุ้นร่วม',
            executiveSalary: 10000.0, // adjusted from 0 -> 10k
            groupIndex: 2,
            profitSharePercent: 25.0,
          ),
        ],
      );

      // Total Executive Salaries = 40k + 35k + 25k + 10k = 110,000 THB
      expect(customConfig.totalExecutiveSalaries, 110000.0);
      expect(customConfig.group1Percent, 50.0);
      expect(customConfig.group2Percent, 50.0);

      // Setup sales including the new 4th store
      final sales = [
        DailySale(date: '2026-03-01', storeName: 'Signature สาขา Big Shop', totalAmount: 100000.0, period: '2026-03'),
        DailySale(date: '2026-03-02', storeName: 'Signature สาขา Cabana', totalAmount: 100000.0, period: '2026-03'),
        DailySale(date: '2026-03-03', storeName: 'Seaside', totalAmount: 100000.0, period: '2026-03'),
        DailySale(date: '2026-03-04', storeName: 'Signature สาขา Beachfront', totalAmount: 100000.0, period: '2026-03'),
      ]; // Total Revenue = 400,000 THB across 4 stores

      final expenses = [
        StoreExpense(date: '2026-03-05', category: 'วัตถุดิบ', payer: 'Manager Somchai', amount: 50000.0, period: '2026-03'),
      ]; // Total Operating Expenses = 50,000 THB

      final staff = [
        StaffPayrollItem(
          epCode: 'EP01',
          nickname: 'Chujai',
          payGroup: 'Date : 1',
          period: '2026-03',
          baseSalary: 50000.0,
          basePay: 50000.0,
          netPay: 50000.0,
        ),
      ]; // Total Staff Payroll = 50,000 THB

      final profit = AccountingEngine.compute(
        sales: sales,
        expenses: expenses,
        staffPayroll: staff,
        config: customConfig,
      );

      // Total Revenue = 400,000 THB
      expect(profit.totalRevenue, 400000.0);
      expect(profit.salesByStore.length, 4);
      expect(profit.salesByStore['Signature สาขา Beachfront'], 100000.0);

      // Operating Profit = 400,000 - (50,000 + 50,000) = 300,000 THB
      expect(profit.operatingProfit, 300000.0);

      // Total Executive Salaries = 110,000 THB
      expect(profit.totalExecutiveSalaries, 110000.0);
      expect(profit.nantapornSalary, 40000.0);
      expect(profit.thayakornSalary, 35000.0);
      expect(profit.kanthongSalary, 10000.0);

      // Net Distributable Profit = 300,000 - 110,000 = 190,000 THB
      expect(profit.netDistributableProfit, 190000.0);

      // Custom Shares: Nantaporn 30%, Thayakorn 20%
      expect(profit.nantapornProfitShare, 190000.0 * 0.30); // 57,000 THB
      expect(profit.thayakornProfitShare, 190000.0 * 0.20); // 38,000 THB
      expect(profit.group1Share, 95000.0); // 50% of 190,000
    });
  });
}
