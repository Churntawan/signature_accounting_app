import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'models/daily_sale.dart';
import 'models/store_expense.dart';
import 'models/profit_distribution.dart';
import 'models/staff_payroll_item.dart';
import 'services/api_service.dart';
import 'services/accounting_engine.dart';
import 'widgets/period_selector_bar.dart';
import 'widgets/sale_entry_dialog.dart';
import 'widgets/expense_entry_dialog.dart';
import 'screens/dashboard_screen.dart';
import 'screens/daily_sales_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/payroll_sync_screen.dart';
import 'screens/profit_sharing_screen.dart';
import 'screens/printable_report_screen.dart';
import 'services/settings_service.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th', null);
  await SettingsService.init();
  runApp(const SignatureAccountingApp());
}

class SignatureAccountingApp extends StatelessWidget {
  const SignatureAccountingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Signature P&L Suite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          primary: Colors.indigo,
          secondary: Colors.purple.shade700,
        ),
        textTheme: GoogleFonts.sarabunTextTheme(
          Theme.of(context).textTheme,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
      ),
      home: const MainAccountingScreen(),
    );
  }
}

class MainAccountingScreen extends StatefulWidget {
  const MainAccountingScreen({super.key});

  @override
  State<MainAccountingScreen> createState() => _MainAccountingScreenState();
}

class _MainAccountingScreenState extends State<MainAccountingScreen> {
  int _currentTabIndex = 0;
  late String _currentPeriod;
  late List<String> _periods;
  bool _isConnected = false;
  bool _isLoading = false;

  List<DailySale> _sales = [];
  List<StoreExpense> _expenses = [];
  List<StaffPayrollItem> _staffPayroll = [];
  List<Map<String, dynamic>> _payrollAdjustments = [];

  @override
  void initState() {
    super.initState();
    _periods = ApiService.generatePeriods();
    final now = DateTime.now();
    _currentPeriod = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    SettingsService.configNotifier.addListener(_onConfigChanged);
    _initData();
  }

  void _onConfigChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    SettingsService.configNotifier.removeListener(_onConfigChanged);
    super.dispose();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    _isConnected = await ApiService.checkConnection();
    await _loadPeriodData();
    setState(() => _isLoading = false);
  }

  Future<void> _loadPeriodData() async {
    final results = await Future.wait([
      ApiService.fetchSales(_currentPeriod),
      ApiService.fetchExpenses(_currentPeriod),
      ApiService.fetchLiveStaffPayroll(_currentPeriod),
      ApiService.fetchPayrollAdjustments(_currentPeriod),
    ]);

    setState(() {
      _sales = results[0] as List<DailySale>;
      _expenses = results[1] as List<StoreExpense>;
      _staffPayroll = results[2] as List<StaffPayrollItem>;
      _payrollAdjustments = results[3] as List<Map<String, dynamic>>;
    });
  }

  ProfitDistribution get _computedProfit {
    return AccountingEngine.compute(
      sales: _sales,
      expenses: _expenses,
      staffPayroll: _staffPayroll,
      payrollAdjustments: _payrollAdjustments,
    );
  }

  void _onAddSale() {
    showDialog(
      context: context,
      builder: (ctx) => SaleEntryDialog(
        currentPeriod: _currentPeriod,
        onSave: (sale) async {
          setState(() => _isLoading = true);
          await ApiService.saveSale(sale);
          await _loadPeriodData();
          setState(() => _isLoading = false);
        },
      ),
    );
  }

  void _onAddExpense() {
    showDialog(
      context: context,
      builder: (ctx) => ExpenseEntryDialog(
        currentPeriod: _currentPeriod,
        onSave: (exp) async {
          setState(() => _isLoading = true);
          await ApiService.saveExpense(exp);
          await _loadPeriodData();
          setState(() => _isLoading = false);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profit = _computedProfit;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.indigo, Colors.purple.shade700]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.analytics, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Signature P&L Suite',
                    style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo.shade900),
                  ),
                  const Text(
                    'ระบบบัญชี 3 ร้านค้า • สรุปกำไร 50/50 • Real-time Sync ร่วมกับ Signature Payroll',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(115),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PeriodSelectorBar(
                currentPeriod: _currentPeriod,
                periods: _periods,
                isConnected: _isConnected,
                onPeriodChanged: (newPeriod) {
                  setState(() => _currentPeriod = newPeriod);
                  _loadPeriodData();
                },
                onRefresh: _loadPeriodData,
                onAddSale: _onAddSale,
                onAddExpense: _onAddExpense,
              ),
              _buildTabBar(),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: _currentTabIndex,
            children: [
              DashboardScreen(profit: profit),
              DailySalesScreen(
                sales: _sales,
                onAddSale: (sale) => _onAddSale(),
                onDeleteSale: (id) async {
                  setState(() => _isLoading = true);
                  await ApiService.deleteSale(id, _currentPeriod);
                  await _loadPeriodData();
                  setState(() => _isLoading = false);
                },
              ),
              ExpensesScreen(
                expenses: _expenses,
                profit: profit,
                onAddExpense: (exp) => _onAddExpense(),
                onDeleteExpense: (id) async {
                  setState(() => _isLoading = true);
                  await ApiService.deleteExpense(id, _currentPeriod);
                  await _loadPeriodData();
                  setState(() => _isLoading = false);
                },
              ),
              PayrollSyncScreen(
                staffPayroll: _staffPayroll,
                payrollAdjustments: _payrollAdjustments,
                period: _currentPeriod,
                onRefresh: _loadPeriodData,
              ),
              ProfitSharingScreen(profit: profit),
              PrintableReportScreen(profit: profit, period: _currentPeriod),
              SettingsScreen(onConfigSaved: () => setState(() {})),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('กำลังโหลดข้อมูลบัญชีและเงินเดือนพนักงาน...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _tabItem(0, 'แดชบอร์ดสรุป (Dashboard)', Icons.dashboard_outlined),
            _tabItem(1, 'ยอดขายประจำวัน (Sales)', Icons.point_of_sale_outlined),
            _tabItem(2, 'รายจ่ายร้านค้า (Expenses)', Icons.receipt_long_outlined),
            _tabItem(3, 'ต้นทุนเงินเดือนพนักงาน (Payroll)', Icons.people_alt_outlined),
            _tabItem(4, 'การแบ่งกำไร 50/50 (Distributions)', Icons.pie_chart_outline),
            _tabItem(5, 'พิมพ์รายงานสรุป (Report)', Icons.print_outlined),
            _tabItem(6, 'ตั้งค่าระบบ (Settings)', Icons.settings_outlined),
          ],
        ),
      ),
    );
  }

  Widget _tabItem(int index, String title, IconData icon) {
    final isSelected = _currentTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.indigo : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.indigo : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.indigo : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
