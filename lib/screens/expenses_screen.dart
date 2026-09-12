import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/store_expense.dart';
import '../models/profit_distribution.dart';
import '../services/accounting_engine.dart';

class ExpensesScreen extends StatefulWidget {
  final List<StoreExpense> expenses;
  final ProfitDistribution profit;
  final Function(StoreExpense) onAddExpense;
  final Function(dynamic) onDeleteExpense;

  const ExpensesScreen({
    super.key,
    required this.expenses,
    required this.profit,
    required this.onAddExpense,
    required this.onDeleteExpense,
  });

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String _selectedPayer = 'ALL';
  final NumberFormat currency = NumberFormat('#,##0.00', 'en_US');

  @override
  Widget build(BuildContext context) {
    final filteredExpenses = widget.expenses.where((e) {
      if (_selectedPayer == 'ALL') return true;
      return e.payer == _selectedPayer;
    }).toList();

    final totalFiltered = filteredExpenses.fold<double>(0, (sum, e) => sum + e.amount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4 Payers Settlement Summary Cards
          const Text(
            'สรุปเงินสำรองจ่ายแยกตาม 4 แหล่งเงินทุน (Reimbursement Summary)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'ยอดที่แต่ละท่านได้สำรองจ่ายค่าของไปในเดือนนี้ เพื่อรอเบิกเคลียร์เงินคืนจากกองกลาง (Nantaporn)',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          _buildPayerCards(),
          const SizedBox(height: 24),

          // Filter & Total Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('เลือกผู้สำรองจ่าย: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _selectedPayer,
                      items: [
                        const DropdownMenuItem(value: 'ALL', child: Text('👥 ทุกผู้จ่าย (4 ท่าน + กองกลาง)')),
                        ...AccountingEngine.payers.map((p) => DropdownMenuItem(value: p, child: Text(p))),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedPayer = val);
                      },
                    ),
                  ],
                ),
                Text(
                  'ยอดรวมรายจ่าย: ฿${currency.format(totalFiltered)} (${filteredExpenses.length} รายการ)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.purple.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Expenses Table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: filteredExpenses.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text('ยังไม่มีรายการรายจ่ายในงวดนี้ กด "ลงรายจ่าย" ด้านบนเพื่อเริ่มบันทึกข้อมูล',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                      columns: const [
                        DataColumn(label: Text('วันที่', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('ผู้สำรองจ่าย', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('หมวดหมู่', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('ร้านค้า / สาขา', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('จำนวนเงิน (บาท)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('รายละเอียด', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('จัดการ', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: filteredExpenses.map((exp) {
                        return DataRow(
                          cells: [
                            DataCell(Text(exp.date, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
                            DataCell(_buildPayerBadge(exp.payer)),
                            DataCell(Text(exp.category.split(' ').first, style: const TextStyle(fontSize: 12))),
                            DataCell(Text(exp.storeName, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                            DataCell(
                              Text(
                                '฿${currency.format(exp.amount)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            DataCell(Text(exp.note.isEmpty ? '-' : exp.note, style: const TextStyle(fontSize: 12))),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                onPressed: () => _confirmDelete(exp),
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

  Widget _buildPayerCards() {
    final corePayers = [
      {'name': 'Nantaporn', 'amount': widget.profit.nantapornExpensesPaid, 'color': Colors.purple},
      {'name': 'Thayakorn', 'amount': widget.profit.thayakornExpensesPaid, 'color': Colors.blue},
      {'name': 'Churntawan', 'amount': widget.profit.churntawanExpensesPaid, 'color': Colors.teal},
      {'name': 'Kanthong', 'amount': widget.profit.kanthongExpensesPaid, 'color': Colors.amber.shade800},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        return GridView.count(
          crossAxisCount: isWide ? 4 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isWide ? 2.0 : 1.5,
          children: corePayers.map((p) {
            final color = p['color'] as Color;
            final amount = p['amount'] as double;
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPayerBadge(p['name'] as String),
                      const Text('สำรองจ่าย', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  Text(
                    '฿${currency.format(amount)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const Text('รอเบิกคืนจากกองกลาง', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPayerBadge(String payer) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade800;
    Color border = Colors.grey.shade300;

    if (payer == 'Nantaporn') {
      bg = Colors.purple.shade50;
      fg = Colors.purple.shade800;
      border = Colors.purple.shade200;
    } else if (payer == 'Thayakorn') {
      bg = Colors.blue.shade50;
      fg = Colors.blue.shade800;
      border = Colors.blue.shade200;
    } else if (payer == 'Churntawan') {
      bg = Colors.teal.shade50;
      fg = Colors.teal.shade800;
      border = Colors.teal.shade200;
    } else if (payer == 'Kanthong') {
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade900;
      border = Colors.amber.shade200;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Text(
        payer,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  void _confirmDelete(StoreExpense exp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบรายการ'),
        content: Text('คุณต้องการลบรายจ่าย ฿${currency.format(exp.amount)} ที่จ่ายโดย ${exp.payer} ใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDeleteExpense(exp.id);
            },
            child: const Text('ลบรายการ'),
          ),
        ],
      ),
    );
  }
}
