import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/unit_model.dart';
import '../../models/unit_type_model.dart';
import '../../providers/property_provider.dart';
import '../../providers/unit_provider.dart';

class UnitsScreen extends StatefulWidget {
  const UnitsScreen({super.key});

  @override
  State<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends State<UnitsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  dynamic _selectedPropertyId;
  String _statusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().loadProperties();
      context.read<UnitProvider>().loadUnits();
      context.read<UnitProvider>().loadUnitTypes();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        title: const Text(
          'Units & Unit Categories',
          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1C2E27)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2A9D8F),
          unselectedLabelColor: const Color(0xFF77847D),
          indicatorColor: const Color(0xFF2A9D8F),
          tabs: const [
            Tab(icon: Icon(Icons.meeting_room_outlined), text: 'Units'),
            Tab(icon: Icon(Icons.category_outlined), text: 'Unit Types'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUnitsTab(),
          _buildUnitTypesTab(),
        ],
      ),
    );
  }

  // ==================== UNITS TAB ====================

  Widget _buildUnitsTab() {
    return Consumer2<UnitProvider, PropertyProvider>(
      builder: (context, unitProv, propProv, _) {
        final query = _searchController.text.trim().toLowerCase();
        final filteredUnits = unitProv.units.where((unit) {
          if (_selectedPropertyId != null && unit.propertyId?.toString() != _selectedPropertyId.toString()) {
            return false;
          }
          if (_statusFilter != 'ALL' && unit.status.toUpperCase() != _statusFilter) {
            return false;
          }
          if (query.isNotEmpty) {
            final matchesNum = unit.unitNumber.toLowerCase().contains(query);
            final matchesProp = (unit.property?.name ?? '').toLowerCase().contains(query);
            final matchesDesc = unit.description.toLowerCase().contains(query);
            if (!matchesNum && !matchesProp && !matchesDesc) return false;
          }
          return true;
        }).toList();

        return Column(
          children: [
            // Filter Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search unit #, property...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Property Filter Dropdown
                  Expanded(
                    child: DropdownButtonFormField<dynamic>(
                      initialValue: _selectedPropertyId,
                      decoration: const InputDecoration(
                        labelText: 'Filter Property',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Properties')),
                        ...propProv.properties.map((p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.name, overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedPropertyId = val);
                        unitProv.loadUnits(propertyId: val, refresh: true);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Status Filter Dropdown
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _statusFilter,
                      decoration: const InputDecoration(
                        labelText: 'Filter Status',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ALL', child: Text('All Statuses')),
                        DropdownMenuItem(value: 'VACANT', child: Text('Vacant')),
                        DropdownMenuItem(value: 'OCCUPIED', child: Text('Occupied')),
                        DropdownMenuItem(value: 'MAINTENANCE', child: Text('Maintenance')),
                        DropdownMenuItem(value: 'RESERVED', child: Text('Reserved')),
                      ],
                      onChanged: (val) => setState(() => _statusFilter = val ?? 'ALL'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => _openUnitEditor(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Unit'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => unitProv.loadUnits(propertyId: _selectedPropertyId, refresh: true),
                child: unitProv.isLoading && unitProv.units.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : filteredUnits.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.meeting_room_outlined, size: 54, color: Color(0xFF87948D)),
                                const SizedBox(height: 12),
                                const Text('No units found matching criteria.', style: TextStyle(color: Color(0xFF77847D))),
                                const SizedBox(height: 12),
                                FilledButton.icon(
                                  onPressed: () => _openUnitEditor(context),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create New Unit'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredUnits.length,
                            itemBuilder: (context, index) {
                              final unit = filteredUnits[index];
                              return _UnitCard(
                                unit: unit,
                                onEdit: () => _openUnitEditor(context, unit),
                                onDelete: () => _deleteUnit(context, unit),
                              );
                            },
                          ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ==================== UNIT TYPES TAB ====================

  Widget _buildUnitTypesTab() {
    return Consumer<UnitProvider>(
      builder: (context, unitProv, _) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Configured Unit Categories & Pricing Models',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1C2E27)),
                  ),
                  FilledButton.icon(
                    onPressed: () => _openUnitTypeEditor(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Unit Type'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => unitProv.loadUnitTypes(refresh: true),
                child: unitProv.isLoadingUnitTypes && unitProv.unitTypes.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : unitProv.unitTypes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.category_outlined, size: 54, color: Color(0xFF87948D)),
                                const SizedBox(height: 12),
                                const Text('No unit types created yet.', style: TextStyle(color: Color(0xFF77847D))),
                                const SizedBox(height: 12),
                                FilledButton.icon(
                                  onPressed: () => _openUnitTypeEditor(context),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create Unit Type'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: unitProv.unitTypes.length,
                            itemBuilder: (context, index) {
                              final type = unitProv.unitTypes[index];
                              return _UnitTypeCard(
                                unitType: type,
                                onEdit: () => _openUnitTypeEditor(context, type),
                                onDelete: () => _deleteUnitType(context, type),
                              );
                            },
                          ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ==================== MODALS & ACTIONS ====================

  Future<void> _openUnitEditor(BuildContext context, [UnitModel? unit]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UnitEditorModal(unit: unit),
    );
  }

  Future<void> _deleteUnit(BuildContext context, UnitModel unit) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<UnitProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Unit ${unit.unitNumber}?'),
        content: const Text('This action cannot be undone if there are no active leases.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB84C43)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final success = await provider.deleteUnit(unit.id);
    if (success) {
      messenger.showSnackBar(const SnackBar(content: Text('Unit deleted successfully')));
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Failed to delete unit')),
      );
    }
  }

  Future<void> _openUnitTypeEditor(BuildContext context, [UnitTypeModel? unitType]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UnitTypeEditorModal(unitType: unitType),
    );
  }

  Future<void> _deleteUnitType(BuildContext context, UnitTypeModel unitType) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<UnitProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${unitType.name}"?'),
        content: const Text('Unit types assigned to existing units cannot be deleted until unassigned.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB84C43)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final success = await provider.deleteUnitType(unitType.id);
    if (success) {
      messenger.showSnackBar(const SnackBar(content: Text('Unit type deleted')));
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.unitTypeErrorMessage ?? 'Failed to delete unit type')),
      );
    }
  }
}

// ==================== CARDS ====================

class _UnitCard extends StatelessWidget {
  final UnitModel unit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UnitCard({required this.unit, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (unit.status.toUpperCase()) {
      'OCCUPIED' => const Color(0xFF2A9D8F),
      'MAINTENANCE' => const Color(0xFFE76F51),
      'RESERVED' => const Color(0xFFE9C46A),
      _ => const Color(0xFF5A7DCE),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE7ECE8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.meeting_room_outlined, color: statusColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Unit ${unit.unitNumber}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1C2E27)),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          unit.status,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor),
                        ),
                      ),
                      if (unit.unitType != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4F1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            unit.unitType!.name,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF536159)),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${unit.property?.name ?? 'Property'}  •  Floor ${unit.floor}  •  ${unit.bedrooms} Bedroom(s)',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF84918A)),
                  ),
                ],
              ),
            ),
            Text(
              NumberFormat.currency(locale: 'en_KE', symbol: 'KES ', decimalDigits: 0).format(unit.rentPrice),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1C2E27)),
            ),
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'edit') onEdit();
                if (val == 'delete') onDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitTypeCard extends StatelessWidget {
  final UnitTypeModel unitType;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UnitTypeCard({required this.unitType, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE7ECE8)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF2A9D8F).withValues(alpha: .12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.category_outlined, color: Color(0xFF2A9D8F)),
        ),
        title: Text(
          unitType.name,
          style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1C2E27)),
        ),
        subtitle: Text(
          unitType.description.isNotEmpty
              ? unitType.description
              : 'Code: ${unitType.code.isNotEmpty ? unitType.code : "N/A"}',
          style: const TextStyle(fontSize: 12, color: Color(0xFF84918A)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (unitType.baseRent > 0)
              Text(
                NumberFormat.currency(locale: 'en_KE', symbol: 'KES ', decimalDigits: 0).format(unitType.baseRent),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1C2E27)),
              ),
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'edit') onEdit();
                if (val == 'delete') onDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== EDITORS ====================

