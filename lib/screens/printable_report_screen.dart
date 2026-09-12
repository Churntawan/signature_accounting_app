import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/profit_distribution.dart';

class PrintableReportScreen extends StatelessWidget {
  final ProfitDistribution profit;
  final String period;
  final NumberFormat currency = NumberFormat('#,##0.00', 'en_US');

  PrintableReportScreen({
    super.key,
    required this.profit,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final todayStr = DateFormat('d MMMM yyyy', 'th').format(DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            children: [
              // Print Action Button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      // In Flutter Web, Ctrl+P or browser print prints the report
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('คุณสามารถกด Ctrl + P บนแป้นพิมพ์ เพื่อสั่งพิมพ์เอกสาร A4 หรือบันทึกเป็น PDF ได้ทันที'),
                          duration: Duration(seconds: 4),
                        ),
                      );
                    },
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('พิมพ์รายงาน A4 / PDF (Ctrl+P)'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.indigo),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // A4 Document Paper
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'SIGNATURE P&L SUITE',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: Colors.indigo,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'รายงานสรุปงบกำไรขาดทุนและการจัดสรรผลประโยชน์ประจำเดือน',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'ธุรกิจเครือข่าย 3 ร้านค้า (Big Shop, Cabana, Seaside)',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'ประจำงวด: $period',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'พิมพ์เมื่อ: $todayStr',
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(thickness: 1.5, height: 28),

                    // Section 1: Sales
                    _sectionTitle('1. รายรับจากการขาย 3 ร้านค้า (Total Revenue)'),
                    _tableBox([
                      _tableRow('ร้านที่ 1: Signature สาขา Big Shop', '฿${currency.format(profit.salesByStore['Signature สาขา Big Shop'] ?? 0)}'),
                      _tableRow('ร้านที่ 2: Signature สาขา Cabana', '฿${currency.format(profit.salesByStore['Signature สาขา Cabana'] ?? 0)}'),
                      _tableRow('ร้านที่ 3: Seaside', '฿${currency.format(profit.salesByStore['Seaside'] ?? 0)}'),
                      _tableRow('รวมรายรับจากการขายทั้งสิ้น', '฿${currency.format(profit.totalRevenue)}', isBold: true, isTotal: true),
                    ]),
                    const SizedBox(height: 16),

                    // Section 2: Operating Expenses
                    _sectionTitle('2. ค่าใช้จ่ายดำเนินงานทั่วไป (Operating Expenses)'),
                    _tableBox([
                      ...profit.expensesByCategory.entries.map((e) => _tableRow(e.key, '฿${currency.format(e.value)}')),
                      _tableRow('รวมค่าใช้จ่ายดำเนินงานทั้งสิ้น', '฿${currency.format(profit.totalOperatingExpenses)}', isBold: true, isTotal: true),
                    ]),
                    const SizedBox(height: 16),

                    // Section 3: Staff Payroll
                    _sectionTitle('3. ต้นทุนพนักงานหน้าร้าน Signature Payroll (Staff Labor Cost)'),
                    _tableBox([
                      _tableRow('เงินเดือนสุทธิพนักงานที่จ่ายจริง (${profit.staffCount} คน)', '฿${currency.format(profit.totalStaffPayroll)}'),
                      _tableRow('เงินที่พนักงานเบิกล่วงหน้า (Staff Advances)', '฿${currency.format(profit.totalStaffAdvances)}'),
                    ]),
                    const SizedBox(height: 16),

                    // Section 4: Executive Salaries
                    _sectionTitle('4. ค่าตอบแทน/เงินเดือนประจำตำแหน่งผู้บริหาร 4 ท่าน'),
                    _tableBox([
                      _tableRow('Nantaporn (ผู้ดูแลบัญชีกองกลางร้าน)', '฿${currency.format(ProfitDistribution.nantapornSalary)}'),
                      _tableRow('Thayakorn (ฝ่ายปฏิบัติการ)', '฿${currency.format(ProfitDistribution.thayakornSalary)}'),
                      _tableRow('Churntawan (ฝ่ายบริหารทั่วไป)', '฿${currency.format(ProfitDistribution.churntawanSalary)}'),
                      _tableRow('Kanthong (ผู้ถือหุ้นร่วม)', '฿${currency.format(ProfitDistribution.kanthongSalary)}'),
                      _tableRow('รวมเงินเดือนผู้บริหารทั้งสิ้น', '฿${currency.format(ProfitDistribution.totalExecutiveSalaries)}', isBold: true, isTotal: true),
                    ]),
                    const SizedBox(height: 16),

                    // Section 5: Net Distributable Profit & 50/50 Split
                    _sectionTitle('5. สรุปกำไรสุทธิสำหรับจัดสรรและการแบ่งปันผลกำไร 50 / 50'),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          _tableRow(
                            'กำไรสุทธิสำหรับจัดสรร (Net Distributable Profit)',
                            '฿${currency.format(profit.netDistributableProfit)}',
                            isBold: true,
                          ),
                          const Divider(height: 12),
                          _tableRow('• กลุ่มที่ 1 (50%): Nantaporn & Thayakorn (คนละ 25%)', '฿${currency.format(profit.group1Share)}'),
                          _tableRow('• กลุ่มที่ 2 (50%): Churntawan & Kanthong (คนละ 25%)', '฿${currency.format(profit.group2Share)}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section 6: Individual Payout Summary
                    _sectionTitle('6. ตารางสรุปยอดเงินรับสุทธิของ 4 ผู้ถือหุ้นประจำงวด (Reimbursement + Salary + Profit)'),
                    _tableBox([
                      _partnerHeaderRow(),
                      _partnerDetailRow('Nantaporn', profit.nantapornExpensesPaid, ProfitDistribution.nantapornSalary, profit.nantapornProfitShare, profit.nantapornNetPayout),
                      _partnerDetailRow('Thayakorn', profit.thayakornExpensesPaid, ProfitDistribution.thayakornSalary, profit.thayakornProfitShare, profit.thayakornNetPayout),
                      _partnerDetailRow('Churntawan', profit.churntawanExpensesPaid, ProfitDistribution.churntawanSalary, profit.churntawanProfitShare, profit.churntawanNetPayout),
                      _partnerDetailRow('Kanthong', profit.kanthongExpensesPaid, ProfitDistribution.kanthongSalary, profit.kanthongProfitShare, profit.kanthongNetPayout),
                    ]),
                    const SizedBox(height: 36),

                    // Signatures Block (4 Boxes)
                    const Text('ลงชื่อรับรองความถูกต้องของรายการบัญชีประจำงวด', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _signatureColumn('Nantaporn'),
                        _signatureColumn('Thayakorn'),
                        _signatureColumn('Churntawan'),
                        _signatureColumn('Kanthong'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _tableBox(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(children: rows),
    );
  }

  Widget _tableRow(String label, String amount, {bool isBold = false, bool isTotal = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isTotal ? Colors.grey.shade100 : Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(amount, style: TextStyle(fontSize: 11, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _partnerHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: Colors.grey.shade100,
      child: const Row(
        children: [
          Expanded(flex: 2, child: Text('ผู้ถือหุ้น', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('สำรองจ่าย', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('เงินเดือน', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('ส่วนแบ่งกำไร', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('ยอดรับสุทธิ', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _partnerDetailRow(String name, double exp, double salary, double profit, double total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('฿${currency.format(exp)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 10, fontFamily: 'monospace'))),
          Expanded(flex: 2, child: Text('฿${currency.format(salary)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 10, fontFamily: 'monospace'))),
          Expanded(flex: 2, child: Text('฿${currency.format(profit)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 10, fontFamily: 'monospace'))),
          Expanded(flex: 2, child: Text('฿${currency.format(total)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: Colors.indigo))),
        ],
      ),
    );
  }

  Widget _signatureColumn(String name) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            Container(height: 40, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey)))),
            const SizedBox(height: 6),
            Text('( $name )', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            const Text('ผู้มีอำนาจลงนาม', style: TextStyle(fontSize: 9, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
