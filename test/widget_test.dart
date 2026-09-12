import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signature_accounting_app/models/profit_distribution.dart';
import 'package:signature_accounting_app/screens/dashboard_screen.dart';
import 'package:signature_accounting_app/screens/profit_sharing_screen.dart';

void main() {
  final sampleProfit = ProfitDistribution(
    totalRevenue: 350000.0,
    salesByStore: {
      'Signature สาขา Big Shop': 150000.0,
      'Signature สาขา Cabana': 120000.0,
      'Seaside': 80000.0,
    },
    totalOperatingExpenses: 100000.0,
    expensesByPayer: {
      'Nantaporn': 50000.0,
      'Thayakorn': 30000.0,
      'Churntawan': 20000.0,
      'Kanthong': 0.0,
      'กองกลางร้าน (Store Cash)': 0.0,
    },
    expensesByCategory: {
      'วัตถุดิบและสต็อกสินค้า': 50000.0,
      'ค่าเช่าสถานที่': 30000.0,
      'สาธารณูปโภค': 20000.0,
    },
    totalStaffPayroll: 55000.0,
    totalStaffAdvances: 3500.0,
    staffCount: 4,
  );

  testWidgets('DashboardScreen renders P&L and 3 stores correctly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardScreen(profit: sampleProfit),
        ),
      ),
    );

    expect(find.text('ยอดขายรวม 3 ร้าน'), findsOneWidget);
    expect(find.text('กำไรสุทธิจัดสรร 50/50'), findsOneWidget);
  });

  testWidgets('ProfitSharingScreen renders 50/50 and 4 partners correctly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfitSharingScreen(profit: sampleProfit),
        ),
      ),
    );

    expect(find.text('กลุ่มที่ 1: ส่วนแบ่งกำไร 50% แรก'), findsOneWidget);
    expect(find.text('กลุ่มที่ 2: ส่วนแบ่งกำไร 50% หลัง'), findsOneWidget);
    expect(find.text('🟣 Nantaporn'), findsOneWidget);
    expect(find.text('🔵 Thayakorn'), findsOneWidget);
    expect(find.text('🟢 Churntawan'), findsOneWidget);
    expect(find.text('🟠 Kanthong'), findsOneWidget);
  });
}
