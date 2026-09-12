import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/daily_sale.dart';
import '../services/accounting_engine.dart';

class SaleEntryDialog extends StatefulWidget {
  final String currentPeriod;
  final Function(DailySale) onSave;

  const SaleEntryDialog({
    super.key,
    required this.currentPeriod,
    required this.onSave,
  });

  @override
  State<SaleEntryDialog> createState() => _SaleEntryDialogState();
}

class _SaleEntryDialogState extends State<SaleEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _date;
  String _storeName = AccountingEngine.stores.first;
  final _totalController = TextEditingController();
  final _cashController = TextEditingController();
  final _qrController = TextEditingController();
  final _creditController = TextEditingController();
  final _alipayController = TextEditingController();
  final _noteController = TextEditingController();
  bool _showBreakdown = false;

  @override
  void initState() {
    super.initState();
    _date = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  void dispose() {
    _totalController.dispose();
    _cashController.dispose();
    _qrController.dispose();
    _creditController.dispose();
    _alipayController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final total = double.tryParse(_totalController.text) ?? 0.0;
      final cash = double.tryParse(_cashController.text) ?? 0.0;
      final qr = double.tryParse(_qrController.text) ?? 0.0;
      final credit = double.tryParse(_creditController.text) ?? 0.0;
      final alipay = double.tryParse(_alipayController.text) ?? 0.0;

      final sale = DailySale(
        date: _date,
        storeName: _storeName,
        totalAmount: total,
        cashAmount: cash,
        qrAmount: qr,
        creditAmount: credit,
        alipayAmount: alipay,
        note: _noteController.text.trim(),
        period: widget.currentPeriod,
      );

      widget.onSave(sale);
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
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.point_of_sale, color: Colors.indigo, size: 20),
          ),
          const SizedBox(width: 10),
          const Text('บันทึกยอดขายประจำวัน', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                  leading: const Icon(Icons.calendar_today, size: 20, color: Colors.indigo),
                  title: const Text('วันที่ขาย', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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

                // Store Dropdown
                const Text('ร้านค้า / สาขา', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _storeName,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: AccountingEngine.stores.map((s) {
                    return DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _storeName = val);
                  },
                ),
                const SizedBox(height: 14),

                // Total Sales
                const Text('ยอดขายรวมของวัน (บาท) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _totalController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.payments, color: Colors.indigo),
                    hintText: '0.00',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'กรุณาระบุยอดขายรวม';
                    if (double.tryParse(val) == null) return 'ตัวเลขไม่ถูกต้อง';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Toggle Optional Breakdown
                InkWell(
                  onTap: () => setState(() => _showBreakdown = !_showBreakdown),
                  child: Row(
                    children: [
                      Icon(_showBreakdown ? Icons.expand_less : Icons.expand_more, size: 20, color: Colors.indigo),
                      const SizedBox(width: 4),
                      Text(
                        _showBreakdown ? 'ซ่อนการแยกประเภทเงินรับ' : 'ระบุแยกประเภทเงินรับ (ใส่หรือไม่ใส่ก็ได้)',
                        style: const TextStyle(fontSize: 12, color: Colors.indigo, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),

                if (_showBreakdown) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cashController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'เงินสด (Cash)', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _qrController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'โอน QR PromptPay', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _creditController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'บัตรเครดิต', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _alipayController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Alipay / อื่นๆ', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),

                // Note
                const Text('หมายเหตุ (ถ้ามี)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    hintText: 'เช่น ยอดปิดรอบเที่ยง / ยอดรวมทั้งวัน',
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
          style: FilledButton.styleFrom(backgroundColor: Colors.indigo),
          child: const Text('บันทึกยอดขาย'),
        ),
      ],
    );
  }
}
