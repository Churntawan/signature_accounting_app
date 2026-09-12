import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/profit_distribution.dart';
import '../widgets/kpi_card.dart';

class DashboardScreen extends StatelessWidget {
  final ProfitDistribution profit;
  final NumberFormat currency = NumberFormat('#,##0.00', 'en_US');

  DashboardScreen({super.key, required this.profit});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4 Top KPI Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              return GridView.count(
                crossAxisCount: isWide ? 4 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: isWide ? 1.8 : 1.4,
                children: [
                  KpiCard(
                    title: 'ยอดขายรวม 3 ร้าน',
                    value: '฿${currency.format(profit.totalRevenue)}',
                    subtitle: 'Big Shop / Cabana / Seaside',
                    icon: Icons.point_of_sale,
                    color: Colors.indigo,
                  ),
                  KpiCard(
                    title: 'รายจ่ายดำเนินงานทั่วไป',
                    value: '฿${currency.format(profit.totalOperatingExpenses)}',
                    subtitle: 'ค่าของ / ค่าเช่า / น้ำไฟ',
                    icon: Icons.receipt_long,
                    color: Colors.purple.shade700,
                  ),
                  KpiCard(
                    title: 'ต้นทุนพนักงาน Signature Payroll',
                    value: '฿${currency.format(profit.totalStaffPayroll)}',
                    subtitle: '${profit.staffCount} พนักงาน (เบิก ฿${currency.format(profit.totalStaffAdvances)})',
                    icon: Icons.people,
                    color: Colors.blue.shade700,
                  ),
                  KpiCard(
                    title: 'กำไรสุทธิจัดสรร 50/50',
                    value: '฿${currency.format(profit.netDistributableProfit)}',
                    subtitle: 'หลังหักเงินเดือนผู้บริหาร 85k (${profit.netProfitMargin.toStringAsFixed(1)}%)',
                    icon: Icons.account_balance_wallet,
                    color: profit.netDistributableProfit >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Charts Section: Store Sales & Expense Categories
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              return isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildStoreSalesChart()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildProfitShareOverviewCard()),
                      ],
                    )
                  : Column(
                      children: [
                        _buildStoreSalesChart(),
                        const SizedBox(height: 16),
                        _buildProfitShareOverviewCard(),
                      ],
                    );
            },
          ),
          const SizedBox(height: 24),

          // Detailed P&L Statement Table
          _buildPnLStatementTable(),
        ],
      ),
    );
  }

  Widget _buildStoreSalesChart() {
    final stores = profit.salesByStore.keys.toList();
    final values = profit.salesByStore.values.toList();
    final maxVal = values.fold<double>(0, (max, v) => v > max ? v : max);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              const Text(
                'เปรียบเทียบยอดขาย 3 ร้านค้า',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                'รวม: ฿${currency.format(profit.totalRevenue)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxVal > 0 ? maxVal * 1.2 : 1000,
                barGroups: List.generate(stores.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: values[i],
                        color: i == 0
                            ? Colors.indigo
                            : (i == 1 ? Colors.blue.shade600 : Colors.teal.shade600),
                        width: 28,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < stores.length) {
                          final shortName = stores[idx].replaceAll('Signature สาขา ', '');
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              shortName,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitShareOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              const Text(
                'สรุปการแบ่งปันผลกำไร 50 / 50',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'กำไรจัดสรร: ฿${currency.format(profit.netDistributableProfit)}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Group 1 Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.indigo.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('กลุ่มที่ 1 (50% แรก)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    SizedBox(height: 2),
                    Text('🟣 Nantaporn & 🔵 Thayakorn', style: TextStyle(fontSize: 11, color: Colors.indigo)),
                  ],
                ),
                Text(
                  '฿${currency.format(profit.group1Share)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Group 2 Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('กลุ่มที่ 2 (50% หลัง)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    SizedBox(height: 2),
                    Text('🟢 Churntawan & 🟠 Kanthong', style: TextStyle(fontSize: 11, color: Colors.green)),
                  ],
                ),
                Text(
                  '฿${currency.format(profit.group2Share)}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green.shade800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPnLStatementTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: const Row(
              children: [
                Icon(Icons.table_chart, size: 18, color: Colors.indigo),
                SizedBox(width: 8),
                Text('งบกำไรขาดทุนละเอียด (Comprehensive P&L Statement)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _pnlRow('1. รายรับจากการขาย 3 ร้านค้า (Total Revenue)', profit.totalRevenue, isHeader: true, color: Colors.indigo),
                ...profit.salesByStore.entries.map((e) => _pnlSubRow('   - ${e.key}', e.value)),
                const Divider(height: 24),
                _pnlRow('2. ค่าใช้จ่ายดำเนินงานร้านค้า (Operating Expenses)', profit.totalOperatingExpenses, isHeader: true, color: Colors.purple.shade700),
                ...profit.expensesByCategory.entries.map((e) => _pnlSubRow('   - ${e.key}', e.value)),
                const Divider(height: 24),
                _pnlRow('3. ต้นทุนพนักงาน Signature Payroll (Staff Labor Cost)', profit.totalStaffPayroll, isHeader: true, color: Colors.blue.shade700),
                _pnlSubRow('   - เงินเดือนสุทธิพนักงานที่จ่ายจริง (Net Pay)', profit.totalStaffPayroll),
                _pnlSubRow('   - เงินที่พนักงานเบิกล่วงหน้า (Staff Advances)', profit.totalStaffAdvances, isDeduction: true),
                const Divider(height: 24),
                _pnlRow('4. กำไรจากการดำเนินงานร้าน (Operating Profit)', profit.operatingProfit, isHeader: true, isHighlight: true),
                const SizedBox(height: 8),
                _pnlRow('5. หัก ค่าตอบแทน/เงินเดือนผู้บริหาร 4 ท่าน (รวม ฿85,000)', ProfitDistribution.totalExecutiveSalaries, isHeader: true, color: Colors.orange.shade800),
                _pnlSubRow('   - Nantaporn (เงินเดือน ฿30,000)', ProfitDistribution.nantapornSalary),
                _pnlSubRow('   - Thayakorn (เงินเดือน ฿30,000)', ProfitDistribution.thayakornSalary),
                _pnlSubRow('   - Churntawan (เงินเดือน ฿25,000)', ProfitDistribution.churntawanSalary),
                _pnlSubRow('   - Kanthong (เงินเดือน ฿0)', ProfitDistribution.kanthongSalary),
                const Divider(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: profit.netDistributableProfit >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: profit.netDistributableProfit >= 0 ? Colors.green.shade300 : Colors.red.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'กำไรสุทธิสำหรับจัดสรร 50/50 (Net Distributable Profit)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: profit.netDistributableProfit >= 0 ? Colors.green.shade900 : Colors.red.shade900,
                        ),
                      ),
                      Text(
                        '฿${currency.format(profit.netDistributableProfit)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: profit.netDistributableProfit >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pnlRow(String label, double amount, {bool isHeader = false, bool isHighlight = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isHeader ? FontWeight.bold : FontWeight.w500,
              fontSize: isHeader ? 13 : 12,
              color: color ?? Colors.grey.shade900,
            ),
          ),
          Text(
            '฿${currency.format(amount)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isHighlight ? 15 : (isHeader ? 13 : 12),
              color: color ?? Colors.grey.shade900,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _pnlSubRow(String label, double amount, {bool isDeduction = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          Text(
            '฿${currency.format(amount)}',
            style: TextStyle(fontSize: 11, color: isDeduction ? Colors.amber.shade900 : Colors.grey.shade700, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}
