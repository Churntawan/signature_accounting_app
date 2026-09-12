import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_config.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onConfigSaved;

  const SettingsScreen({super.key, required this.onConfigSaved});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NumberFormat _currency = NumberFormat('#,##0.00', 'en_US');

  late List<String> _stores;
  late List<String> _payers;
  late List<PartnerConfig> _partners;
  final Map<String, TextEditingController> _salaryControllers = {};
  final Map<String, TextEditingController> _shareControllers = {};

  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _loadFromCurrentConfig();
  }

  void _loadFromCurrentConfig() {
    final conf = SettingsService.config;
    _stores = List.from(conf.stores);
    _payers = List.from(conf.payers);
    _partners = conf.partners.map((p) => p.copyWith()).toList();

    _salaryControllers.clear();
    _shareControllers.clear();
    for (var p in _partners) {
      _salaryControllers[p.name] =
          TextEditingController(text: p.executiveSalary.toStringAsFixed(0));
      _shareControllers[p.name] =
          TextEditingController(text: p.profitSharePercent.toStringAsFixed(1));
    }
    _isDirty = false;
  }

  @override
  void dispose() {
    for (var c in _salaryControllers.values) {
      c.dispose();
    }
    for (var c in _shareControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _totalExecSalaries {
    double sum = 0.0;
    for (var p in _partners) {
      final val = double.tryParse(_salaryControllers[p.name]?.text ?? '') ??
          p.executiveSalary;
      sum += val;
    }
    return sum;
  }

  double get _group1TotalShare {
    double sum = 0.0;
    for (var p in _partners.where((x) => x.groupIndex == 1)) {
      sum += double.tryParse(_shareControllers[p.name]?.text ?? '') ??
          p.profitSharePercent;
    }
    return sum;
  }

  double get _group2TotalShare {
    double sum = 0.0;
    for (var p in _partners.where((x) => x.groupIndex == 2)) {
      sum += double.tryParse(_shareControllers[p.name]?.text ?? '') ??
          p.profitSharePercent;
    }
    return sum;
  }

  Future<void> _saveAll() async {
    final updatedPartners = _partners.map((p) {
      final sal = double.tryParse(_salaryControllers[p.name]?.text ?? '') ??
          p.executiveSalary;
      final share = double.tryParse(_shareControllers[p.name]?.text ?? '') ??
          p.profitSharePercent;
      return p.copyWith(executiveSalary: sal, profitSharePercent: share);
    }).toList();

    final newConfig = AppConfig(
      stores: _stores,
      payers: _payers,
      partners: updatedPartners,
      startYear: SettingsService.config.startYear,
    );

    final success = await SettingsService.saveConfig(newConfig);
    if (mounted) {
      if (success) {
        setState(() => _isDirty = false);
        widget.onConfigSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('บันทึกการตั้งค่าระบบเรียบร้อยแล้ว (อัปเดตทุกหน้าจอทันที)'),
              ],
            ),
            backgroundColor: Colors.teal,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เกิดข้อผิดพลาดในการบันทึกข้อมูล'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการคืนค่าเริ่มต้น?'),
        content: const Text(
          'ระบบจะรีเซ็ตรายชื่อร้านค้า, เงินเดือนผู้บริหาร (฿85,000) และสัดส่วนกำไร (50/50) กลับเป็นค่ามาตรฐานเริ่มต้น',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('คืนค่าเริ่มต้น', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok == true) {
      await SettingsService.resetToDefaults();
      setState(() {
        _loadFromCurrentConfig();
      });
      widget.onConfigSaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('คืนค่าเริ่มต้นระบบเรียบร้อยแล้ว'),
            backgroundColor: Colors.indigo,
          ),
        );
      }
    }
  }

  void _addStoreDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('เพิ่มสาขาร้านค้าใหม่'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'ระบุชื่อสาขา เช่น Signature สาขา Beachfront',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty && !_stores.contains(text)) {
                setState(() {
                  _stores.add(text);
                  _isDirty = true;
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('เพิ่มสาขา'),
          ),
        ],
      ),
    );
  }

  void _addPayerDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('เพิ่มรายชื่อผู้สำรองจ่าย'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'ระบุชื่อผู้สำรองจ่าย เช่น ผู้จัดการร้าน / หุ้นส่วนใหม่',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty && !_payers.contains(text)) {
                setState(() {
                  _payers.add(text);
                  _isDirty = true;
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('เพิ่ม'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card with Actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueGrey.shade800, Colors.blueGrey.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tune, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ตั้งค่าโครงสร้างธุรกิจ & กฎบัญชี (System Configuration)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ปรับแต่งเงินเดือนผู้บริหาร, เพิ่มสาขาร้านค้า, ผู้สำรองจ่าย และสัดส่วนปันผลกำไรโดยไม่ต้องแก้โค้ด',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 10,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      onPressed: _confirmReset,
                      icon: const Icon(Icons.restore, size: 16),
                      label: const Text('คืนค่าเริ่มต้น'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.tealAccent.shade400,
                        foregroundColor: Colors.teal.shade900,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      onPressed: _saveAll,
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text(
                        'บันทึกการตั้งค่า',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 1: Executive Salaries
          _buildExecutiveSalariesCard(),
          const SizedBox(height: 24),

          // Section 2: Stores & Payers in Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              return isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildStoresCard()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildPayersCard()),
                      ],
                    )
                  : Column(
                      children: [
                        _buildStoresCard(),
                        const SizedBox(height: 16),
                        _buildPayersCard(),
                      ],
                    );
            },
          ),
          const SizedBox(height: 24),

          // Section 3: Profit Sharing Configuration
          _buildProfitSharingCard(),
        ],
      ),
    );
  }

  Widget _buildExecutiveSalariesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.account_balance_wallet,
                        color: Colors.orange.shade800, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'เงินเดือนประจำตำแหน่งผู้บริหาร (Executive Salaries)',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'ยอดนี้จะถูกนำไปหักออกจากกำไรดำเนินงานก่อนแบ่งปันผลกำไรสุทธิ',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const Text('รวมเงินเดือนผู้บริหาร: ',
                        style: TextStyle(fontSize: 12, color: Colors.black87)),
                    Text(
                      '฿${_currency.format(_totalExecSalaries)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Partner Salary Inputs
          Column(
            children: _partners.map((p) {
              final controller = _salaryControllers[p.name]!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            p.role,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          prefixText: '฿ ',
                          suffixText: '/ เดือน',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) {
                          setState(() => _isDirty = true);
                        },
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStoresCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        Icon(Icons.store, color: Colors.blue.shade700, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'สาขาร้านค้า (Stores)',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.blue),
                tooltip: 'เพิ่มสาขาใหม่',
                onPressed: _addStoreDialog,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _stores.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final store = _stores[i];
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.blue.shade100,
                  child: Text('${i + 1}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.blue.shade900)),
                ),
                title: Text(store,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                trailing: _stores.length > 1
                    ? IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: Colors.redAccent),
                        onPressed: () {
                          setState(() {
                            _stores.removeAt(i);
                            _isDirty = true;
                          });
                        },
                      )
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPayersCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.payments_outlined,
                        color: Colors.purple.shade700, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'ผู้สำรองจ่าย (Payers)',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.purple),
                tooltip: 'เพิ่มผู้สำรองจ่าย',
                onPressed: _addPayerDialog,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _payers.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final payer = _payers[i];
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.purple.shade100,
                  child: Icon(Icons.person,
                      size: 14, color: Colors.purple.shade900),
                ),
                title: Text(payer,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                trailing: _payers.length > 1
                    ? IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: Colors.redAccent),
                        onPressed: () {
                          setState(() {
                            _payers.removeAt(i);
                            _isDirty = true;
                          });
                        },
                      )
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfitSharingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.pie_chart_outline,
                        color: Colors.indigo, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'สัดส่วนการแบ่งปันผลกำไร (Profit Sharing Ratios)',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'กำหนดสัดส่วนร้อยละของแต่ละกลุ่มและหุ้นส่วนแต่ละท่าน',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.indigo.shade200),
                ),
                child: Row(
                  children: [
                    Text('กลุ่ม 1: ${_group1TotalShare.toStringAsFixed(1)}%  |  กลุ่ม 2: ${_group2TotalShare.toStringAsFixed(1)}%',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Column(
            children: _partners.map((p) {
              final controller = _shareControllers[p.name]!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: p.groupIndex == 1
                                  ? Colors.indigo.shade50
                                  : Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'กลุ่มที่ ${p.groupIndex}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: p.groupIndex == 1
                                  ? Colors.indigo.shade800
                                  : Colors.teal.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            p.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          suffixText: '%',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) {
                          setState(() => _isDirty = true);
                        },
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
