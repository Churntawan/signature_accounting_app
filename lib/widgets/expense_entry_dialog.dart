import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/store_expense.dart';
import '../services/accounting_engine.dart';

class ExpenseEntryDialog extends StatefulWidget {
  final String currentPeriod;
  final Function(StoreExpense) onSave;

  const ExpenseEntryDialog({
    super.key,
    required this.currentPeriod,
    required this.onSave,
  });

  @override
  State<ExpenseEntryDialog> createState() => _ExpenseEntryDialogState();
}

class _ExpenseEntryDialogState extends State<ExpenseEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _date;
  String _payer = AccountingEngine.payers.first;
  String _category = AccountingEngine.categories.first;
  String _storeName = 'กองกลาง / ทุกร้าน';
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _date = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text) ?? 0.0;

      final expense = StoreExpense(
        date: _date,
        storeName: _storeName,
        category: _category,
        payer: _payer,
        amount: amount,
        note: _noteController.text.trim(),
        period: widget.currentPeriod,
      );

      widget.onSave(expense);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.receipt_long, color: Colors.purple, size: 20),
          ),
          const SizedBox(width: 10),
          const Text('ลงบันทึกรายจ่าย & สำรองจ่าย', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today, size: 20, color: Colors.purple),
                  title: const Text('วันที่จ่าย', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text(_date, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: TextButton(
                    child: const Text('เปลี่ยนวัน'),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2050),
                      );
                      if (picked != null) {
                        setState(() {
                          _date = DateFormat('yyyy-MM-dd').format(picked);
                        });
                      }
                    },
                  ),
                ),
                const Divider(),

                // Payer Selection
                const Text('ผู้สำรองจ่าย (Source of Funds / Payer) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _payer,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: AccountingEngine.payers.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text(
                        p,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.purple),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _payer = val);
                  },
                ),
                const SizedBox(height: 14),

                // Category
                const Text('หมวดหมู่รายจ่าย *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: AccountingEngine.categories.map((c) {
                    return DropdownMenuItem(
                      value: c,
                      child: Text(c, style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _category = val);
                  },
                ),
                const SizedBox(height: 14),

                // Store
                const Text('ร้านค้า / สาขา', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _storeName,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: [
                    'กองกลาง / ทุกร้าน',
                    ...AccountingEngine.stores,
                  ].map((s) {
                    return DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _storeName = val);
                  },
                ),
                const SizedBox(height: 14),

                // Amount
                const Text('จำนวนเงิน (บาท) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.attach_money, color: Colors.red),
                    hintText: '0.00',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'กรุณาระบุยอดเงิน';
                    if (double.tryParse(val) == null) return 'ตัวเลขไม่ถูกต้อง';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Note
                const Text('รายละเอียดรายการ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    hintText: 'เช่น ซื้อของสดแม็คโคร, ค่าบำรุงรักษา',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: Colors.purple.shade700),
          child: const Text('บันทึกรายจ่าย'),
        ),
      ],
    );
  }
}