class _UnitEditorModal extends StatefulWidget {
  final UnitModel? unit;

  const _UnitEditorModal({this.unit});

  @override
  State<_UnitEditorModal> createState() => _UnitEditorModalState();
}

class _UnitEditorModalState extends State<_UnitEditorModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _unitNumber;
  late final TextEditingController _floor;
  late final TextEditingController _bedrooms;
  late final TextEditingController _rentPrice;
  late final TextEditingController _description;
  dynamic _propertyId;
  dynamic _unitTypeId;
  String _status = 'VACANT';

  bool get editing => widget.unit != null;

  @override
  void initState() {
    super.initState();
    final unit = widget.unit;
    _unitNumber = TextEditingController(text: unit?.unitNumber ?? '');
    _floor = TextEditingController(text: '${unit?.floor ?? 1}');
    _bedrooms = TextEditingController(text: '${unit?.bedrooms ?? 1}');
    _rentPrice = TextEditingController(text: unit?.rentPrice != null ? '${unit!.rentPrice}' : '');
    _description = TextEditingController(text: unit?.description ?? '');
    _propertyId = unit?.propertyId;
    _unitTypeId = unit?.unitTypeId;
    _status = unit?.status.isNotEmpty == true ? unit!.status : 'VACANT';
  }

  @override
  void dispose() {
    _unitNumber.dispose();
    _floor.dispose();
    _bedrooms.dispose();
    _rentPrice.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final properties = context.watch<PropertyProvider>().properties;
    final unitTypes = context.watch<UnitProvider>().unitTypes;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(top: 50, bottom: bottom),
      child: Material(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      editing ? 'Edit Unit' : 'Create Unit',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1C2E27)),
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<dynamic>(
                  initialValue: _propertyId,
                  decoration: const InputDecoration(labelText: 'Property *', border: OutlineInputBorder()),
                  items: properties.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                  onChanged: (val) => setState(() => _propertyId = val),
                  validator: (val) => val == null ? 'Property is required' : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _unitNumber,
                        decoration: const InputDecoration(labelText: 'Unit Number *', border: OutlineInputBorder()),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<dynamic>(
                        initialValue: _unitTypeId,
                        decoration: const InputDecoration(labelText: 'Unit Type', border: OutlineInputBorder()),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('None')),
                          ...unitTypes.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))),
                        ],
                        onChanged: (val) => setState(() => _unitTypeId = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _floor,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Floor', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _bedrooms,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Bedrooms', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _rentPrice,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Rent Price (KES) *', border: OutlineInputBorder()),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Rent is required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _status,
                        decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'VACANT', child: Text('Vacant')),
                          DropdownMenuItem(value: 'OCCUPIED', child: Text('Occupied')),
                          DropdownMenuItem(value: 'MAINTENANCE', child: Text('Maintenance')),
                          DropdownMenuItem(value: 'RESERVED', child: Text('Reserved')),
                        ],
                        onChanged: (val) => setState(() => _status = val ?? _status),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _description,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: context.watch<UnitProvider>().isLoading ? null : _submit,
                    child: Text(editing ? 'Save Changes' : 'Create Unit'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final payload = <String, dynamic>{
      'property_id': _propertyId,
      if (_unitTypeId != null) 'unit_type_id': _unitTypeId,
      'unit_number': _unitNumber.text.trim(),
      'floor': int.tryParse(_floor.text.trim()) ?? 1,
      'bedrooms': int.tryParse(_bedrooms.text.trim()) ?? 1,
      'rent_price': double.tryParse(_rentPrice.text.trim()) ?? 0,
      'status': _status,
      'description': _description.text.trim(),
    };

    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<UnitProvider>();
    final success = editing
        ? await provider.updateUnit(widget.unit!.id, payload)
        : await provider.createUnit(payload);

    if (success) {
      if (mounted) Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(content: Text(editing ? 'Unit updated' : 'Unit created')),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Failed to save unit')),
      );
    }
  }
}

