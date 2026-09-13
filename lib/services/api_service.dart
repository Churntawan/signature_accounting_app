import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/daily_sale.dart';
import '../models/store_expense.dart';
import '../models/employee.dart';
import '../models/staff_payroll_item.dart';
import 'payroll_calculation_service.dart';

class ApiService {
  static const String supabaseUrl = 'https://qsmigegcefcbohmufywh.supabase.co/rest/v1';
  static const String supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFzbWlnZWdjZWZjYm9obXVmeXdoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkwNDM4MDAsImV4cCI6MjEwNDYxOTgwMH0.jIEkmGeSVzht81fGEQnxOM-n9TGG7AFumkFEe5SVGTk';

  static Map<String, String> get _headers => {
        'apikey': supabaseKey,
        'Authorization': 'Bearer $supabaseKey',
        'Content-Type': 'application/json',
      };

  // Local fallback caches when offline or before SQL schema is run on Supabase
  static final Map<String, List<DailySale>> _localSalesCache = {};
  static final Map<String, List<StoreExpense>> _localExpensesCache = {};

  // 1. Generate Rolling Periods
  static List<String> generatePeriods() {
    final now = DateTime.now();
    const startYear = 2024;
    final endYear = now.year >= 2026 ? now.year + 2 : 2028;

    final List<String> periods = [];
    for (int y = endYear; y >= startYear; y--) {
      for (int m = 12; m >= 1; m--) {
        periods.add('$y-${m.toString().padLeft(2, '0')}');
      }
    }
    return periods;
  }

