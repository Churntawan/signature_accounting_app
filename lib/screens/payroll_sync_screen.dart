import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/staff_payroll_item.dart';
import '../services/api_service.dart';

class PayrollSyncScreen extends StatefulWidget {
  final List<StaffPayrollItem> staffPayroll;
  final List<Map<String, dynamic>> payrollAdjustments;
  final String period;
  final VoidCallback onRefresh;

  const PayrollSyncScreen({
    super.key,
    required this.staffPayroll,
    required this.payrollAdjustments,
    required this.period,
    required this.onRefresh,
  });

  @override
  State<PayrollSyncScreen> createState() => _PayrollSyncScreenState();
}

class _PayrollSyncScreenState extends State<PayrollSyncScreen> {
  final NumberFormat currency = NumberFormat('#,##0.00', 'en_US');
  bool _isSyncingToCloud = false;

  Future<void> _syncToCloud() async {
    if (widget.staffPayroll.isEmpty) return;
    setState(() => _isSyncingToCloud = true);
    final ok = await ApiService.syncPayrollSummaryToCloud(widget.staffPayroll);
    setState(() => _isSyncingToCloud = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? '✅ ซิงค์สรุปเงินเดือน ${widget.staffPayroll.length} ท่านไปยัง Supabase เรียบร้อยแล้ว'
                : '⚠️ ไม่สามารถซิงค์ได้ โปรดตรวจสอบการเชื่อมต่ออินเทอร์เน็ต',
          ),
          backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalBase = 0.0;
    double totalNet = 0.0;
    double totalAdvances = 0.0;
    double totalDeductions = 0.0;
    double totalHousing = 0.0;
    double totalExtras = 0.0;
    double totalExcessOffDeductions = 0.0;

    for (var p in widget.staffPayroll) {
      totalBase += p.baseSalary;
      totalNet += p.netPay;
      totalAdvances += p.advanceDeduction;
      totalDeductions += (p.workPermitDeduction + p.otherDeduction);
      totalHousing += p.housingAllowance;
      totalExtras += (p.overtimePay + p.bonusPay + p.otherExtra);
      totalExcessOffDeductions += p.excessDayOffDeduction;
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
              color: Colors.blue.shade50.withOpacity(0.7),
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
                          Icon(Icons.bolt, color: Colors.blue.shade700, size: 22),
                          const SizedBox(width: 8),
                          const Text(
                            'เชื่อมโยงต้นทุนพนักงานแบบ Real-time จาก Signature Payroll',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'คำนวณสดจากข้อมูลพนักงาน Active ทั้งหมด (${widget.staffPayroll.length} ท่าน) พร้อมบันทึกวันลา/OT และยอดเบิกเงินในงวด ${widget.period} ตามรอบวิก (Date : 1, 10, 20)',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: _isSyncingToCloud ? null : _syncToCloud,
                      icon: _isSyncingToCloud
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_upload, size: 16),
                      label: const Text('บันทึกสรุปลง Cloud'),
                    ),
                    FilledButton.icon(
                      onPressed: widget.onRefresh,
                      icon: const Icon(Icons.sync, size: 16),
                      label: const Text('รีเฟรชข้อมูล'),
                      style: FilledButton.styleFrom(backgroundColor: Colors.blue.shade700),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Summary Stats Cards
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 175,
                child: _statBox('จำนวนพนักงาน Active', '${widget.staffPayroll.length} คน', Icons.people, Colors.indigo),
              ),
              SizedBox(
                width: 195,
                child: _statBox('ฐานเงินเดือนรวม', '฿${currency.format(totalBase)}', Icons.account_balance_wallet, Colors.blue.shade800),
              ),
              SizedBox(
                width: 190,
                child: _statBox('ค่าห้องพัก/เพิ่มรวม', '+฿${currency.format(totalHousing + totalExtras)}', Icons.add_home_work, Colors.green.shade700),
              ),
              SizedBox(
                width: 185,
                child: _statBox('ยอดเงินเบิกล่วงหน้า', '-฿${currency.format(totalAdvances)}', Icons.money_off, Colors.amber.shade900),
              ),
              SizedBox(
                width: 200,
                child: _statBox('หักเอกสาร & หยุดเกิน', '-฿${currency.format(totalDeductions + totalExcessOffDeductions)}', Icons.remove_circle_outline, Colors.orange.shade800),
              ),
              SizedBox(
                width: 215,
                child: _statBox('ต้นทุนเงินเดือนสุทธิ', '฿${currency.format(totalNet)}', Icons.payments, Colors.teal.shade800),
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: widget.staffPayroll.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.person_off, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          Text(
                            'ไม่พบข้อมูลพนักงานในงวด ${widget.period}',
                            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต แล้วกดปุ่ม "รีเฟรชข้อมูล"',
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
                        DataColumn(label: Text('รหัส', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('ชื่อเล่น', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('รอบจ่าย (Cycle)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('ฐานเงินเดือน', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('สถิติทำงาน (ทำ/หยุด/ลา/OT)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('ค่าห้องพัก', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('เงินเพิ่ม / OT', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('เงินเบิก (Advance)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('หักเอกสาร/อื่นๆ', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('หักหยุดเกินโควตา', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('เงินเดือนสุทธิ (Net Pay)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('หมายเหตุ / ประจำงวด', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: widget.staffPayroll.map((p) {
                        final extra = p.overtimePay + p.bonusPay + p.otherExtra;
                        final docs = p.workPermitDeduction + p.otherDeduction;

                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                p.epCode,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.blue.shade100,
                                    child: Text(
                                      p.nickname.isNotEmpty ? p.nickname[0].toUpperCase() : '?',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(p.nickname, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  if (p.isDailyWage) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.amber.shade400),
                                      ),
                                      child: Text(
                                        'รายวัน',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text(p.payGroup, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                              ),
                            ),
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    p.isDailyWage
                                        ? '฿${currency.format(p.basePay)}'
                                        : '฿${currency.format(p.baseSalary)}',
                                    style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600),
                                  ),
                                  if (p.isDailyWage)
                                    Text(
                                      '(@฿${p.dailyRate.toInt()}/วัน)',
                                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                    ),
                                ],
                              ),
                            ),
                            DataCell(
                              Text(
                                'ทำงาน ${p.workDays} วัน | หยุด ${p.dayOff} วัน | ลา ${p.sickLeave} วัน${p.otDays > 0 ? " | OT ${p.otDays} วัน" : ""}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            DataCell(
                              Text(
                                p.housingAllowance > 0 ? '+฿${currency.format(p.housingAllowance)}' : '-',
                                style: TextStyle(
                                  color: p.housingAllowance > 0 ? Colors.green.shade700 : Colors.grey,
                                  fontWeight: p.housingAllowance > 0 ? FontWeight.bold : FontWeight.normal,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                extra > 0 ? '+฿${currency.format(extra)}' : '-',
                                style: TextStyle(
                                  color: extra > 0 ? Colors.teal.shade700 : Colors.grey,
                                  fontWeight: extra > 0 ? FontWeight.bold : FontWeight.normal,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                p.advanceDeduction > 0 ? '-฿${currency.format(p.advanceDeduction)}' : '-',
                                style: TextStyle(
                                  color: p.advanceDeduction > 0 ? Colors.amber.shade900 : Colors.grey,
                                  fontWeight: p.advanceDeduction > 0 ? FontWeight.bold : FontWeight.normal,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                docs > 0 ? '-฿${currency.format(docs)}' : '-',
                                style: TextStyle(
                                  color: docs > 0 ? Colors.red.shade700 : Colors.grey,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                p.excessDayOffDeduction > 0
                                    ? '-฿${currency.format(p.excessDayOffDeduction)} (${p.formattedExcessDays} วัน)'
                                    : '-',
                                style: TextStyle(
                                  color: p.excessDayOffDeduction > 0 ? Colors.deepOrange.shade800 : Colors.grey,
                                  fontWeight: p.excessDayOffDeduction > 0 ? FontWeight.bold : FontWeight.normal,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '฿${currency.format(p.netPay)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            DataCell(
                              p.isProrate || p.note.isNotEmpty
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.purple.shade200),
                                      ),
                                      child: Text(
                                        p.note.isNotEmpty ? p.note : 'Prorated',
                                        style: TextStyle(fontSize: 10, color: Colors.purple.shade800, fontWeight: FontWeight.w600),
                                      ),
                                    )
                                  : const Text('-', style: TextStyle(color: Colors.grey)),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color, fontFamily: 'monospace'),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(icon, color: color, size: 22),
        ],
      ),
    );
  }
}