class _UnitTypeEditorModal extends StatefulWidget {
  final UnitTypeModel? unitType;

  const _UnitTypeEditorModal({this.unitType});

  @override
  State<_UnitTypeEditorModal> createState() => _UnitTypeEditorModalState();
}

class _UnitTypeEditorModalState extends State<_UnitTypeEditorModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _baseRent;
  late final TextEditingController _description;

  bool get editing => widget.unitType != null;

  @override
  void initState() {
    super.initState();
    final t = widget.unitType;
    _name = TextEditingController(text: t?.name ?? '');
    _code = TextEditingController(text: t?.code ?? '');
    _baseRent = TextEditingController(text: t != null && t.baseRent > 0 ? '${t.baseRent}' : '');
    _description = TextEditingController(text: t?.description ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _baseRent.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(top: 50, bottom: bottom),
      child: Material(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      editing ? 'Edit Unit Type' : 'Create Unit Type',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1C2E27)),
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Type Name (e.g. 1 Bedroom Deluxe) *', border: OutlineInputBorder()),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _code,
                        decoration: const InputDecoration(labelText: 'Code (e.g. 1BD-DLX)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _baseRent,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Base Rent (KES)', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _description,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: context.watch<UnitProvider>().isLoadingUnitTypes ? null : _submit,
                    child: Text(editing ? 'Save Changes' : 'Create Unit Type'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final payload = <String, dynamic>{
      'name': _name.text.trim(),
      'code': _code.text.trim(),
      'base_rent': double.tryParse(_baseRent.text.trim()) ?? 0,
      'description': _description.text.trim(),
    };

    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<UnitProvider>();
    final success = editing
        ? await provider.updateUnitType(widget.unitType!.id, payload)
        : await provider.createUnitType(payload);

    if (success) {
      if (mounted) Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(content: Text(editing ? 'Unit type updated' : 'Unit type created')),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.unitTypeErrorMessage ?? 'Failed to save unit type')),
      );
    }
  }
}
