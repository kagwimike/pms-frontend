import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class InspectionDetailScreen extends StatefulWidget {
  final int inspectionId;
  final bool isOwner;

  const InspectionDetailScreen({
    super.key,
    required this.inspectionId,
    required this.isOwner,
  });

  @override
  State<InspectionDetailScreen> createState() => _InspectionDetailScreenState();
}

class _InspectionDetailScreenState extends State<InspectionDetailScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _inspection;
  Map<String, dynamic>? _reconciliation;
  List<dynamic> _catalog = [];

  bool _isSavingChecklist = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final inspRes = await _apiService.getInspection(widget.inspectionId);
      final catalogRes = await _apiService.getInspectionCatalog();

      _inspection = ApiService.extractMap(inspRes);
      final rawChecklist = _inspection?['checklist'];
      if (rawChecklist is String && rawChecklist.isNotEmpty) {
        try {
          _inspection?['checklist'] = jsonDecode(rawChecklist);
        } catch (_) {}
      }

      final catalogData = ApiService.extractMap(catalogRes);
      _catalog = catalogData['catalog'] as List<dynamic>? ?? [];

      // If move-out or completed or has damages, load reconciliation
      await _loadReconciliationQuiet();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadReconciliationQuiet() async {
    try {
      final reconRes = await _apiService.getDepositReconciliation(widget.inspectionId);
      _reconciliation = ApiService.extractMap(reconRes);
    } catch (_) {}
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return const Color(0xFF10B981); // Emerald
      case 'SCHEDULED':
        return const Color(0xFFF59E0B); // Amber
      case 'CANCELLED':
        return const Color(0xFFEF4444); // Red
      case 'PASSED':
        return const Color(0xFF3B82F6); // Blue
      default:
        return Colors.grey.shade600;
    }
  }

  Color _getConditionColor(String condition) {
    switch (condition.toUpperCase()) {
      case 'GOOD':
        return const Color(0xFF10B981);
      case 'FAIR':
        return const Color(0xFF3B82F6);
      case 'POOR':
        return const Color(0xFFF59E0B);
      case 'BROKEN':
        return const Color(0xFFEF4444);
      case 'MISSING':
        return const Color(0xFF9333EA);
      default:
        return Colors.grey;
    }
  }

  String _fmtKsh(dynamic v) {
    final numVal = double.tryParse(v?.toString() ?? '0') ?? 0.0;
    return 'KSh ${NumberFormat('#,##0.00').format(numVal)}';
  }

  List<dynamic> _getNormalizedChecklist() {
    if (_inspection == null) return [];
    var cl = _inspection!['checklist'];
    if (cl is String && cl.isNotEmpty) {
      try {
        cl = jsonDecode(cl);
        _inspection!['checklist'] = cl;
      } catch (_) {
        return [];
      }
    }
    if (cl is List) {
      return cl;
    }
    return [];
  }

  Future<void> _updateChecklistItemCondition(int sectionIndex, int itemIndex, String newCondition) async {
    if (_inspection == null) return;
    final checklist = List<dynamic>.from(_getNormalizedChecklist());
    if (sectionIndex >= checklist.length) return;

    final section = Map<String, dynamic>.from(checklist[sectionIndex] as Map);
    final items = List<dynamic>.from(section['items'] as List<dynamic>? ?? []);
    if (itemIndex >= items.length) return;

    final item = Map<String, dynamic>.from(items[itemIndex] as Map);
    item['condition'] = newCondition;
    items[itemIndex] = item;
    section['items'] = items;
    checklist[sectionIndex] = section;

    setState(() {
      _inspection!['checklist'] = checklist;
    });

    // If marked as BROKEN or MISSING, prompt to add damage record directly from catalog
    if ((newCondition == 'BROKEN' || newCondition == 'MISSING') && widget.isOwner) {
      _promptAddDamageForItem(item['name']?.toString() ?? 'Item');
    }

    _autoSaveChecklist();
  }

  Future<void> _autoSaveChecklist() async {
    if (_isSavingChecklist || _inspection == null) return;
    _isSavingChecklist = true;
    try {
      await _apiService.updateInspection(widget.inspectionId, {
        'checklist': _inspection!['checklist'],
      });
    } catch (_) {} finally {
      _isSavingChecklist = false;
    }
  }

  void _promptAddDamageForItem(String itemName) {
    // Find item in catalog if exists
    final match = _catalog.firstWhere(
      (c) => c['name'].toString().toLowerCase().contains(itemName.toLowerCase()) ||
          itemName.toLowerCase().contains(c['name'].toString().toLowerCase()),
      orElse: () => null,
    );

    _openAddDamageDialog(
      prefilledName: itemName,
      prefilledPrice: match != null ? double.tryParse(match['default_price']?.toString() ?? '0') : null,
      prefilledDesc: match != null ? match['description']?.toString() : null,
    );
  }

  void _openAddDamageDialog({String? prefilledName, double? prefilledPrice, String? prefilledDesc}) {
    showDialog(
      context: context,
      builder: (ctx) => _AddDamageDialog(
        catalog: _catalog,
        prefilledName: prefilledName,
        prefilledPrice: prefilledPrice,
        prefilledDesc: prefilledDesc,
        onSave: (data) async {
          try {
            await _apiService.addInspectionDamage(widget.inspectionId, data);
            await _loadAll();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Item recorded and deduction calculated!'),
                  backgroundColor: Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to record damage: $e'), backgroundColor: Colors.red),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _deleteDamage(int damageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Damage Item'),
        content: const Text('Are you sure you want to remove this deduction item?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _apiService.deleteInspectionDamage(damageId);
      await _loadAll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete item: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openFinalizeRefundDialog() {
    if (_reconciliation == null) return;

    showDialog(
      context: context,
      builder: (ctx) => _FinalizeRefundDialog(
        reconciliation: _reconciliation!,
        onFinalize: (data) async {
          try {
            await _apiService.finalizeDepositRefund(widget.inspectionId, data);
            await _loadAll();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Deposit reconciliation settled and recorded successfully!'),
                  backgroundColor: Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to finalize refund: $e'), backgroundColor: Colors.red),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF13151B) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1A1D24) : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.navy;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(title: const Text('Inspection Details'), elevation: 0),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.teal)),
      );
    }

    if (_error != null || _inspection == null) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(title: const Text('Inspection Details'), elevation: 0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Failed to load inspection: $_error', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadAll, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final lease = _inspection!['lease'] as Map<String, dynamic>?;
    final unit = lease?['unit'] as Map<String, dynamic>?;
    final property = unit?['property'] as Map<String, dynamic>?;
    final tenant = lease?['tenant'] as Map<String, dynamic>?;
    final damages = (_inspection!['damages'] as List<dynamic>? ?? []);

    final type = _inspection!['inspection_type']?.toString().toUpperCase() ?? 'ROUTINE';
    final status = _inspection!['status']?.toString().toUpperCase() ?? 'SCHEDULED';
    final dateStr = _inspection!['date']?.toString();
    final parsedDate = dateStr != null ? DateTime.tryParse(dateStr) : null;

    final depositHeld = double.tryParse(lease?['deposit_amount']?.toString() ?? '0') ?? 0.0;
    final totalDeductions = double.tryParse(_inspection!['total_deductions']?.toString() ?? '0') ?? 0.0;
    final netRefund = (depositHeld - totalDeductions).clamp(0.0, double.infinity);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          '$type Inspection #${_inspection!['id']}',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadAll,
          ),
          if (widget.isOwner)
            PopupMenuButton<String>(
              onSelected: (val) async {
                if (val == 'MARK_COMPLETED') {
                  await _apiService.updateInspection(widget.inspectionId, {'status': 'COMPLETED'});
                  await _loadAll();
                } else if (val == 'MARK_SCHEDULED') {
                  await _apiService.updateInspection(widget.inspectionId, {'status': 'SCHEDULED'});
                  await _loadAll();
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'MARK_COMPLETED', child: Text('Mark as Completed')),
                const PopupMenuItem(value: 'MARK_SCHEDULED', child: Text('Mark as Scheduled')),
              ],
            )
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0084FF),
          unselectedLabelColor: isDark ? Colors.white60 : Colors.grey.shade600,
          indicatorColor: const Color(0xFF0084FF),
          indicatorWeight: 3,
          labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            const Tab(icon: Icon(Icons.checklist_rounded, size: 20), text: 'Condition Checklist'),
            Tab(icon: const Icon(Icons.build_circle_outlined, size: 20), text: 'Damages & Items (${damages.length})'),
            const Tab(icon: Icon(Icons.account_balance_wallet_outlined, size: 20), text: 'Deposit Settlement'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Top Summary Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    type == 'CHECKIN'
                        ? Icons.login_rounded
                        : (type == 'CHECKOUT' ? Icons.logout_rounded : Icons.fact_check_outlined),
                    color: _getStatusColor(status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            unit != null ? 'Unit ${unit['unit_number']}' : 'Unit Inspection',
                            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: textColor),
                          ),
                          if (property != null) ...[
                            Text(' • ', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey)),
                            Flexible(
                              child: Text(
                                property['name']?.toString() ?? '',
                                style: GoogleFonts.dmSans(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey.shade700),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Tenant: ${tenant != null ? "${tenant['first_name'] ?? ''} ${tenant['last_name'] ?? ''}".trim() : "Unknown"} • Date: ${parsedDate != null ? DateFormat('MMM d, yyyy').format(parsedDate) : "Not set"}',
                        style: GoogleFonts.dmSans(fontSize: 12.5, color: isDark ? Colors.white54 : Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getStatusColor(status).withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChecklistTab(isDark, cardBg, textColor),
                _buildDamagesTab(isDark, cardBg, textColor, damages),
                _buildDepositSettlementTab(isDark, cardBg, textColor, depositHeld, totalDeductions, netRefund),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB 1: Check In / Out Checklist ───
  Widget _buildChecklistTab(bool isDark, Color cardBg, Color textColor) {
    final checklist = _getNormalizedChecklist();

    if (checklist.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.checklist, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No checklist sections available.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final catalogRes = await _apiService.getInspectionCatalog();
                final catalogData = ApiService.extractMap(catalogRes);
                final defaultSections = catalogData['default_checklist'] ?? [];
                await _apiService.updateInspection(widget.inspectionId, {'checklist': defaultSections});
                await _loadAll();
              },
              child: const Text('Load Standard Checklist Template'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: checklist.length,
      itemBuilder: (context, sectionIndex) {
        final section = checklist[sectionIndex] as Map<String, dynamic>;
        final categoryName = section['category']?.toString() ?? 'Section';
        final items = (section['items'] as List<dynamic>? ?? []);

        return Card(
          color: cardBg,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0084FF),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      categoryName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...List.generate(items.length, (itemIndex) {
                  final item = items[itemIndex] as Map<String, dynamic>;
                  final name = item['name']?.toString() ?? 'Item';
                  final condition = item['condition']?.toString().toUpperCase() ?? 'GOOD';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF222630) : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Condition Selector Chips
                          Wrap(
                            spacing: 4,
                            children: ['GOOD', 'FAIR', 'POOR', 'BROKEN', 'MISSING'].map((cond) {
                              final isSelected = condition == cond;
                              final condColor = _getConditionColor(cond);

                              return InkWell(
                                onTap: () => _updateChecklistItemCondition(sectionIndex, itemIndex, cond),
                                borderRadius: BorderRadius.circular(6),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 120),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected ? condColor : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isSelected ? condColor : (isDark ? Colors.white24 : Colors.grey.shade300),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    cond,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? Colors.white : (isDark ? Colors.white60 : Colors.grey.shade700),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── TAB 2: Damages, Broken Items & Pricing ───
  Widget _buildDamagesTab(bool isDark, Color cardBg, Color textColor, List<dynamic> damages) {
    return Column(
      children: [
        // Top action bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recorded Damages & Replacements',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: textColor),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Broken Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0084FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _openAddDamageDialog(),
              ),
            ],
          ),
        ),

        // List of damages
        Expanded(
          child: damages.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.task_alt_outlined, size: 54, color: Color(0xFF10B981)),
                        const SizedBox(height: 12),
                        Text(
                          'No damages or broken items recorded!',
                          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: textColor),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Everything is in pristine condition or no deductions have been logged yet.',
                          style: GoogleFonts.dmSans(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Deduction Item'),
                          onPressed: () => _openAddDamageDialog(),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: damages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final damage = damages[index] as Map<String, dynamic>;
                    final id = damage['id'] is int ? damage['id'] : int.tryParse(damage['id'].toString()) ?? 0;
                    final itemName = damage['item_name']?.toString() ?? 'Damage Item';
                    final condition = damage['condition']?.toString() ?? 'BROKEN';
                    final qty = damage['quantity'] ?? 1;
                    final unitPrice = damage['unit_price'] ?? 0;
                    final cost = damage['cost'] ?? 0;
                    final desc = damage['description']?.toString() ?? '';
                    final chargeTarget = damage['charge_target']?.toString() ?? 'TENANT_DEPOSIT';

                    return Card(
                      color: cardBg,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.broken_image_outlined, color: Colors.red, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          itemName,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _fmtKsh(cost),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.red.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    desc,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getConditionColor(condition).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          condition,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: _getConditionColor(condition),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Qty: $qty × ${_fmtKsh(unitPrice)}',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 11,
                                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          chargeTarget == 'TENANT_DEPOSIT' ? 'Deposit Deduction' : chargeTarget,
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.blue),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (widget.isOwner)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                tooltip: 'Remove item',
                                onPressed: () => _deleteDamage(id),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ─── TAB 3: Deposit Settlement & Deduction Calculations ───
  Widget _buildDepositSettlementTab(
    bool isDark,
    Color cardBg,
    Color textColor,
    double depositHeld,
    double totalDeductions,
    double netRefund,
  ) {
    final recon = _reconciliation;
    final itemized = recon?['itemized_deductions'] as List<dynamic>? ?? [];
    final arrears = recon?['itemized_arrears'] as List<dynamic>? ?? [];
    final unpaidBills = double.tryParse(recon?['total_unpaid_bills']?.toString() ?? '0') ?? 0.0;
    final deficit = double.tryParse(recon?['tenant_deficit_owing']?.toString() ?? '0') ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Settlement Math Summary Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 650;
              final cards = [
                _buildMathCard(
                  title: 'Security Deposit Held',
                  amount: _fmtKsh(depositHeld),
                  subtitle: 'From original tenancy lease',
                  icon: Icons.shield_outlined,
                  color: const Color(0xFF10B981),
                  cardBg: cardBg,
                  textColor: textColor,
                  isDark: isDark,
                ),
                _buildMathCard(
                  title: 'Damage Deductions',
                  amount: '- ${_fmtKsh(totalDeductions)}',
                  subtitle: '${itemized.length} broken/missing items',
                  icon: Icons.construction_outlined,
                  color: const Color(0xFFEF4444),
                  cardBg: cardBg,
                  textColor: textColor,
                  isDark: isDark,
                ),
                _buildMathCard(
                  title: 'Unpaid Bills / Rent',
                  amount: '- ${_fmtKsh(unpaidBills)}',
                  subtitle: '${arrears.length} pending invoices',
                  icon: Icons.receipt_long_outlined,
                  color: const Color(0xFFF59E0B),
                  cardBg: cardBg,
                  textColor: textColor,
                  isDark: isDark,
                ),
                _buildMathCard(
                  title: 'Net Refund to Tenant',
                  amount: _fmtKsh(netRefund),
                  subtitle: deficit > 0 ? 'Deficit owing: ${_fmtKsh(deficit)}' : 'Eligible for refund',
                  icon: Icons.account_balance_wallet,
                  color: const Color(0xFF0084FF),
                  cardBg: cardBg,
                  textColor: textColor,
                  isDark: isDark,
                  isHighlight: true,
                ),
              ];

              if (isSmall) {
                return Column(children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList());
              }
              return Row(
                children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: c))).toList(),
              );
            },
          ),

          const SizedBox(height: 24),

          // Itemized Deductions Table
          Text(
            'Itemized Deposit Deductions Breakdown',
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: textColor),
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
            ),
            child: itemized.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No deductions applied. Full deposit is eligible for refund.',
                        style: GoogleFonts.dmSans(color: isDark ? Colors.white60 : Colors.grey.shade600),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: itemized.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade100),
                    itemBuilder: (context, index) {
                      final item = itemized[index] as Map<String, dynamic>;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.withValues(alpha: 0.1),
                          child: const Icon(Icons.close_rounded, color: Colors.red, size: 18),
                        ),
                        title: Text(item['item_name']?.toString() ?? 'Item', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${item['condition']} • Qty: ${item['quantity']} × ${_fmtKsh(item['unit_price'])}',
                          style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade600, fontSize: 12),
                        ),
                        trailing: Text(
                          _fmtKsh(item['cost']),
                          style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.red),
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 24),

          // Final Action Bar (Finalize refund, vacate tenant, record transaction)
          if (widget.isOwner)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0084FF).withValues(alpha: 0.08),
                    const Color(0xFF00C6FF).withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF0084FF).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined, color: Color(0xFF0084FF), size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Finalize Move-Out & Settle Deposit',
                          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: textColor),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Disburse the net refund amount to the tenant, release deductions, and optionally mark the unit vacant.',
                          style: GoogleFonts.dmSans(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Process Settlement'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0084FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _openFinalizeRefundDialog,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMathCard({
    required String title,
    required String amount,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color cardBg,
    required Color textColor,
    required bool isDark,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isHighlight ? color.withValues(alpha: 0.08) : cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlight ? color.withValues(alpha: 0.4) : (isDark ? Colors.white12 : Colors.grey.shade200),
          width: isHighlight ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.dmSans(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey.shade600, fontWeight: FontWeight.w500)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            amount,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isHighlight ? color : textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.dmSans(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// ─── ADD DAMAGE / ITEM DIALOG WITH LIVE CATALOG LOOKUP ───
class _AddDamageDialog extends StatefulWidget {
  final List<dynamic> catalog;
  final String? prefilledName;
  final double? prefilledPrice;
  final String? prefilledDesc;
  final Function(Map<String, dynamic> data) onSave;

  const _AddDamageDialog({
    required this.catalog,
    this.prefilledName,
    this.prefilledPrice,
    this.prefilledDesc,
    required this.onSave,
  });

  @override
  State<_AddDamageDialog> createState() => _AddDamageDialogState();
}

class _AddDamageDialogState extends State<_AddDamageDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _unitPriceCtrl = TextEditingController();
  final TextEditingController _qtyCtrl = TextEditingController(text: '1');
  String _condition = 'BROKEN';
  String _chargeTarget = 'TENANT_DEPOSIT';

  @override
  void initState() {
    super.initState();
    if (widget.prefilledName != null) _nameCtrl.text = widget.prefilledName!;
    if (widget.prefilledDesc != null) _descCtrl.text = widget.prefilledDesc!;
    if (widget.prefilledPrice != null) _unitPriceCtrl.text = widget.prefilledPrice!.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _unitPriceCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  void _selectCatalogItem(Map<String, dynamic> item) {
    setState(() {
      _nameCtrl.text = item['name']?.toString() ?? '';
      _descCtrl.text = item['description']?.toString() ?? '';
      _unitPriceCtrl.text = (item['default_price'] ?? 0.0).toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final qty = int.tryParse(_qtyCtrl.text) ?? 1;
    final price = double.tryParse(_unitPriceCtrl.text) ?? 0.0;
    final totalCost = qty * price;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.broken_image_outlined, color: Colors.red, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Record Broken Item / Deduction',
                        style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 14),

                // Quick Catalog Item Picker Dropdown
                if (widget.catalog.isNotEmpty) ...[
                  Text('Quick-Pick from Standard Pricing Catalog:', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Map<String, dynamic>>(
                        isExpanded: true,
                        hint: const Text('Select standard item (e.g. window glass, paint, tap)...'),
                        items: widget.catalog.map((catItem) {
                          final c = Map<String, dynamic>.from(catItem as Map);
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: c,
                            child: Text(
                              '${c['name']} - KSh ${c['default_price']}',
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) _selectCatalogItem(val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: InputDecoration(
                            labelText: 'Item Name *',
                            hintText: 'e.g. Window pane, Bathroom Shower Head',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Item name required' : null,
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _condition,
                                decoration: InputDecoration(
                                  labelText: 'Condition',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'BROKEN', child: Text('Broken')),
                                  DropdownMenuItem(value: 'MISSING', child: Text('Missing')),
                                  DropdownMenuItem(value: 'POOR', child: Text('Poor')),
                                  DropdownMenuItem(value: 'FAIR', child: Text('Fair')),
                                ],
                                onChanged: (v) => setState(() => _condition = v!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _qtyCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Quantity',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _unitPriceCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Unit Price (KSh) *',
                                  prefixText: 'KSh ',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onChanged: (_) => setState(() {}),
                                validator: (v) => v == null || double.tryParse(v) == null ? 'Valid price required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Total Deduction:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    Text(
                                      'KSh ${NumberFormat('#,##0.00').format(totalCost)}',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _descCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Damage Description / Notes',
                            hintText: 'e.g. Cracked lower pane in master bedroom',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        DropdownButtonFormField<String>(
                          initialValue: _chargeTarget,
                          decoration: InputDecoration(
                            labelText: 'Charge Target',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'TENANT_DEPOSIT', child: Text('Deduct from Tenant Security Deposit')),
                            DropdownMenuItem(value: 'DIRECT_BILL', child: Text('Bill Directly to Tenant')),
                            DropdownMenuItem(value: 'LANDLORD_ACC', child: Text('Covered by Landlord / Property')),
                          ],
                          onChanged: (v) => setState(() => _chargeTarget = v!),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0084FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.pop(context);
                          widget.onSave({
                            'item_name': _nameCtrl.text.trim(),
                            'condition': _condition,
                            'quantity': int.tryParse(_qtyCtrl.text) ?? 1,
                            'unit_price': double.tryParse(_unitPriceCtrl.text) ?? 0.0,
                            'cost': totalCost,
                            'description': _descCtrl.text.trim(),
                            'charge_target': _chargeTarget,
                          });
                        }
                      },
                      child: const Text('Add Deduction Item'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── FINALIZE DEPOSIT REFUND DIALOG ───
class _FinalizeRefundDialog extends StatefulWidget {
  final Map<String, dynamic> reconciliation;
  final Function(Map<String, dynamic> data) onFinalize;

  const _FinalizeRefundDialog({required this.reconciliation, required this.onFinalize});

  @override
  State<_FinalizeRefundDialog> createState() => _FinalizeRefundDialogState();
}

class _FinalizeRefundDialogState extends State<_FinalizeRefundDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _refundAmountCtrl;
  final TextEditingController _refCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  String _paymentMethod = 'MPESA';
  bool _vacateUnit = true;
  bool _terminateLease = true;

  @override
  void initState() {
    super.initState();
    final netRefund = double.tryParse(widget.reconciliation['net_refund_amount']?.toString() ?? '0') ?? 0.0;
    _refundAmountCtrl = TextEditingController(text: netRefund.toStringAsFixed(2));
    _refCtrl.text = 'DEP-REF-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }

  @override
  void dispose() {
    _refundAmountCtrl.dispose();
    _refCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final depositHeld = widget.reconciliation['deposit_held'] ?? 0;
    final deductions = widget.reconciliation['total_deductions'] ?? 0;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.account_balance_wallet, color: Color(0xFF0084FF)),
          SizedBox(width: 8),
          Text('Finalize Deposit Settlement'),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0084FF).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Held: KSh $depositHeld', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text('Deductions: - KSh $deductions', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.red)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _refundAmountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Refund Amount to Tenant (KSh)',
                    prefixText: 'KSh ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) => v == null || double.tryParse(v) == null ? 'Valid amount required' : null,
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  decoration: InputDecoration(
                    labelText: 'Payout Method',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'MPESA', child: Text('M-Pesa')),
                    DropdownMenuItem(value: 'BANK_TRANSFER', child: Text('Bank Transfer (EFT/RTGS)')),
                    DropdownMenuItem(value: 'CASH', child: Text('Cash')),
                  ],
                  onChanged: (v) => setState(() => _paymentMethod = v!),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _refCtrl,
                  decoration: InputDecoration(
                    labelText: 'Transaction Reference / Receipt #',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),

                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _vacateUnit,
                  title: const Text('Mark unit as VACANT immediately', style: TextStyle(fontSize: 13)),
                  onChanged: (v) => setState(() => _vacateUnit = v ?? true),
                ),

                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _terminateLease,
                  title: const Text('Mark lease as TERMINATED (Checkout complete)', style: TextStyle(fontSize: 13)),
                  onChanged: (v) => setState(() => _terminateLease = v ?? true),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0084FF),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context);
              widget.onFinalize({
                'amount_refunded': double.tryParse(_refundAmountCtrl.text) ?? 0.0,
                'deductions_retained': deductions,
                'payment_method': _paymentMethod,
                'transaction_reference': _refCtrl.text.trim(),
                'notes': _notesCtrl.text.trim(),
                'vacate_unit_now': _vacateUnit,
                'terminate_lease_now': _terminateLease,
              });
            }
          },
          child: const Text('Confirm Settlement'),
        ),
      ],
    );
  }
}
