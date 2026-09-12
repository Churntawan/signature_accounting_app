class ProfitDistribution {
  final double totalRevenue;
  final Map<String, double> salesByStore;
  final double totalOperatingExpenses;
  final Map<String, double> expensesByPayer;
  final Map<String, double> expensesByCategory;
  final double totalStaffPayroll;
  final double totalStaffAdvances;
  final int staffCount;

  // Executive Salaries (เงินเดือนประจำตำแหน่งผู้บริหาร)
  static const double nantapornSalary = 30000.0;
  static const double thayakornSalary = 30000.0;
  static const double churntawanSalary = 25000.0;
  static const double kanthongSalary = 0.0;
  static const double totalExecutiveSalaries = 85000.0;

  ProfitDistribution({
    required this.totalRevenue,
    required this.salesByStore,
    required this.totalOperatingExpenses,
    required this.expensesByPayer,
    required this.expensesByCategory,
    required this.totalStaffPayroll,
    required this.totalStaffAdvances,
    required this.staffCount,
  });

  // กำไรจากการดำเนินงานร้านค้าก่อนหักเงินเดือนผู้บริหาร (Operating Profit)
  double get operatingProfit =>
      totalRevenue - (totalOperatingExpenses + totalStaffPayroll);

  // กำไรสุทธิสำหรับจัดสรรหลังหักเงินเดือนผู้บริหาร 85,000 (Net Distributable Profit)
  double get netDistributableProfit => operatingProfit - totalExecutiveSalaries;

  // อัตรากำไรสุทธิ (Net Margin %)
  double get netProfitMargin =>
      totalRevenue > 0 ? (netDistributableProfit / totalRevenue) * 100 : 0.0;

  // ส่วนแบ่งกำไร 50/50 สองกลุ่มหุ้นส่วน
  double get group1Share =>
      netDistributableProfit > 0 ? netDistributableProfit * 0.50 : 0.0;
  double get group2Share =>
      netDistributableProfit > 0 ? netDistributableProfit * 0.50 : 0.0;

  // ส่วนแบ่งรายบุคคลในแต่ละกลุ่ม (คนละ 25% ของกำไรสุทธิทั้งหมด หรือครึ่งหนึ่งของกลุ่ม)
  double get nantapornProfitShare => group1Share / 2;
  double get thayakornProfitShare => group1Share / 2;
  double get churntawanProfitShare => group2Share / 2;
  double get kanthongProfitShare => group2Share / 2;

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