  // 2. Check Supabase connection
  static Future<bool> checkConnection() async {
    try {
      final res = await http
          .get(Uri.parse('$supabaseUrl/employees?select=ep_code&limit=1'), headers: _headers)
          .timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // 3. Fetch Sales
  static Future<List<DailySale>> fetchSales(String period) async {
    try {
      final res = await http
          .get(
            Uri.parse('$supabaseUrl/store_sales?period=eq.$period&order=date.desc'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        final sales = list.map((item) => DailySale.fromJson(item)).toList();
        _localSalesCache[period] = sales;
        return sales;
      }
    } catch (_) {}

    return _localSalesCache[period] ?? [];
  }

  // 4. Save Sale
  static Future<bool> saveSale(DailySale sale) async {
    try {
      final res = await http
          .post(
            Uri.parse('$supabaseUrl/store_sales'),
            headers: _headers,
            body: jsonEncode(sale.toJson()),
          )
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200 || res.statusCode == 201) {
        return true;
      }
    } catch (_) {}

    // Fallback to local cache
    final current = _localSalesCache[sale.period] ?? [];
    final newSale = DailySale(
      id: 'LOCAL_${DateTime.now().millisecondsSinceEpoch}',
      date: sale.date,
      storeName: sale.storeName,
      totalAmount: sale.totalAmount,
      cashAmount: sale.cashAmount,
      qrAmount: sale.qrAmount,
      creditAmount: sale.creditAmount,
      alipayAmount: sale.alipayAmount,
      note: sale.note,
      period: sale.period,
    );
    current.insert(0, newSale);
    _localSalesCache[sale.period] = current;
    return true;
  }

  // 5. Delete Sale
  static Future<bool> deleteSale(dynamic id, String period) async {
    try {
      if (id != null && !id.toString().startsWith('LOCAL_')) {
        await http
            .delete(
              Uri.parse('$supabaseUrl/store_sales?id=eq.$id'),
              headers: _headers,
            )
            .timeout(const Duration(seconds: 5));
      }
    } catch (_) {}

    final current = _localSalesCache[period] ?? [];
    current.removeWhere((s) => s.id == id);
    _localSalesCache[period] = current;
    return true;
  }

  // 6. Fetch Expenses
  static Future<List<StoreExpense>> fetchExpenses(String period) async {
    try {
      final res = await http
          .get(
            Uri.parse('$supabaseUrl/store_expenses?period=eq.$period&order=date.desc'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        final expenses = list.map((item) => StoreExpense.fromJson(item)).toList();
        _localExpensesCache[period] = expenses;
        return expenses;
      }
    } catch (_) {}

    return _localExpensesCache[period] ?? [];
  }

  // 7. Save Expense
  static Future<bool> saveExpense(StoreExpense expense) async {
    try {
      final res = await http
          .post(
            Uri.parse('$supabaseUrl/store_expenses'),
            headers: _headers,
            body: jsonEncode(expense.toJson()),
          )
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200 || res.statusCode == 201) {
        return true;
      }
    } catch (_) {}

    // Fallback to local cache
    final current = _localExpensesCache[expense.period] ?? [];
    final newExp = StoreExpense(
      id: 'LOCAL_${DateTime.now().millisecondsSinceEpoch}',
      date: expense.date,
      storeName: expense.storeName,
      category: expense.category,
      payer: expense.payer,
      amount: expense.amount,
      note: expense.note,
      period: expense.period,
      status: expense.status,
    );
    current.insert(0, newExp);
    _localExpensesCache[expense.period] = current;
    return true;
  }

  // 8. Delete Expense
  static Future<bool> deleteExpense(dynamic id, String period) async {
    try {
      if (id != null && !id.toString().startsWith('LOCAL_')) {
        await http
            .delete(
              Uri.parse('$supabaseUrl/store_expenses?id=eq.$id'),
              headers: _headers,
            )
            .timeout(const Duration(seconds: 5));
      }
    } catch (_) {}

    final current = _localExpensesCache[period] ?? [];
    current.removeWhere((e) => e.id == id);
    _localExpensesCache[period] = current;
    return true;
  }

  // 9. Fetch Employees from Supabase
  static Future<List<Employee>> fetchEmployees() async {
    try {
      final res = await http
          .get(
            Uri.parse('$supabaseUrl/employees?select=*&order=ep_code.asc'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((item) => Employee.fromJson(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  // 10. Fetch Attendance from Supabase (filtered by period date window to avoid 1,000 row truncation)
  static Future<List<Map<String, dynamic>>> fetchAttendance([String? period]) async {
    try {
      String query = '$supabaseUrl/attendance_log?select=*&order=date.asc';
      if (period != null && period.contains('-')) {
        final parts = period.split('-');
        final y = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        // Date ranges for all 3 cycles (1, 10, 20) span between (m-1)-01 and m-25
        final fromDate = DateTime(y, m - 1, 1).toIso8601String().split('T').first;
        final toDate = DateTime(y, m, 25).toIso8601String().split('T').first;
        query = '$supabaseUrl/attendance_log?date=gte.$fromDate&date=lte.$toDate&order=date.asc';
      }
      final res = await http
          .get(
            Uri.parse(query),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list
            .map((e) => Map<String, dynamic>.from(e))
            .where((e) => !(e['category']?.toString().startsWith('Request:') ?? false))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  // 11. Fetch Payroll Adjustments from Supabase
  static Future<List<Map<String, dynamic>>> fetchPayrollAdjustments(String period) async {
    try {
      final res = await http
          .get(
            Uri.parse('$supabaseUrl/payroll_adjustments?period=eq.$period&order=due_date.desc'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  // 12. Fetch Payroll Summary Snapshots from Supabase
  static Future<List<Map<String, dynamic>>> fetchPayrollSummary(String period) async {
    try {
      final res = await http
          .get(
            Uri.parse('$supabaseUrl/payroll_summary?period=eq.$period&order=ep_code.asc'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  // 13. Fetch Live Staff Payroll (Real-time dynamic calculation across all active staff)
  static Future<List<StaffPayrollItem>> fetchLiveStaffPayroll(String period) async {
    try {
      final results = await Future.wait([
        fetchEmployees(),
        fetchAttendance(period),
        fetchPayrollAdjustments(period),
        fetchPayrollSummary(period),
      ]);

      final employees = results[0] as List<Employee>;
      final attendance = results[1] as List<Map<String, dynamic>>;
      final adjustments = results[2] as List<Map<String, dynamic>>;
      final savedSummary = results[3] as List<Map<String, dynamic>>;

      if (employees.isNotEmpty) {
        return PayrollCalculationService.computeStaffPayroll(
          employees: employees,
          period: period,
          attendanceLogs: attendance,
          adjustments: adjustments,
          savedSummary: savedSummary,
        );
      }
    } catch (_) {}

    return [];
  }

  // 14. Sync & Upsert complete calculated payroll to Supabase payroll_summary
  static Future<bool> syncPayrollSummaryToCloud(List<StaffPayrollItem> items) async {
    if (items.isEmpty) return true;
    try {
      final upsertHeaders = Map<String, String>.from(_headers);
      upsertHeaders['Prefer'] = 'resolution=merge-duplicates';

      final payload = items.map((i) => i.toJson()).toList();
      final res = await http.post(
        Uri.parse('$supabaseUrl/payroll_summary?on_conflict=period,ep_code'),
        headers: upsertHeaders,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}
