import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/profit_distribution.dart';

class ProfitSharingScreen extends StatelessWidget {
  final ProfitDistribution profit;
  final NumberFormat currency = NumberFormat('#,##0.00', 'en_US');

  ProfitSharingScreen({super.key, required this.profit});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade700, Colors.purple.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'การจัดสรรผลกำไร 50 / 50 & เคลียร์เงินสุทธิ 4 หุ้นส่วน',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'กำไรสุทธิหลังหักค่าใช้จ่ายร้าน, ค่าแรงพนักงาน, และเงินเดือนผู้บริหาร ฿${currency.format(profit.totalExecutiveSalaries)}',
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('กำไรจัดสรรสุทธิ', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      Text(
                        '฿${currency.format(profit.netDistributableProfit)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Two Groups 50 / 50 Comparison
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              return isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildGroup1Card()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildGroup2Card()),
                      ],
                    )
                  : Column(
                      children: [
                        _buildGroup1Card(),
                        const SizedBox(height: 16),
                        _buildGroup2Card(),
                      ],
                    );
            },
          ),
          const SizedBox(height: 24),

          // Detailed Table of 4 Partners
          _buildPartnerSummaryTable(),
        ],
      ),
    );
  }

  Widget _buildGroup1Card() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.shade200),
        boxShadow: [
          BoxShadow(color: Colors.indigo.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.pie_chart, color: Colors.indigo, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text('กลุ่มที่ 1: ส่วนแบ่งกำไร ${profit.config.group1Percent.toStringAsFixed(0)}% แรก', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              Text(
                '฿${currency.format(profit.group1Share)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigo, fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _partnerSubCard(
            name: '🟣 Nantaporn',
            role: 'บริหารการเงิน & บัญชีกองกลางร้าน',
            reimbursement: profit.nantapornExpensesPaid,
            salary: profit.nantapornSalary,
            profitShare: profit.nantapornProfitShare,
            totalPayout: profit.nantapornNetPayout,
            color: Colors.purple,
          ),
          const SizedBox(height: 12),
          _partnerSubCard(
            name: '🔵 Thayakorn',
            role: 'บริหารงานฝ่ายปฏิบัติการ',
            reimbursement: profit.thayakornExpensesPaid,
            salary: profit.thayakornSalary,
            profitShare: profit.thayakornProfitShare,
            totalPayout: profit.thayakornNetPayout,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildGroup2Card() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade200),
        boxShadow: [
          BoxShadow(color: Colors.teal.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.pie_chart, color: Colors.teal, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text('กลุ่มที่ 2: ส่วนแบ่งกำไร ${profit.config.group2Percent.toStringAsFixed(0)}% หลัง', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              Text(
                '฿${currency.format(profit.group2Share)}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.teal.shade800, fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _partnerSubCard(
            name: '🟢 Churntawan',
            role: 'บริหารจัดการทั่วไป',
            reimbursement: profit.churntawanExpensesPaid,
            salary: profit.churntawanSalary,
            profitShare: profit.churntawanProfitShare,
            totalPayout: profit.churntawanNetPayout,
            color: Colors.teal,
          ),
          const SizedBox(height: 12),
          _partnerSubCard(
            name: '🟠 Kanthong',
            role: 'ผู้ถือหุ้นร่วม',
            reimbursement: profit.kanthongExpensesPaid,
            salary: profit.kanthongSalary,
            profitShare: profit.kanthongProfitShare,
            totalPayout: profit.kanthongNetPayout,
            color: Colors.amber.shade800,
          ),
        ],
      ),
    );
  }

  Widget _partnerSubCard({
    required String name,
    required String role,
    required double reimbursement,
    required double salary,
    required double profitShare,
    required double totalPayout,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
              Text(role, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const Divider(height: 16),
          _subCardRow('เคลียร์คืนสำรองจ่าย:', '฿${currency.format(reimbursement)}'),
          _subCardRow('เงินเดือนประจำตำแหน่ง:', '฿${currency.format(salary)}'),
          _subCardRow('ส่วนแบ่งกำไรสุทธิ (25%):', '฿${currency.format(profitShare)}'),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('รวมเงินรับสุทธิ (Net Payout):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                Text(
                  '฿${currency.format(totalPayout)}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _subCardRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(val, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildPartnerSummaryTable() {
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
                Icon(Icons.format_list_bulleted, size: 18, color: Colors.indigo),
                SizedBox(width: 8),
                Text('ตารางสรุปเงินเคลียร์สุทธิรายบุคคล (Reimbursement & Payout Table)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('ผู้ถือหุ้น / หุ้นส่วน', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('กลุ่มสัดส่วน', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('เงินสำรองจ่ายที่ควักไป', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('เงินเดือนประจำตำแหน่ง', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('ส่วนแบ่งกำไรสุทธิ', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('รวมยอดเงินรับสุทธิ', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: [
                _partnerRow('Nantaporn', 'กลุ่มที่ 1 (${profit.config.getPartnerProfitShare('Nantaporn').toStringAsFixed(0)}%)', profit.nantapornExpensesPaid, profit.nantapornSalary, profit.nantapornProfitShare, profit.nantapornNetPayout, Colors.purple),
                _partnerRow('Thayakorn', 'กลุ่มที่ 1 (${profit.config.getPartnerProfitShare('Thayakorn').toStringAsFixed(0)}%)', profit.thayakornExpensesPaid, profit.thayakornSalary, profit.thayakornProfitShare, profit.thayakornNetPayout, Colors.blue),
                _partnerRow('Churntawan', 'กลุ่มที่ 2 (${profit.config.getPartnerProfitShare('Churntawan').toStringAsFixed(0)}%)', profit.churntawanExpensesPaid, profit.churntawanSalary, profit.churntawanProfitShare, profit.churntawanNetPayout, Colors.teal),
                _partnerRow('Kanthong', 'กลุ่มที่ 2 (${profit.config.getPartnerProfitShare('Kanthong').toStringAsFixed(0)}%)', profit.kanthongExpensesPaid, profit.kanthongSalary, profit.kanthongProfitShare, profit.kanthongNetPayout, Colors.amber.shade800),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataRow _partnerRow(String name, String group, double exp, double salary, double profitShare, double total, Color color) {
    return DataRow(
      cells: [
        DataCell(Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: color))),
        DataCell(Text(group, style: const TextStyle(fontSize: 12))),
        DataCell(Text('฿${currency.format(exp)}', style: const TextStyle(fontFamily: 'monospace'))),
        DataCell(Text('฿${currency.format(salary)}', style: const TextStyle(fontFamily: 'monospace'))),
        DataCell(Text('฿${currency.format(profitShare)}', style: const TextStyle(fontFamily: 'monospace', color: Colors.indigo))),
        DataCell(
          Text(
            '฿${currency.format(total)}',
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }
}
