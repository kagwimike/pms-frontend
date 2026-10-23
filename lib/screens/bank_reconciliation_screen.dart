import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class BankReconciliationScreen extends StatefulWidget {
  const BankReconciliationScreen({super.key});

  @override
  State<BankReconciliationScreen> createState() => _BankReconciliationScreenState();
}

class _BankReconciliationScreenState extends State<BankReconciliationScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;

  // Stats
  int _unmatchedCount = 0;
  double _unmatchedTotalAmount = 0.0;

  // Data lists
  List<dynamic> _unmatchedPayments = [];
  List<dynamic> _bankAccounts = [];
  List<dynamic> _statementUploads = [];
  List<dynamic> _supportedBanks = [];

  // Search & Filters for Unmatched Queue
  final TextEditingController _searchController = TextEditingController();
  int? _filterBankAccountId;

  // Statement Ingestion State
  int? _uploadBankAccountId;
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  int? _selectedFileSizeBytes;
  bool _isUploadingStatement = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.wait([
        _loadStatsAndQueue(),
        _loadBankAccounts(),
        _loadStatementUploads(),
        _loadSupportedBanks(),
      ]);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadStatsAndQueue() async {
    try {
      final statsRes = await _apiService.getUnmatchedStats();
      final statsData = ApiService.extractMap(statsRes);

      final queueRes = await _apiService.getUnmatchedPayments(
        query: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
        bankAccountId: _filterBankAccountId,
        limit: 50,
      );
      final queueData = ApiService.extractMap(queueRes);
      final queueItems = queueData['items'] as List<dynamic>? ?? ApiService.extractList(queueRes);

      if (mounted) {
        setState(() {
          _unmatchedCount = int.tryParse(statsData['unmatched_count']?.toString() ?? '0') ?? 0;
          _unmatchedTotalAmount = double.tryParse(statsData['total_unmatched_amount']?.toString() ?? '0') ?? 0.0;
          _unmatchedPayments = queueItems;
        });
      }
    } catch (e) {
      debugPrint('Error loading unmatched queue: $e');
    }
  }

  Future<void> _loadBankAccounts() async {
    try {
      final res = await _apiService.getBankAccounts();
      final list = ApiService.extractList(res);
      if (mounted) {
        setState(() {
          _bankAccounts = list;
          // Set default upload bank account to primary account if available
          if (_uploadBankAccountId == null && list.isNotEmpty) {
            final primary = list.firstWhere(
              (a) => a['is_primary'] == true,
              orElse: () => list.first,
            );
            _uploadBankAccountId = primary['id'];
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading bank accounts: $e');
    }
  }

  Future<void> _loadStatementUploads() async {
    try {
      final res = await _apiService.getStatementUploads(limit: 20);
      final data = ApiService.extractMap(res);
      final list = data['statements'] as List<dynamic>? ?? ApiService.extractList(res);
      if (mounted) {
        setState(() => _statementUploads = list);
      }
    } catch (e) {
      debugPrint('Error loading statement uploads: $e');
    }
  }

  Future<void> _loadSupportedBanks() async {
    try {
      final res = await _apiService.getSupportedBanks();
      final list = ApiService.extractList(res);
      if (mounted) {
        setState(() => _supportedBanks = list);
      }
    } catch (e) {
      debugPrint('Error loading supported banks: $e');
    }
  }

  // ─── Format Helpers ───
  String _fmtKsh(dynamic amount) {
    if (amount == null) return 'KSh 0.00';
    final val = double.tryParse(amount.toString()) ?? 0.0;
    return NumberFormat.currency(symbol: 'KSh ', decimalDigits: 2).format(val);
  }

  String _fmtDate(dynamic dateStr) {
    if (dateStr == null) return '—';
    try {
      final dt = DateTime.parse(dateStr.toString()).toLocal();
      return DateFormat('MMM dd, yyyy • hh:mm a').format(dt);
    } catch (_) {
      return dateStr.toString();
    }
  }

  Color _getBankColor(String? bankCode) {
    switch (bankCode?.toUpperCase()) {
      case 'EQUITY':
        return const Color(0xFF8B1E1E); // Equity Crimson
      case 'COOP':
        return const Color(0xFF0F6B4F); // Co-op Emerald
      case 'KCB':
        return const Color(0xFF2E7D32); // KCB Green
      case 'NCBA':
        return const Color(0xFF1E3A8A); // NCBA Deep Blue
      case 'STANBIC':
        return const Color(0xFF0284C7); // Stanbic Blue
      case 'ABSA':
        return const Color(0xFFDC2626); // Absa Red
      case 'DTB':
        return const Color(0xFFD97706); // DTB Amber
      default:
        return AppTheme.teal;
    }
  }

  // ─── 1-Click Assignment Action ───
  Future<void> _assignPayment(int paymentId, int invoiceId, {String? notes}) async {
    try {
      await _apiService.assignUnmatchedPayment(paymentId, invoiceId, notes: notes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.teal,
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                'Payment matched & invoice reconciled successfully!',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ],
          ),
        ),
      );
      _loadStatsAndQueue();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          content: Text('Failed to assign payment: $e'),
        ),
      );
    }
  }

  // ─── File Picker & Statement Upload ───
  Future<void> _pickStatementFile() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
      );

      if (file != null) {
        final bytes = await file.xFile.readAsBytes();
        if (!mounted) return;
        setState(() {
          _selectedFileBytes = bytes;
          _selectedFileName = file.name;
          _selectedFileSizeBytes = bytes.length;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting file: $e')),
      );
    }
  }

  Future<void> _uploadAndReconcileStatement() async {
    if (_selectedFileBytes == null || _selectedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a CSV or Excel bank statement file first')),
      );
      return;
    }

    setState(() => _isUploadingStatement = true);

    try {
      final res = await _apiService.uploadBankStatement(
        bytes: _selectedFileBytes!,
        filename: _selectedFileName!,
        bankAccountId: _uploadBankAccountId,
      );
      final result = ApiService.extractMap(res);

      if (!mounted) return;
      setState(() {
        _isUploadingStatement = false;
        _selectedFileBytes = null;
        _selectedFileName = null;
        _selectedFileSizeBytes = null;
      });

      _showUploadResultModal(result);
      _loadAllData();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingStatement = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          content: Text('Upload failed: $e'),
        ),
      );
    }
  }

  // ─── Modal: Reconciliation Summary ───
  void _showUploadResultModal(Map<String, dynamic> result) {
    final totalRows = result['totalRows'] ?? 0;
    final totalAmount = result['totalAmount'] ?? 0;
    final matchedCount = result['matchedCount'] ?? 0;
    final unmatchedCount = result['unmatchedCount'] ?? 0;
    final duplicateCount = result['duplicateCount'] ?? 0;
    final errors = result['errors'] as List<dynamic>? ?? [];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.analytics_outlined, color: AppTheme.teal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reconciliation Summary',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.navy,
                      ),
                    ),
                    Text(
                      result['fileName']?.toString() ?? 'Statement Ingestion',
                      style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.mutedText),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        _buildResultRow('Total Transactions Ingested', '$totalRows rows', Icons.list_alt),
                        const Divider(height: 16),
                        _buildResultRow('Total Processed Volume', _fmtKsh(totalAmount), Icons.payments_outlined, valueColor: AppTheme.navy),
                        const Divider(height: 16),
                        _buildResultRow('Auto-Matched to Invoices', '$matchedCount matched', Icons.verified, valueColor: AppTheme.teal),
                        const Divider(height: 16),
                        _buildResultRow('Routed to Unmatched Queue', '$unmatchedCount in suspense', Icons.pending_actions, valueColor: Colors.orange.shade800),
                        const Divider(height: 16),
                        _buildResultRow('Duplicates Skipped', '$duplicateCount records', Icons.copy_outlined, valueColor: Colors.grey),
                      ],
                    ),
                  ),
                  if (errors.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Row Processing Notes (${errors.length}):',
                        style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.orange.shade800),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: errors.length,
                        itemBuilder: (ctx, i) {
                          final err = errors[i];
                          return Text(
                            '• Row ${err['row'] ?? i + 1}: ${err['error'] ?? 'Formatting warning'}',
                            style: GoogleFonts.dmSans(fontSize: 11, color: Colors.brown.shade800),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _tabController.animateTo(0); // Jump to unmatched queue tab
              },
              style: AppTheme.actionButtonStyle,
              child: Text(
                'Review Unmatched Queue ($unmatchedCount)',
                style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResultRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.mutedText),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.mutedText),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppTheme.navy,
          ),
        ),
      ],
    );
  }

  // ─── Modal: Manual Invoice Match ───
  void _showManualAssignModal(Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (context) => _ManualAssignDialog(
        payment: payment,
        onAssigned: (invoiceId, notes) {
          Navigator.of(context).pop();
          _assignPayment(payment['id'], invoiceId, notes: notes);
        },
      ),
    );
  }

  // ─── Modal: Resolve / Dismiss Deposit ───
  void _showResolveModal(Map<String, dynamic> payment) {
    final messenger = ScaffoldMessenger.of(context);
    String selectedResolution = 'NON_RENTAL';
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.brown.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.do_not_disturb_on_outlined, color: Colors.brown.shade800),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resolve / Dismiss Deposit',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.navy,
                          ),
                        ),
                        Text(
                          'Reference: ${payment['transaction_reference'] ?? 'Deposit #${payment['id']}'}',
                          style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.mutedText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber.shade900, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Resolving removes this deposit of ${_fmtKsh(payment['amount'])} from the active unmatched suspense queue.',
                              style: GoogleFonts.dmSans(fontSize: 12, color: Colors.amber.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Resolution Classification',
                      style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.navy),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedResolution,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'NON_RENTAL',
                          child: Text('Non-Rental (Utility, Owner Capital, Misc)'),
                        ),
                        DropdownMenuItem(
                          value: 'REFUNDED',
                          child: Text('Refunded (Returned to Sender)'),
                        ),
                        DropdownMenuItem(
                          value: 'CANCELLED',
                          child: Text('Cancelled / Duplicate Entry'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedResolution = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Audit Note & Explanation',
                      style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.navy),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'e.g. Electricity token reimbursement paid to caretaker account',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel', style: GoogleFonts.dmSans()),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    try {
                      await _apiService.resolveUnmatchedPayment(
                        payment['id'],
                        selectedResolution,
                        reason: reasonController.text.trim().isNotEmpty
                            ? reasonController.text.trim()
                            : null,
                      );
                      messenger.showSnackBar(
                        SnackBar(
                          backgroundColor: AppTheme.teal,
                          content: Text('Deposit marked as $selectedResolution'),
                        ),
                      );
                      _loadStatsAndQueue();
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Confirm Resolution',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── Modal: Add/Edit Bank Account ───
  void _showAddEditBankAccountModal({Map<String, dynamic>? accountToEdit}) {
    showDialog(
      context: context,
      builder: (context) => _AddEditBankAccountDialog(
        accountToEdit: accountToEdit,
        supportedBanks: _supportedBanks,
        onSaved: () {
          _loadBankAccounts();
          _loadStatsAndQueue();
        },
      ),
    );
  }

  // ─── Main Scaffold Build ───
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bank Reconciliation Desk',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: isMobile ? 22 : 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Automate statement ingestion, rent matching, and Kenya bank integrations',
                      style: GoogleFonts.dmSans(
                        fontSize: isMobile ? 12 : 14,
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _loadAllData,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: Text(isMobile ? '' : 'Refresh'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.navy,
                      side: const BorderSide(color: AppTheme.border),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditBankAccountModal(),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(isMobile ? 'Add A/C' : '+ Add Bank Account'),
                    style: AppTheme.actionButtonStyle,
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: isMobile ? 16 : 24),

          // ── Metrics Bar ──
          _buildMetricsBar(isMobile),

          SizedBox(height: isMobile ? 16 : 24),

          // ── Tab Bar Navigation ──
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: isMobile || screenWidth < 900,
              tabAlignment: (isMobile || screenWidth < 900) ? TabAlignment.start : TabAlignment.fill,
              labelColor: AppTheme.teal,
              unselectedLabelColor: AppTheme.mutedText,
              indicatorColor: AppTheme.teal,
              indicatorWeight: 3,
              labelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.pending_actions_outlined, size: 18),
                      const SizedBox(width: 8),
                      const Text('Unmatched Queue'),
                      if (_unmatchedCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade700,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$_unmatchedCount',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_file_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Statement Ingestion Desk'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.account_balance_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text('Bank Accounts Hub (${_bankAccounts.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Tab Content Views ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Failed to load reconciliation desk',
                              style: GoogleFonts.bricolageGrotesque(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.navy,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(_errorMessage!, style: GoogleFonts.dmSans(color: AppTheme.mutedText)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadAllData,
                              style: AppTheme.actionButtonStyle,
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildUnmatchedQueueTab(isMobile),
                          _buildStatementIngestionTab(isMobile),
                          _buildBankAccountsHubTab(isMobile),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  // ─── Metric Cards Bar ───
  Widget _buildMetricsBar(bool isMobile) {
    final hasUnmatched = _unmatchedCount > 0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = isMobile
            ? constraints.maxWidth
            : constraints.maxWidth < 1000
                ? (constraints.maxWidth - 16) / 2
                : (constraints.maxWidth - 48) / 4;
        return Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            _buildMetricCard(
              title: 'Unmatched Suspense Queue',
              value: '$_unmatchedCount deposits',
              subtitle: hasUnmatched ? 'Requires manual or 1-click match' : 'All deposits reconciled ✨',
              icon: Icons.pending_actions_rounded,
              color: hasUnmatched ? Colors.orange.shade700 : AppTheme.teal,
              width: cardWidth,
            ),
            _buildMetricCard(
              title: 'Unmatched Value',
              value: _fmtKsh(_unmatchedTotalAmount),
              subtitle: 'Funds waiting for invoice allocation',
              icon: Icons.account_balance_wallet_outlined,
              color: AppTheme.navy,
              width: cardWidth,
            ),
            _buildMetricCard(
              title: 'Collection Bank Accounts',
              value: '${_bankAccounts.length} Active Accounts',
              subtitle: 'Equity, Co-op, KCB & Paybills',
              icon: Icons.account_balance_outlined,
              color: AppTheme.teal,
              width: cardWidth,
            ),
            _buildMetricCard(
              title: 'Statement Batches',
              value: '${_statementUploads.length} Ingested',
              subtitle: _statementUploads.isNotEmpty
                  ? 'Last: ${_statementUploads.first['file_name'] ?? 'Recent'}'
                  : 'Ready for upload',
              icon: Icons.history_rounded,
              color: AppTheme.brass,
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.mutedText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.navy,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppTheme.mutedText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // TAB 1: UNMATCHED DEPOSITS QUEUE (Smart 1-Click Assignment)
  // ══════════════════════════════════════════════════════════════
  Widget _buildUnmatchedQueueTab(bool isMobile) {
    return Column(
      children: [
        // ── Filter & Search Bar ──
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: isMobile
              ? Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onSubmitted: (_) => _loadStatsAndQueue(),
                      decoration: InputDecoration(
                        hintText: 'Search reference, payer, narration...',
                        prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.mutedText),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            initialValue: _filterBankAccountId,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('All Bank A/Cs')),
                              ..._bankAccounts.map((a) {
                                return DropdownMenuItem<int?>(
                                  value: a['id'],
                                  child: Text(
                                    '${a['bank_name']} (${a['account_number']})',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              setState(() => _filterBankAccountId = val);
                              _loadStatsAndQueue();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _loadStatsAndQueue,
                          icon: const Icon(Icons.refresh, color: AppTheme.teal),
                          tooltip: 'Refresh Queue',
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: (_) => _loadStatsAndQueue(),
                        decoration: InputDecoration(
                          hintText: 'Search by reference, payer name, or bank narration...',
                          prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.mutedText),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppTheme.border),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Bank Account Selector Filter
                    SizedBox(
                      width: 190,
                      child: DropdownButtonFormField<int?>(
                        initialValue: _filterBankAccountId,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Bank A/Cs')),
                          ..._bankAccounts.map((a) {
                            return DropdownMenuItem<int?>(
                              value: a['id'],
                              child: Text(
                                '${a['bank_name']} (${a['account_number']})',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setState(() => _filterBankAccountId = val);
                          _loadStatsAndQueue();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _loadStatsAndQueue,
                      icon: const Icon(Icons.refresh, color: AppTheme.teal),
                      tooltip: 'Refresh Queue',
                    ),
                  ],
                ),
        ),

        const SizedBox(height: 12),

        // ── Unmatched List ──
        Expanded(
          child: _unmatchedPayments.isEmpty
              ? _buildEmptyQueueState()
              : ListView.separated(
                  itemCount: _unmatchedPayments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _unmatchedPayments[index];
                    return _buildUnmatchedPaymentCard(item, isMobile);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyQueueState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.teal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline, size: 56, color: AppTheme.teal),
            ),
            const SizedBox(height: 16),
            Text(
              'Zero Unmatched Deposits 🎉',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.navy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'All incoming tenant bank deposits and M-Pesa sweeps are cleanly reconciled to invoices.',
              style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.mutedText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(1),
              icon: const Icon(Icons.upload_file_outlined, size: 16),
              label: const Text('Ingest New Statement'),
              style: AppTheme.actionButtonStyle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnmatchedPaymentCard(Map<String, dynamic> item, bool isMobile) {
    final paymentId = item['id'];
    final amount = item['amount'];
    final reference = item['transaction_reference'] ?? 'No Reference';
    final payer = item['payer_name'] ?? 'Unknown Payer';
    final notes = item['notes'] ?? item['account_reference'] ?? 'No narration provided';
    final paidAt = item['paid_at'];
    final bank = item['bank_account'];
    final bankName = bank != null ? (bank['bank_name'] ?? 'Bank') : 'General Bank';
    final bankAccountNum = bank != null ? bank['account_number'] : '';

    final suggestions = item['suggested_matches'] as List<dynamic>? ?? [];
    final topMatch = suggestions.isNotEmpty ? suggestions.first : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Header of Card ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getBankColor(bankName),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    bankName,
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (bankAccountNum != null && bankAccountNum.toString().isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '• A/C: $bankAccountNum',
                      style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.mutedText),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const Spacer(),
                const Icon(Icons.access_time, size: 14, color: AppTheme.mutedText),
                const SizedBox(width: 4),
                Text(
                  _fmtDate(paidAt),
                  style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.mutedText),
                ),
              ],
            ),
          ),

          // ── Deposit Core Details ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                reference,
                                style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.navy,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 14, color: AppTheme.mutedText),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: reference));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Reference copied to clipboard')),
                                  );
                                },
                                tooltip: 'Copy Reference',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Payer: $payer',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Bank Narration: $notes',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppTheme.mutedText,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Unmatched Deposit',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade800,
                          ),
                        ),
                        Text(
                          _fmtKsh(amount),
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.navy,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Pre-Computed Smart Suggestion Banner ──
                if (topMatch != null) ...[
                  _buildSmartSuggestionBox(topMatch),
                  const SizedBox(height: 12),
                ],

                // ── Card Action Buttons ──
                Wrap(
                  alignment: isMobile ? WrapAlignment.start : WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showResolveModal(item),
                      icon: const Icon(Icons.remove_circle_outline, size: 14),
                      label: const Text('Resolve / Non-Rental'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.brown.shade700,
                        side: BorderSide(color: Colors.brown.shade300),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        textStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _showManualAssignModal(item),
                      icon: const Icon(Icons.search, size: 14),
                      label: const Text('Search & Assign'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.teal,
                        side: const BorderSide(color: AppTheme.teal),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        textStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (topMatch != null)
                      ElevatedButton.icon(
                        onPressed: () {
                          final invId = topMatch['invoice']?['id'];
                          if (invId != null) {
                            _assignPayment(
                              paymentId,
                              invId,
                              notes: '1-Click Match (Confidence: ${topMatch['score']}%)',
                            );
                          }
                        },
                        icon: const Icon(Icons.bolt, size: 16),
                        label: Text('1-Click Match & Confirm (${topMatch['score']}%)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartSuggestionBox(Map<String, dynamic> topMatch) {
    final invoice = topMatch['invoice'] ?? {};
    final invId = invoice['id'];
    final invNumber = invoice['invoice_number'] ?? 'INV-#$invId';
    final invBalance = (invoice['amount'] ?? 0) - (invoice['amount_paid'] ?? 0);
    final score = topMatch['score'] ?? 0;
    final tier = topMatch['tier'] ?? 'TIER_3_FUZZY';
    final reasons = (topMatch['match_reasons'] as List<dynamic>?)?.map((r) => r.toString()).toList() ?? [];

    final lease = invoice['lease'];
    final unit = lease != null ? lease['unit'] : null;
    final property = unit != null ? unit['property'] : null;
    final tenant = lease != null ? lease['tenant'] : null;

    final tenantName = tenant != null ? '${tenant['first_name'] ?? ''} ${tenant['last_name'] ?? ''}'.trim() : 'Unknown Tenant';
    final propertyUnit = '${property?['name'] ?? 'Property'} • Unit ${unit?['unit_number'] ?? '—'}';

    Color badgeColor = Colors.blue;
    String badgeLabel = 'Fuzzy Match';
    if (score >= 90) {
      badgeColor = AppTheme.teal;
      badgeLabel = 'High Confidence Match';
    } else if (score >= 70) {
      badgeColor = Colors.amber.shade800;
      badgeLabel = 'Probable Match';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.teal.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$badgeLabel ($score%)',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Algorithm Suggestion: $tier',
                  style: GoogleFonts.dmSans(fontSize: 11, color: AppTheme.mutedText),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Invoice Balance: ${_fmtKsh(invBalance)}',
                style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.navy),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined, size: 16, color: AppTheme.teal),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$invNumber • $tenantName ($propertyUnit)',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.navy,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: reasons.map((r) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.teal.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    '✓ $r',
                    style: GoogleFonts.dmSans(fontSize: 10, color: AppTheme.teal, fontWeight: FontWeight.w600),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // TAB 2: STATEMENT INGESTION DESK
  // ══════════════════════════════════════════════════════════════
  Widget _buildStatementIngestionTab(bool isMobile) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Upload Card ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.cloud_upload_outlined, color: AppTheme.teal, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ingest Bank Statement File',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.navy,
                            ),
                          ),
                          Text(
                            'Upload CSV or Excel statements from Equity, Co-op, KCB, NCBA, Stanbic, Absa, or DTB',
                            style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.mutedText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Bank Account Selector
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Target Receiving Bank Account',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.navy,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<int?>(
                            initialValue: _uploadBankAccountId,
                            decoration: InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Auto-Detect Bank from Statement Header'),
                              ),
                              ..._bankAccounts.map((a) {
                                return DropdownMenuItem<int?>(
                                  value: a['id'],
                                  child: Text(
                                    '${a['bank_name']} — ${a['account_name']} (${a['account_number']})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }),
                            ],
                            onChanged: (val) => setState(() => _uploadBankAccountId = val),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Dropzone / File Picker Container
                InkWell(
                  onTap: _pickStatementFile,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedFileName != null ? AppTheme.teal : AppTheme.border,
                        width: _selectedFileName != null ? 1.5 : 1.0,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _selectedFileName != null ? Icons.file_present_rounded : Icons.file_upload_outlined,
                          size: 44,
                          color: _selectedFileName != null ? AppTheme.teal : AppTheme.mutedText,
                        ),
                        const SizedBox(height: 10),
                        if (_selectedFileName != null) ...[
                          Text(
                            _selectedFileName!,
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.navy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Size: ${((_selectedFileSizeBytes ?? 0) / 1024).toStringAsFixed(1)} KB • Ready for automated reconciliation',
                            style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.teal),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Click to choose a different file',
                            style: GoogleFonts.dmSans(fontSize: 11, color: AppTheme.mutedText),
                          ),
                        ] else ...[
                          Text(
                            'Click to select bank statement (.csv, .xlsx, .xls)',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.navy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Supported formats: Standard Kenyan Bank Statement CSV or Excel Exports',
                            style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.mutedText),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Upload Button
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _isUploadingStatement ? null : _uploadAndReconcileStatement,
                    icon: _isUploadingStatement
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.bolt, size: 18),
                    label: Text(_isUploadingStatement ? 'Parsing & Matching Statement...' : 'Ingest & Auto-Reconcile'),
                    style: AppTheme.actionButtonStyle,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Batches History Header ──
          Text(
            'Statement Ingestion History',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Audit log of all uploaded bank statements and their reconciliation outcomes',
            style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.mutedText),
          ),

          const SizedBox(height: 12),

          // ── History List ──
          if (_statementUploads.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Center(
                child: Text(
                  'No bank statements uploaded yet.',
                  style: GoogleFonts.dmSans(color: AppTheme.mutedText),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _statementUploads.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final upload = _statementUploads[index];
                return _buildStatementUploadCard(upload);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatementUploadCard(Map<String, dynamic> upload) {
    final fileName = upload['file_name'] ?? 'Statement';
    final totalAmount = upload['total_amount'] ?? 0;
    final matched = upload['matched_count'] ?? 0;
    final unmatched = upload['unmatched_count'] ?? 0;
    final createdAt = upload['created_at'];
    final bank = upload['bank_account'];
    final bankName = bank != null ? (bank['bank_name'] ?? 'Bank') : 'General';
    final uploader = upload['uploader'];
    final uploaderName = uploader != null ? (uploader['username'] ?? 'Staff') : 'System';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getBankColor(bankName).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.table_chart_outlined, color: _getBankColor(bankName), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        fileName,
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.navy,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        bankName,
                        style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.navy),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Ingested by $uploaderName on ${_fmtDate(createdAt)}',
                  style: GoogleFonts.dmSans(fontSize: 11, color: AppTheme.mutedText),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmtKsh(totalAmount),
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$matched Matched',
                      style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.teal),
                    ),
                  ),
                  if (unmatched > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$unmatched Unmatched',
                        style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.orange.shade800),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // TAB 3: BANK ACCOUNTS HUB (Kenyan Collection Accounts)
  // ══════════════════════════════════════════════════════════════
  Widget _buildBankAccountsHubTab(bool isMobile) {
    if (_bankAccounts.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_balance_outlined, size: 56, color: AppTheme.mutedText),
              const SizedBox(height: 16),
              Text(
                'No Bank Accounts Configured',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Add your Equity, Co-op, KCB, NCBA, or Stanbic bank accounts and Paybills to receive direct tenant deposits.',
                style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.mutedText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showAddEditBankAccountModal(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add First Bank Account'),
                style: AppTheme.actionButtonStyle,
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = isMobile ? constraints.maxWidth : (constraints.maxWidth - 20) / 2;
        return SingleChildScrollView(
          child: Wrap(
            spacing: 20,
            runSpacing: 16,
            children: _bankAccounts.map((account) {
              return SizedBox(
                width: cardWidth,
                child: _buildBankAccountCard(account),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildBankAccountCard(Map<String, dynamic> account) {
    final accountId = account['id'];
    final bankName = account['bank_name'] ?? 'BANK';
    final accountName = account['account_name'] ?? 'Collection Account';
    final accountNum = account['account_number'] ?? '—';
    final paybill = account['paybill_number'];
    final branch = account['branch_name'];
    final isPrimary = account['is_primary'] == true;
    final property = account['property'];
    final propertyScope = property != null ? property['name'] : 'All Managed Properties (Global)';
    final bankColor = _getBankColor(bankName);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPrimary ? AppTheme.teal : AppTheme.border,
          width: isPrimary ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card Header ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bankColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            bankName,
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.navy,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isPrimary) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.teal,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'PRIMARY',
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      accountName,
                      style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.mutedText),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppTheme.mutedText),
                onSelected: (val) async {
                  if (val == 'PRIMARY') {
                    await _apiService.setPrimaryBankAccount(accountId);
                    _loadBankAccounts();
                  } else if (val == 'EDIT') {
                    _showAddEditBankAccountModal(accountToEdit: account);
                  } else if (val == 'DELETE') {
                    _confirmDeleteBankAccount(accountId);
                  }
                },
                itemBuilder: (context) => [
                  if (!isPrimary)
                    const PopupMenuItem(
                      value: 'PRIMARY',
                      child: Row(
                        children: [
                          Icon(Icons.star_outline, size: 18, color: AppTheme.teal),
                          SizedBox(width: 8),
                          Text('Set as Default'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'EDIT',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: AppTheme.navy),
                        SizedBox(width: 8),
                        Text('Edit Details'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'DELETE',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete Account', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // ── Account Number & Copy ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Account Number',
                style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.mutedText),
              ),
              Row(
                children: [
                  Text(
                    accountNum,
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.navy,
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 14, color: AppTheme.mutedText),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: accountNum));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Account number copied')),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Paybill Number & Copy ──
          if (paybill != null && paybill.toString().isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'M-Pesa Paybill Shortcode',
                  style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.mutedText),
                ),
                Row(
                  children: [
                    Text(
                      paybill.toString(),
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.navy,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 14, color: AppTheme.mutedText),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: paybill.toString()));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Paybill copied')),
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // ── Branch & Scope ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Branch',
                style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.mutedText),
              ),
              Text(
                branch != null && branch.toString().isNotEmpty ? branch.toString() : 'Head Office',
                style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.navy),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Assigned Scope',
                style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.mutedText),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  propertyScope,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.teal),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDeleteBankAccount(int accountId) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bank Account'),
        content: const Text(
          'Are you sure you want to remove this bank account? This will not delete previous reconciled payments.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _apiService.deleteBankAccount(accountId);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Bank account deleted')),
                );
                _loadBankAccounts();
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// MODAL: MANUAL INVOICE ASSIGN DIALOG
// ══════════════════════════════════════════════════════════════
class _ManualAssignDialog extends StatefulWidget {
  final Map<String, dynamic> payment;
  final Function(int invoiceId, String? notes) onAssigned;

  const _ManualAssignDialog({
    required this.payment,
    required this.onAssigned,
  });

  @override
  State<_ManualAssignDialog> createState() => _ManualAssignDialogState();
}

class _ManualAssignDialogState extends State<_ManualAssignDialog> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _invoices = [];
  int? _selectedInvoiceId;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _searchInvoiceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _searchInvoiceController.dispose();
    super.dispose();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.getInvoices(limit: 100);
      final list = ApiService.extractList(res);
      // Filter for UNPAID or PARTIAL invoices
      final openInvoices = list.where((inv) {
        final status = inv['status']?.toString().toUpperCase();
        return status == 'UNPAID' || status == 'PARTIAL';
      }).toList();

      if (mounted) {
        setState(() {
          _invoices = openInvoices;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final depositAmount = widget.payment['amount'];
    final reference = widget.payment['transaction_reference'] ?? 'Deposit #${widget.payment['id']}';

    final filtered = _invoices.where((inv) {
      final query = _searchInvoiceController.text.trim().toLowerCase();
      if (query.isEmpty) return true;
      final invNum = (inv['invoice_number'] ?? '').toString().toLowerCase();
      final tenant = inv['lease']?['tenant'];
      final tenantName = '${tenant?['first_name'] ?? ''} ${tenant?['last_name'] ?? ''}'.toLowerCase();
      final unit = inv['lease']?['unit']?['unit_number']?.toString().toLowerCase() ?? '';
      return invNum.contains(query) || tenantName.contains(query) || unit.contains(query);
    }).toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.link, color: AppTheme.teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assign Deposit to Invoice',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.navy,
                  ),
                ),
                Text(
                  'Target: $reference (KSh $depositAmount)',
                  style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.mutedText),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Container(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          children: [
            TextField(
              controller: _searchInvoiceController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Filter by tenant name, unit number, or invoice #...',
                prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.mutedText),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No open invoices found.',
                            style: GoogleFonts.dmSans(color: AppTheme.mutedText),
                          ),
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, i) {
                            final inv = filtered[i];
                            final id = inv['id'];
                            final num = inv['invoice_number'] ?? 'INV-#$id';
                            final total = inv['amount'] ?? 0;
                            final balance = (inv['amount'] ?? 0) - (inv['amount_paid'] ?? 0);
                            final tenant = inv['lease']?['tenant'];
                            final tenantName = '${tenant?['first_name'] ?? ''} ${tenant?['last_name'] ?? ''}'.trim();
                            final unit = inv['lease']?['unit']?['unit_number'] ?? '—';
                            final isSelected = _selectedInvoiceId == id;

                            return InkWell(
                              onTap: () => setState(() => _selectedInvoiceId = id),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.teal.withValues(alpha: 0.1) : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? AppTheme.teal : AppTheme.border,
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                      color: isSelected ? AppTheme.teal : AppTheme.mutedText,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$num • $tenantName',
                                            style: GoogleFonts.dmSans(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: AppTheme.navy,
                                            ),
                                          ),
                                          Text(
                                            'Unit $unit • Balance Due: KSh $balance (Total: KSh $total)',
                                            style: GoogleFonts.dmSans(
                                              fontSize: 11,
                                              color: AppTheme.mutedText,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'Optional assignment note / audit justification...',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedInvoiceId == null
              ? null
              : () => widget.onAssigned(_selectedInvoiceId!, _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null),
          style: AppTheme.actionButtonStyle,
          child: const Text('Confirm Match'),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// MODAL: ADD / EDIT BANK ACCOUNT DIALOG
// ══════════════════════════════════════════════════════════════
class _AddEditBankAccountDialog extends StatefulWidget {
  final Map<String, dynamic>? accountToEdit;
  final List<dynamic> supportedBanks;
  final VoidCallback onSaved;

  const _AddEditBankAccountDialog({
    this.accountToEdit,
    required this.supportedBanks,
    required this.onSaved,
  });

  @override
  State<_AddEditBankAccountDialog> createState() => _AddEditBankAccountDialogState();
}

class _AddEditBankAccountDialogState extends State<_AddEditBankAccountDialog> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  String _bankCode = 'EQUITY';
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _branchController = TextEditingController();
  final TextEditingController _paybillController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isPrimary = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.accountToEdit != null) {
      final a = widget.accountToEdit!;
      _bankCode = a['bank_name'] ?? 'EQUITY';
      _accountNameController.text = a['account_name'] ?? '';
      _accountNumberController.text = a['account_number'] ?? '';
      _branchController.text = a['branch_name'] ?? '';
      _paybillController.text = a['paybill_number'] ?? '';
      _notesController.text = a['notes'] ?? '';
      _isPrimary = a['is_primary'] == true;
    } else {
      _applyDefaultPaybill('EQUITY');
    }
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _branchController.dispose();
    _paybillController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _applyDefaultPaybill(String code) {
    final found = widget.supportedBanks.firstWhere(
      (b) => b['code'] == code,
      orElse: () => null,
    );
    if (found != null && found['defaultPaybill'] != null) {
      _paybillController.text = found['defaultPaybill'].toString();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final payload = {
      'bank_name': _bankCode,
      'account_name': _accountNameController.text.trim(),
      'account_number': _accountNumberController.text.trim(),
      'branch_name': _branchController.text.trim().isNotEmpty ? _branchController.text.trim() : null,
      'paybill_number': _paybillController.text.trim().isNotEmpty ? _paybillController.text.trim() : null,
      'is_primary': _isPrimary,
      'currency': 'KES',
      'notes': _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    };

    try {
      if (widget.accountToEdit != null) {
        await _apiService.updateBankAccount(widget.accountToEdit!['id'], payload);
      } else {
        await _apiService.createBankAccount(payload);
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.accountToEdit != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.account_balance, color: AppTheme.teal),
          ),
          const SizedBox(width: 12),
          Text(
            isEdit ? 'Edit Bank Account' : 'Add Reception Bank Account',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.navy,
            ),
          ),
        ],
      ),
      content: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Commercial Bank / Institution',
                  style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.navy),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _bankCode,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: widget.supportedBanks.isNotEmpty
                      ? widget.supportedBanks.map((b) {
                          return DropdownMenuItem<String>(
                            value: b['code'].toString(),
                            child: Text(b['name'].toString()),
                          );
                        }).toList()
                      : const [
                          DropdownMenuItem(value: 'EQUITY', child: Text('Equity Bank Kenya')),
                          DropdownMenuItem(value: 'COOP', child: Text('Co-operative Bank of Kenya')),
                          DropdownMenuItem(value: 'KCB', child: Text('KCB Bank Kenya')),
                          DropdownMenuItem(value: 'NCBA', child: Text('NCBA Bank Kenya')),
                          DropdownMenuItem(value: 'STANBIC', child: Text('Stanbic Bank Kenya')),
                          DropdownMenuItem(value: 'ABSA', child: Text('Absa Bank Kenya')),
                          DropdownMenuItem(value: 'DTB', child: Text('Diamond Trust Bank (DTB)')),
                          DropdownMenuItem(value: 'OTHER', child: Text('Other Financial Institution')),
                        ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _bankCode = val);
                      _applyDefaultPaybill(val);
                    }
                  },
                ),

                const SizedBox(height: 14),

                Text(
                  'Account Name (Title on Bank Record)',
                  style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.navy),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _accountNameController,
                  decoration: InputDecoration(
                    hintText: 'e.g. PMS Pro Client Collection A/C',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Account name is required' : null,
                ),

                const SizedBox(height: 14),

                Text(
                  'Account Number',
                  style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.navy),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _accountNumberController,
                  decoration: InputDecoration(
                    hintText: 'e.g. 0180293847291',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Account number is required' : null,
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Paybill / Till Number',
                            style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.navy),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _paybillController,
                            decoration: InputDecoration(
                              hintText: 'e.g. 247247',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Branch Name',
                            style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.navy),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _branchController,
                            decoration: InputDecoration(
                              hintText: 'e.g. Upper Hill / Westlands',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                CheckboxListTile(
                  title: Text(
                    'Set as Primary Reception Account',
                    style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.navy),
                  ),
                  subtitle: Text(
                    'Default bank account displayed to tenants when generating rent invoices & bank slips',
                    style: GoogleFonts.dmSans(fontSize: 11, color: AppTheme.mutedText),
                  ),
                  value: _isPrimary,
                  onChanged: (val) => setState(() => _isPrimary = val ?? false),
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppTheme.teal,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          style: AppTheme.actionButtonStyle,
          child: Text(_isSaving ? 'Saving...' : (isEdit ? 'Update Account' : 'Save Account')),
        ),
      ],
    );
  }
}
