import 'package:flutter/material.dart';

class PeriodSelectorBar extends StatelessWidget {
  final String currentPeriod;
  final List<String> periods;
  final ValueChanged<String> onPeriodChanged;
  final VoidCallback onRefresh;
  final VoidCallback onAddSale;
  final VoidCallback onAddExpense;
  final bool isConnected;

  const PeriodSelectorBar({
    super.key,
    required this.currentPeriod,
    required this.periods,
    required this.onPeriodChanged,
    required this.onRefresh,
    required this.onAddSale,
    required this.onAddExpense,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Left side: Period selector and status
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_month, size: 16, color: Colors.indigo),
                    const SizedBox(width: 8),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: periods.contains(currentPeriod) ? currentPeriod : periods.firstOrNull,
                        items: periods.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Text(
                              'งวดประจำเดือน: $p',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) onPeriodChanged(val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Cloud Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isConnected ? Colors.green.shade50 : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isConnected ? Colors.green.shade200 : Colors.amber.shade200,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isConnected ? Colors.green : Colors.amber.shade700,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isConnected ? 'Supabase Live' : 'Offline Mode',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isConnected ? Colors.green.shade800 : Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.sync, size: 18),
                tooltip: 'ดึงข้อมูลสด Real-time จาก Signature Payroll',
                onPressed: onRefresh,
              ),
            ],
          ),

          // Right side: Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.icon(
                onPressed: onAddSale,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('บันทึกยอดขาย'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: onAddExpense,
                icon: const Icon(Icons.receipt_long, size: 16),
                label: const Text('ลงรายจ่าย'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.purple.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
