import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/daily_sale.dart';
import '../services/accounting_engine.dart';

class DailySalesScreen extends StatefulWidget {
  final List<DailySale> sales;
  final Function(DailySale) onAddSale;
  final Function(dynamic) onDeleteSale;

  const DailySalesScreen({
    super.key,
    required this.sales,
    required this.onAddSale,
    required this.onDeleteSale,
  });

  @override
  State<DailySalesScreen> createState() => _DailySalesScreenState();
}

class _DailySalesScreenState extends State<DailySalesScreen> {
  String _selectedStore = 'ALL';
  final NumberFormat currency = NumberFormat('#,##0.00', 'en_US');

  @override
  Widget build(BuildContext context) {
    final filteredSales = widget.sales.where((s) {
      if (_selectedStore == 'ALL') return true;
      return s.storeName == _selectedStore;
    }).toList();

    final totalFiltered = filteredSales.fold<double>(0, (sum, s) => sum + s.totalAmount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    const Text('เลือกร้านค้า: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _selectedStore,
                      items: [
                        const DropdownMenuItem(value: 'ALL', child: Text('🏪 ทุกร้านค้า (รวม 3 ร้าน)')),
                        ...AccountingEngine.stores.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedStore = val);
                      },
                    ),
                  ],
                ),
                Text(
                  'ยอดขายรวม: ฿${currency.format(totalFiltered)} (${filteredSales.length} วัน)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.indigo),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Sales Table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: filteredSales.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text('ยังไม่มีรายการยอดขายในงวดนี้ กด "บันทึกยอดขาย" ด้านบนเพื่อเริ่มบันทึกข้อมูล',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                      columns: const [
                        DataColumn(label: Text('วันที่', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('ร้านค้า / สาขา', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('ยอดขายรวม (บาท)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('แยกประเภทเงินรับ', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('หมายเหตุ', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('จัดการ', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: filteredSales.map((sale) {
                        return DataRow(
                          cells: [
                            DataCell(Text(sale.date, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
                            DataCell(Text(sale.storeName, style: const TextStyle(fontWeight: FontWeight.w600))),
                            DataCell(
                              Text(
                                '฿${currency.format(sale.totalAmount)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            DataCell(_buildBreakdownPills(sale)),
                            DataCell(Text(sale.note.isEmpty ? '-' : sale.note, style: const TextStyle(fontSize: 12))),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                onPressed: () => _confirmDelete(sale),
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

  Widget _buildBreakdownPills(DailySale sale) {
    final pills = <Widget>[];
    if (sale.cashAmount > 0) pills.add(_pill('สด: ฿${currency.format(sale.cashAmount)}', Colors.green));
    if (sale.qrAmount > 0) pills.add(_pill('QR: ฿${currency.format(sale.qrAmount)}', Colors.blue));
    if (sale.creditAmount > 0) pills.add(_pill('บัตร: ฿${currency.format(sale.creditAmount)}', Colors.purple));
    if (sale.alipayAmount > 0) pills.add(_pill('Alipay: ฿${currency.format(sale.alipayAmount)}', Colors.orange));

    if (pills.isEmpty) {
      return const Text('-', style: TextStyle(color: Colors.grey, fontSize: 12));
    }

    return Wrap(spacing: 4, children: pills);
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  void _confirmDelete(DailySale sale) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบรายการ'),
        content: Text('คุณต้องการลบยอดขายวันที่ ${sale.date} ของ ${sale.storeName} ใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDeleteSale(sale.id);
            },
            child: const Text('ลบรายการ'),
          ),
        ],
      ),
    );
  }
}
