import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'auth_service.dart';
import 'api_service.dart';
import '../models/accounting_models.dart';

class AccountingService {
  static final AccountingService _instance = AccountingService._internal();
  factory AccountingService() => _instance;
  AccountingService._internal();

  final _auth = AuthService();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_auth.accessToken != null) 'Authorization': 'Bearer ${_auth.accessToken}',
      };

  Map<String, dynamic> _process(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (res.statusCode >= 400) {
        final message = body['message'] ?? 'Accounting Error (Status ${res.statusCode})';
        throw ApiException(message);
      }
      return body;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to parse accounting response');
    }
  }

  // ─── Dashboard Summary ───
  Future<AccountingDashboardSummary> getDashboardSummary({
    String? startDate,
    String? endDate,
    int? propertyId,
  }) async {
    final query = <String, String>{};
    if (startDate != null) query['startDate'] = startDate;
    if (endDate != null) query['endDate'] = endDate;
    if (propertyId != null) query['propertyId'] = propertyId.toString();

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/accounting/dashboard-summary').replace(queryParameters: query.isEmpty ? null : query);
    final res = await http.get(uri, headers: _headers);
    final data = _process(res);
    final map = ApiService.extractMap(data);
    return AccountingDashboardSummary.fromJson(map);
  }

  // ─── Chart of Accounts ───
  Future<List<AccountModel>> getAccounts({String? type, String? category, bool? active}) async {
    final query = <String, String>{};
    if (type != null) query['type'] = type;
    if (category != null) query['category'] = category;
    if (active != null) query['active'] = active.toString();

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/accounting/accounts').replace(queryParameters: query.isEmpty ? null : query);
    final res = await http.get(uri, headers: _headers);
    final data = _process(res);
    final list = ApiService.extractList(data);
    return list.map((e) => AccountModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AccountModel> createAccount(Map<String, dynamic> data) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/accounting/accounts');
    final res = await http.post(uri, headers: _headers, body: jsonEncode(data));
    final body = _process(res);
    final map = ApiService.extractMap(body);
    return AccountModel.fromJson(map);
  }

  Future<void> updateAccount(int id, Map<String, dynamic> data) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/accounting/accounts/$id');
    final res = await http.put(uri, headers: _headers, body: jsonEncode(data));
    _process(res);
  }

  Future<void> deleteAccount(int id) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/accounting/accounts/$id');
    final res = await http.delete(uri, headers: _headers);
    _process(res);
  }

  // ─── Journal Entries ───
  Future<Map<String, dynamic>> getJournalEntries({
    int page = 1,
    int limit = 20,
    String? status,
    String? sourceType,
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (sourceType != null && sourceType.isNotEmpty) query['source_type'] = sourceType;
    if (startDate != null) query['startDate'] = startDate;
    if (endDate != null) query['endDate'] = endDate;
    if (search != null && search.isNotEmpty) query['search'] = search;

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/accounting/journals').replace(queryParameters: query);
    final res = await http.get(uri, headers: _headers);
    final data = _process(res);
    final bodyData = data['data'] as Map<String, dynamic>? ?? {};
    final list = (bodyData['entries'] as List<dynamic>? ?? [])
        .map((e) => JournalEntryModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return {
      'entries': list,
      'total_count': bodyData['total_count'] ?? 0,
      'page': bodyData['page'] ?? 1,
      'total_pages': bodyData['total_pages'] ?? 1,
    };
  }

  Future<JournalEntryModel> getJournalEntry(int id) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/accounting/journals/$id');
    final res = await http.get(uri, headers: _headers);
    final body = _process(res);
    final map = ApiService.extractMap(body);
    return JournalEntryModel.fromJson(map);
  }

  Future<JournalEntryModel> createManualJournalEntry(Map<String, dynamic> payload) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/accounting/journals');
    final res = await http.post(uri, headers: _headers, body: jsonEncode(payload));
    final body = _process(res);
    final map = ApiService.extractMap(body);
    return JournalEntryModel.fromJson(map);
  }

  Future<void> reverseJournalEntry(int id, String reason) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/accounting/journals/$id/reverse');
    final res = await http.post(uri, headers: _headers, body: jsonEncode({'reason': reason}));
    _process(res);
  }

  // ─── General Ledger ───
  Future<Map<String, dynamic>> getGeneralLedger({
    int? accountId,
    String? startDate,
    String? endDate,
    int? propertyId,
    int page = 1,
    int limit = 50,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (accountId != null) query['accountId'] = accountId.toString();
    if (startDate != null) query['startDate'] = startDate;
    if (endDate != null) query['endDate'] = endDate;
    if (propertyId != null) query['propertyId'] = propertyId.toString();

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/accounting/general-ledger').replace(queryParameters: query);
    final res = await http.get(uri, headers: _headers);
    final body = _process(res);
    return ApiService.extractMap(body);
  }

  // ─── Financial Statements & Reports ───
  Future<Map<String, dynamic>> getTrialBalance({String? asOfDate, String? periodId}) async {
    final query = <String, String>{};
    if (asOfDate != null) query['asOfDate'] = asOfDate;
    if (periodId != null) query['periodId'] = periodId;

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/accounting/trial-balance').replace(queryParameters: query.isEmpty ? null : query);
    final res = await http.get(uri, headers: _headers);
    return ApiService.extractMap(_process(res));
  }

  Future<Map<String, dynamic>> getProfitAndLoss({String? startDate, String? endDate, int? propertyId}) async {
    final query = <String, String>{};
    if (startDate != null) query['startDate'] = startDate;
    if (endDate != null) query['endDate'] = endDate;
    if (propertyId != null) query['propertyId'] = propertyId.toString();

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/accounting/profit-and-loss').replace(queryParameters: query.isEmpty ? null : query);
    final res = await http.get(uri, headers: _headers);
    return ApiService.extractMap(_process(res));
  }

  Future<Map<String, dynamic>> getBalanceSheet({String? asOfDate, int? propertyId}) async {
    final query = <String, String>{};
    if (asOfDate != null) query['asOfDate'] = asOfDate;
    if (propertyId != null) query['propertyId'] = propertyId.toString();

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/accounting/balance-sheet').replace(queryParameters: query.isEmpty ? null : query);
    final res = await http.get(uri, headers: _headers);
    return ApiService.extractMap(_process(res));
  }

  Future<Map<String, dynamic>> getCashFlow({String? startDate, String? endDate}) async {
    final query = <String, String>{};
    if (startDate != null) query['startDate'] = startDate;
    if (endDate != null) query['endDate'] = endDate;

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/accounting/cash-flow').replace(queryParameters: query.isEmpty ? null : query);
    final res = await http.get(uri, headers: _headers);
    return ApiService.extractMap(_process(res));
  }

  // ─── Subledgers & Aging ───
  Future<Map<String, dynamic>> getTenantSubledger({int? tenantId, String? startDate, String? endDate}) async {
    final query = <String, String>{};
    if (tenantId != null) query['tenantId'] = tenantId.toString();
    if (startDate != null) query['startDate'] = startDate;
    if (endDate != null) query['endDate'] = endDate;

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/accounting/subledgers/tenant').replace(queryParameters: query.isEmpty ? null : query);
    final res = await http.get(uri, headers: _headers);
    return ApiService.extractMap(_process(res));
  }

  Future<Map<String, dynamic>> getOwnerSubledger({int? ownerId, String? startDate, String? endDate}) async {
    final query = <String, String>{};
    if (ownerId != null) query['ownerId'] = ownerId.toString();
    if (startDate != null) query['startDate'] = startDate;
    if (endDate != null) query['endDate'] = endDate;

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/accounting/subledgers/owner').replace(queryParameters: query.isEmpty ? null : query);
    final res = await http.get(uri, headers: _headers);
    return ApiService.extractMap(_process(res));
  }

  Future<Map<String, dynamic>> getARAging({String? asOfDate}) async {
    final query = <String, String>{};
    if (asOfDate != null) query['asOfDate'] = asOfDate;

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/accounting/aging/ar').replace(queryParameters: query.isEmpty ? null : query);
    final res = await http.get(uri, headers: _headers);
    return ApiService.extractMap(_process(res));
  }

  // ─── Accounting Periods ───
  Future<List<AccountingPeriodModel>> getPeriods({int? fiscalYear}) async {
    final query = <String, String>{};
    if (fiscalYear != null) query['fiscal_year'] = fiscalYear.toString();

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/accounting/periods').replace(queryParameters: query.isEmpty ? null : query);
    final res = await http.get(uri, headers: _headers);
    final data = _process(res);
    final list = ApiService.extractList(data);
    return list.map((e) => AccountingPeriodModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> closePeriod(int periodId, {String? notes}) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/accounting/periods/$periodId/close');
    final res = await http.post(uri, headers: _headers, body: jsonEncode({'notes': notes}));
    _process(res);
  }

  Future<void> reopenPeriod(int periodId, {required String reason}) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/accounting/periods/$periodId/reopen');
    final res = await http.post(uri, headers: _headers, body: jsonEncode({'reason': reason}));
    _process(res);
  }

  // ─── Bootstrap Historical Postings ───
  Future<Map<String, dynamic>> migrateHistoricalPostings() async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/accounting/migrate-historical');
    final res = await http.post(uri, headers: _headers);
    return ApiService.extractMap(_process(res));
  }
}
