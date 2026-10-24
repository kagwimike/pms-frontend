// PMS Pro — Double-Entry Accounting Domain Models

class AccountModel {
  final int id;
  final String accountCode;
  final String accountName;
  final String accountType; // ASSET, LIABILITY, EQUITY, REVENUE, EXPENSE
  final String normalBalance; // DEBIT, CREDIT
  final String category;
  final String? description;
  final int? parentId;
  final bool isSystem;
  final bool isActive;
  final String currency;
  final List<AccountModel> subAccounts;

  AccountModel({
    required this.id,
    required this.accountCode,
    required this.accountName,
    required this.accountType,
    required this.normalBalance,
    required this.category,
    this.description,
    this.parentId,
    required this.isSystem,
    required this.isActive,
    required this.currency,
    this.subAccounts = const [],
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      accountCode: json['account_code']?.toString() ?? '',
      accountName: json['account_name']?.toString() ?? '',
      accountType: json['account_type']?.toString() ?? 'ASSET',
      normalBalance: json['normal_balance']?.toString() ?? 'DEBIT',
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString(),
      parentId: json['parent_id'] != null ? int.tryParse(json['parent_id'].toString()) : null,
      isSystem: json['is_system'] == true || json['is_system'] == 1,
      isActive: json['is_active'] != false && json['is_active'] != 0,
      currency: json['currency']?.toString() ?? 'KES',
      subAccounts: (json['sub_accounts'] as List<dynamic>?)
              ?.map((s) => AccountModel.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class JournalLineModel {
  final int id;
  final int accountId;
  final String accountCode;
  final String accountName;
  final double debit;
  final double credit;
  final String? description;
  final int? propertyId;
  final String? propertyName;
  final int? unitId;
  final int? tenantId;
  final String? tenantName;
  final int? ownerId;
  final int? vendorId;

  JournalLineModel({
    required this.id,
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    required this.debit,
    required this.credit,
    this.description,
    this.propertyId,
    this.propertyName,
    this.unitId,
    this.tenantId,
    this.tenantName,
    this.ownerId,
    this.vendorId,
  });

  factory JournalLineModel.fromJson(Map<String, dynamic> json) {
    final acc = json['account'] as Map<String, dynamic>?;
    final prop = json['property'] as Map<String, dynamic>?;
    final ten = json['tenant'] as Map<String, dynamic>?;

    return JournalLineModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      accountId: json['account_id'] is int ? json['account_id'] : int.tryParse(json['account_id']?.toString() ?? '0') ?? 0,
      accountCode: acc?['account_code']?.toString() ?? json['account_code']?.toString() ?? '',
      accountName: acc?['account_name']?.toString() ?? json['account_name']?.toString() ?? 'Account',
      debit: double.tryParse(json['debit']?.toString() ?? '0') ?? 0.0,
      credit: double.tryParse(json['credit']?.toString() ?? '0') ?? 0.0,
      description: json['description']?.toString(),
      propertyId: json['property_id'] != null ? int.tryParse(json['property_id'].toString()) : null,
      propertyName: prop?['title']?.toString() ?? prop?['name']?.toString(),
      unitId: json['unit_id'] != null ? int.tryParse(json['unit_id'].toString()) : null,
      tenantId: json['tenant_id'] != null ? int.tryParse(json['tenant_id'].toString()) : null,
      tenantName: ten != null ? '${ten['first_name'] ?? ''} ${ten['last_name'] ?? ''}'.trim() : null,
      ownerId: json['owner_id'] != null ? int.tryParse(json['owner_id'].toString()) : null,
      vendorId: json['vendor_id'] != null ? int.tryParse(json['vendor_id'].toString()) : null,
    );
  }
}

class JournalEntryModel {
  final int id;
  final String entryNumber;
  final String entryDate;
  final String postingDate;
  final String status; // DRAFT, POSTED, REVERSED
  final String sourceType; // MANUAL, INVOICE, PAYMENT, etc.
  final String? sourceId;
  final String? reference;
  final String? description;
  final double totalDebit;
  final double totalCredit;
  final bool isBalanced;
  final int? reversalEntryId;
  final String? reversalReason;
  final List<JournalLineModel> lines;

  JournalEntryModel({
    required this.id,
    required this.entryNumber,
    required this.entryDate,
    required this.postingDate,
    required this.status,
    required this.sourceType,
    this.sourceId,
    this.reference,
    this.description,
    required this.totalDebit,
    required this.totalCredit,
    required this.isBalanced,
    this.reversalEntryId,
    this.reversalReason,
    this.lines = const [],
  });

  factory JournalEntryModel.fromJson(Map<String, dynamic> json) {
    return JournalEntryModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      entryNumber: json['entry_number']?.toString() ?? '',
      entryDate: json['entry_date']?.toString() ?? '',
      postingDate: json['posting_date']?.toString() ?? '',
      status: json['status']?.toString() ?? 'POSTED',
      sourceType: json['source_type']?.toString() ?? 'MANUAL',
      sourceId: json['source_id']?.toString(),
      reference: json['reference']?.toString(),
      description: json['description']?.toString(),
      totalDebit: double.tryParse(json['total_debit']?.toString() ?? '0') ?? 0.0,
      totalCredit: double.tryParse(json['total_credit']?.toString() ?? '0') ?? 0.0,
      isBalanced: json['is_balanced'] == true || json['is_balanced'] == 1,
      reversalEntryId: json['reversal_entry_id'] != null ? int.tryParse(json['reversal_entry_id'].toString()) : null,
      reversalReason: json['reversal_reason']?.toString(),
      lines: (json['lines'] as List<dynamic>?)
              ?.map((l) => JournalLineModel.fromJson(l as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class AccountingPeriodModel {
  final int id;
  final String periodName;
  final int fiscalYear;
  final int periodNumber;
  final String startDate;
  final String endDate;
  final String status; // OPEN, CLOSED, LOCKED
  final String? closeNotes;

  AccountingPeriodModel({
    required this.id,
    required this.periodName,
    required this.fiscalYear,
    required this.periodNumber,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.closeNotes,
  });

  factory AccountingPeriodModel.fromJson(Map<String, dynamic> json) {
    return AccountingPeriodModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      periodName: json['period_name']?.toString() ?? '',
      fiscalYear: json['fiscal_year'] is int ? json['fiscal_year'] : int.tryParse(json['fiscal_year']?.toString() ?? '0') ?? 0,
      periodNumber: json['period_number'] is int ? json['period_number'] : int.tryParse(json['period_number']?.toString() ?? '0') ?? 0,
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      status: json['status']?.toString() ?? 'OPEN',
      closeNotes: json['close_notes']?.toString(),
    );
  }
}

class AccountingDashboardSummary {
  final double totalRentalRevenue;
  final double totalOperatingExpenses;
  final double netOperatingIncome;
  final double tenantArOutstanding;
  final double ownerFundsPayable;
  final double cashAndBankTotal;
  final double openPeriodsCount;
  final double postedJournalsCount;

  AccountingDashboardSummary({
    required this.totalRentalRevenue,
    required this.totalOperatingExpenses,
    required this.netOperatingIncome,
    required this.tenantArOutstanding,
    required this.ownerFundsPayable,
    required this.cashAndBankTotal,
    required this.openPeriodsCount,
    required this.postedJournalsCount,
  });

  factory AccountingDashboardSummary.fromJson(Map<String, dynamic> json) {
    return AccountingDashboardSummary(
      totalRentalRevenue: double.tryParse(json['total_rental_revenue']?.toString() ?? '0') ?? 0.0,
      totalOperatingExpenses: double.tryParse(json['total_operating_expenses']?.toString() ?? '0') ?? 0.0,
      netOperatingIncome: double.tryParse(json['net_operating_income']?.toString() ?? '0') ?? 0.0,
      tenantArOutstanding: double.tryParse(json['tenant_ar_outstanding']?.toString() ?? '0') ?? 0.0,
      ownerFundsPayable: double.tryParse(json['owner_funds_payable']?.toString() ?? '0') ?? 0.0,
      cashAndBankTotal: double.tryParse(json['cash_and_bank_total']?.toString() ?? '0') ?? 0.0,
      openPeriodsCount: double.tryParse(json['open_periods_count']?.toString() ?? '0') ?? 0.0,
      postedJournalsCount: double.tryParse(json['posted_journals_count']?.toString() ?? '0') ?? 0.0,
    );
  }
}
