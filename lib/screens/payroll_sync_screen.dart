import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PayrollSyncScreen extends StatelessWidget {
  final List<Map<String, dynamic>> payrollSummary;
  final List<Map<String, dynamic>> payrollAdjustments;
  final String period;
  final VoidCallback onRefresh;

  final NumberFormat currency = NumberFormat('#,##0.00', 'en_US');

  PayrollSyncScreen({
    super.key,
    required this.payrollSummary,
    required this.payrollAdjustments,
    required this.period,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    double totalNet = 0.0;
    double totalAdvances = 0.0;

    for (var p in payrollSummary) {
      totalNet += (p['net_pay'] ?? p['base_pay'] ?? 0.0).toDouble();
    }

    for (var a in payrollAdjustments) {
      final type = (a['type'] ?? '').toString();
      final cat = (a['category'] ?? '').toString();
      if (type == 'Advance' || cat == 'Advance') {
        totalAdvances += (a['amount'] ?? 0.0).toDouble();
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Info
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.blue.shade50.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.cloud_done, color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'เชื่อมโยงข้อมูลแบบ Real-time จาก Signature Payroll',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ข้อมูลเงินเดือนและเงินเบิกพนักงานในงวด $period ถูกดึงตรงจาก Supabase Cloud ตาราง payroll_summary โดยอัตโนมัติ',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.sync, size: 16),
                  label: const Text('ดึงข้อมูลล่าสุด'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.blue.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Summary Stats Cards
          Row(
            children: [
              Expanded(
                child: _statBox('จำนวนพนักงาน', '${payrollSummary.length} คน', Icons.people, Colors.indigo),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statBox('เงินเดือนพนักงานสุทธิ', '฿${currency.format(totalNet)}', Icons.payments, Colors.green.shade700),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statBox('ยอดเงินเบิกล่วงหน้า', '฿${currency.format(totalAdvances)}', Icons.money_off, Colors.amber.shade900),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Staff Table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: payrollSummary.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.person_off, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          Text(
                            'ยังไม่มีข้อมูลการคำนวณเงินเดือนในงวด $period บน Signature Payroll',
                            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'เมื่อคุณเข้าแอป Signature Payroll และกด "Save to Cloud" แล้ว สามารถกดปุ่ม "ดึงข้อมูลล่าสุด" ด้านบนเพื่อซิงค์ได้ทันที',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                      columns: const [
                        DataColumn(label: Text('รหัสพนักงาน', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('ชื่อเล่น', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('ฐานเงินเดือน', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('วันทำงาน / OT', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('เงินเบิกล่วงหน้า', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('เงินเดือนสุทธิ (Net Pay)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('สถานะ', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: payrollSummary.map((p) {
                        final epCode = p['ep_code'] ?? '';
                        // Find advances for this employee
                        double empAdv = 0.0;
                        for (var a in payrollAdjustments) {
                          if (a['ep_code'] == epCode &&
                              (a['type'] == 'Advance' || a['category'] == 'Advance')) {
                            empAdv += (a['amount'] ?? 0.0).toDouble();
                          }
                        }

                        final netPay = (p['net_pay'] ?? p['base_pay'] ?? 0.0).toDouble();

                        return DataRow(
                          cells: [
                            DataCell(Text(epCode, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontFamily: 'monospace'))),
                            DataCell(Text(p['nickname'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600))),
                            DataCell(Text('฿${currency.format(p['base_salary'] ?? 0.0)}', style: const TextStyle(fontFamily: 'monospace'))),
                            DataCell(Text('${p['work_days'] ?? 0} วัน / OT ${p['ot_days'] ?? 0} วัน', style: const TextStyle(fontSize: 12))),
                            DataCell(Text('฿${currency.format(empAdv)}', style: TextStyle(color: Colors.amber.shade900, fontFamily: 'monospace'))),
                            DataCell(
                              Text(
                                '฿${currency.format(netPay)}',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800, fontFamily: 'monospace'),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: p['status'] == 'Approved' ? Colors.green.shade50 : Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: p['status'] == 'Approved' ? Colors.green.shade200 : Colors.amber.shade200,
                                  ),
                                ),
                                child: Text(
                                  p['status'] ?? 'Pending',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: p['status'] == 'Approved' ? Colors.green.shade800 : Colors.amber.shade900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color, fontFamily: 'monospace')),
            ],
          ),
          Icon(icon, color: color, size: 24),
        ],
      ),
    );
  }
}
