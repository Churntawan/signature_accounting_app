import 'dart:convert';

class PartnerConfig {
  final String name;
  final String role;
  final double executiveSalary;
  final int groupIndex; // 1 or 2
  final double profitSharePercent; // e.g. 25.0

  PartnerConfig({
    required this.name,
    required this.role,
    required this.executiveSalary,
    required this.groupIndex,
    required this.profitSharePercent,
  });

  PartnerConfig copyWith({
    String? name,
    String? role,
    double? executiveSalary,
    int? groupIndex,
    double? profitSharePercent,
  }) {
    return PartnerConfig(
      name: name ?? this.name,
      role: role ?? this.role,
      executiveSalary: executiveSalary ?? this.executiveSalary,
      groupIndex: groupIndex ?? this.groupIndex,
      profitSharePercent: profitSharePercent ?? this.profitSharePercent,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'role': role,
        'executiveSalary': executiveSalary,
        'groupIndex': groupIndex,
        'profitSharePercent': profitSharePercent,
      };

  factory PartnerConfig.fromJson(Map<String, dynamic> json) {
    return PartnerConfig(
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      executiveSalary: (json['executiveSalary'] as num?)?.toDouble() ?? 0.0,
      groupIndex: (json['groupIndex'] as num?)?.toInt() ?? 1,
      profitSharePercent: (json['profitSharePercent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AppConfig {
  final List<String> stores;
  final List<String> payers;
  final List<PartnerConfig> partners;
  final int startYear;

  AppConfig({
    required this.stores,
    required this.payers,
    required this.partners,
    this.startYear = 2024,
  });

  factory AppConfig.defaults() {
    return AppConfig(
      stores: [
        'Signature สาขา Big Shop',
        'Signature สาขา Cabana',
        'Seaside',
      ],
      payers: [
        'Nantaporn',
        'Thayakorn',
        'Churntawan',
        'Kanthong',
        'กองกลางร้าน (Store Cash)',
      ],
      partners: [
        PartnerConfig(
          name: 'Nantaporn',
          role: 'บริหารการเงิน & บัญชีกองกลางร้าน',
          executiveSalary: 30000.0,
          groupIndex: 1,
          profitSharePercent: 25.0,
        ),
        PartnerConfig(
          name: 'Thayakorn',
          role: 'บริหารฝ่ายปฏิบัติการ & หน้าร้าน',
          executiveSalary: 30000.0,
          groupIndex: 1,
          profitSharePercent: 25.0,
        ),
        PartnerConfig(
          name: 'Churntawan',
          role: 'บริหารงานทั่วไป & เทคโนโลยี',
          executiveSalary: 25000.0,
          groupIndex: 2,
          profitSharePercent: 25.0,
        ),
        PartnerConfig(
          name: 'Kanthong',
          role: 'ผู้ร่วมถือหุ้นเชิงกลยุทธ์',
          executiveSalary: 0.0,
          groupIndex: 2,
          profitSharePercent: 25.0,
        ),
      ],
      startYear: 2024,
    );
  }

  double get totalExecutiveSalaries =>
      partners.fold(0.0, (sum, p) => sum + p.executiveSalary);

  double get group1Percent => partners
      .where((p) => p.groupIndex == 1)
      .fold(0.0, (sum, p) => sum + p.profitSharePercent);

  double get group2Percent => partners
      .where((p) => p.groupIndex == 2)
      .fold(0.0, (sum, p) => sum + p.profitSharePercent);

  double getPartnerSalary(String name) {
    try {
      return partners.firstWhere((p) => p.name == name).executiveSalary;
    } catch (_) {
      return 0.0;
    }
  }

  double getPartnerProfitShare(String name) {
    try {
      return partners.firstWhere((p) => p.name == name).profitSharePercent;
    } catch (_) {
      return 0.0;
    }
  }

  String getPartnerRole(String name) {
    try {
      return partners.firstWhere((p) => p.name == name).role;
    } catch (_) {
      return '';
    }
  }

  int getPartnerGroup(String name) {
    try {
      return partners.firstWhere((p) => p.name == name).groupIndex;
    } catch (_) {
      return 1;
    }
  }

  AppConfig copyWith({
    List<String>? stores,
    List<String>? payers,
    List<PartnerConfig>? partners,
    int? startYear,
  }) {
    return AppConfig(
      stores: stores ?? List.from(this.stores),
      payers: payers ?? List.from(this.payers),
      partners: partners ?? List.from(this.partners),
      startYear: startYear ?? this.startYear,
    );
  }

  Map<String, dynamic> toJson() => {
        'stores': stores,
        'payers': payers,
        'partners': partners.map((p) => p.toJson()).toList(),
        'startYear': startYear,
      };

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final defaultConf = AppConfig.defaults();

    List<String> loadedStores = defaultConf.stores;
    if (json['stores'] is List) {
      loadedStores = (json['stores'] as List)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    List<String> loadedPayers = defaultConf.payers;
    if (json['payers'] is List) {
      loadedPayers = (json['payers'] as List)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    List<PartnerConfig> loadedPartners = defaultConf.partners;
    if (json['partners'] is List) {
      loadedPartners = (json['partners'] as List)
          .map((e) => PartnerConfig.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final loadedYear = (json['startYear'] as num?)?.toInt() ?? 2024;

    return AppConfig(
      stores: loadedStores.isNotEmpty ? loadedStores : defaultConf.stores,
      payers: loadedPayers.isNotEmpty ? loadedPayers : defaultConf.payers,
      partners: loadedPartners.isNotEmpty ? loadedPartners : defaultConf.partners,
      startYear: loadedYear,
    );
  }

  String serialize() => jsonEncode(toJson());

  static AppConfig deserialize(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return AppConfig.fromJson(decoded);
      }
    } catch (_) {}
    return AppConfig.defaults();
  }
}
