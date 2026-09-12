import 'app_config.dart';

class ProfitDistribution {
  final double totalRevenue;
  final Map<String, double> salesByStore;
  final double totalOperatingExpenses;
  final Map<String, double> expensesByPayer;
  final Map<String, double> expensesByCategory;
  final double totalStaffPayroll;
  final double totalStaffAdvances;
  final int staffCount;
  final AppConfig config;

  ProfitDistribution({
    required this.totalRevenue,
    required this.salesByStore,
    required this.totalOperatingExpenses,
    required this.expensesByPayer,
    required this.expensesByCategory,
    required this.totalStaffPayroll,
    required this.totalStaffAdvances,
    required this.staffCount,
    AppConfig? config,
  }) : config = config ?? AppConfig.defaults();

  // Dynamic Executive Salaries from config
  double get nantapornSalary => config.getPartnerSalary('Nantaporn');
  double get thayakornSalary => config.getPartnerSalary('Thayakorn');
  double get churntawanSalary => config.getPartnerSalary('Churntawan');
  double get kanthongSalary => config.getPartnerSalary('Kanthong');
  double get totalExecutiveSalaries => config.totalExecutiveSalaries;

  // กำไรจากการดำเนินงานร้านค้าก่อนหักเงินเดือนผู้บริหาร (Operating Profit)
  double get operatingProfit =>
      totalRevenue - (totalOperatingExpenses + totalStaffPayroll);

  // กำไรสุทธิสำหรับจัดสรรหลังหักเงินเดือนผู้บริหาร (Net Distributable Profit)
  double get netDistributableProfit => operatingProfit - totalExecutiveSalaries;

  // อัตรากำไรสุทธิ (Net Margin %)
  double get netProfitMargin =>
      totalRevenue > 0 ? (netDistributableProfit / totalRevenue) * 100 : 0.0;

  // ส่วนแบ่งกำไรสองกลุ่มหุ้นส่วน (Dynamic จาก config)
  double get group1Share =>
      netDistributableProfit > 0 ? netDistributableProfit * (config.group1Percent / 100.0) : 0.0;
  double get group2Share =>
      netDistributableProfit > 0 ? netDistributableProfit * (config.group2Percent / 100.0) : 0.0;

  // ส่วนแบ่งรายบุคคลในแต่ละกลุ่ม (Dynamic จาก config)
  double get nantapornProfitShare =>
      netDistributableProfit > 0 ? netDistributableProfit * (config.getPartnerProfitShare('Nantaporn') / 100.0) : 0.0;
  double get thayakornProfitShare =>
      netDistributableProfit > 0 ? netDistributableProfit * (config.getPartnerProfitShare('Thayakorn') / 100.0) : 0.0;
  double get churntawanProfitShare =>
      netDistributableProfit > 0 ? netDistributableProfit * (config.getPartnerProfitShare('Churntawan') / 100.0) : 0.0;
  double get kanthongProfitShare =>
      netDistributableProfit > 0 ? netDistributableProfit * (config.getPartnerProfitShare('Kanthong') / 100.0) : 0.0;

  // ยอดเงินสำรองจ่ายที่แต่ละคนควักกระเป๋าจ่ายไปในงวดนี้
  double get nantapornExpensesPaid => expensesByPayer['Nantaporn'] ?? 0.0;
  double get thayakornExpensesPaid => expensesByPayer['Thayakorn'] ?? 0.0;
  double get churntawanExpensesPaid => expensesByPayer['Churntawan'] ?? 0.0;
  double get kanthongExpensesPaid => expensesByPayer['Kanthong'] ?? 0.0;
  double get storeCashExpensesPaid =>
      expensesByPayer['กองกลางร้าน (Store Cash)'] ?? 0.0;

  // ยอดเงินรับสุทธิประจำงวด (Reimbursement + Executive Salary + Profit Share)
  double get nantapornNetPayout =>
      nantapornExpensesPaid + nantapornSalary + nantapornProfitShare;
  double get thayakornNetPayout =>
      thayakornExpensesPaid + thayakornSalary + thayakornProfitShare;
  double get churntawanNetPayout =>
      churntawanExpensesPaid + churntawanSalary + churntawanProfitShare;
  double get kanthongNetPayout =>
      kanthongExpensesPaid + kanthongSalary + kanthongProfitShare;
}
