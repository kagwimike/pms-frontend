import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_endpoints.dart';
import '../../models/property_model.dart';
import '../../providers/property_provider.dart';

class PropertiesScreen extends StatefulWidget {
  const PropertiesScreen({super.key});

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _typeFilter = 'ALL';
  String _statusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().loadProperties();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PropertyProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF6F8F7),
          appBar: AppBar(
            title: const Text(
              'Properties',
              style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1C2E27)),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              FilledButton.icon(
                onPressed: provider.isLoading ? null : () => _openEditor(),
                icon: const Icon(Icons.add_home_work_outlined, size: 18),
                label: const Text('Add property'),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: Column(
            children: [
              // Search & Filter Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search property name, city, address...',
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
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _typeFilter,
                        decoration: InputDecoration(
                          labelText: 'Type',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('All Types')),
                          DropdownMenuItem(value: 'APARTMENT', child: Text('Apartment')),
                          DropdownMenuItem(value: 'HOTEL', child: Text('Hotel')),
                          DropdownMenuItem(value: 'AIRBNB', child: Text('Airbnb')),
                        ],
                        onChanged: (val) => setState(() => _typeFilter = val ?? 'ALL'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _statusFilter,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('All Statuses')),
                          DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                          DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
                          DropdownMenuItem(value: 'MAINTENANCE', child: Text('Maintenance')),
                        ],
                        onChanged: (val) => setState(() => _statusFilter = val ?? 'ALL'),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.loadProperties(refresh: true),
                  child: _buildBody(provider),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(PropertyProvider provider) {
    if (provider.isLoading && provider.properties.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null && provider.properties.isEmpty) {
      return _MessageState(
        message: provider.errorMessage!,
        action: () => provider.loadProperties(refresh: true),
      );
    }
    if (provider.properties.isEmpty) {
      return _MessageState(
        message: 'No properties found. Add your first property to get started.',
        action: _openEditor,
        actionLabel: 'Add property',
      );
    }

    final query = _searchController.text.trim().toLowerCase();
    final filtered = provider.properties.where((p) {
      if (query.isNotEmpty) {
        final matchesName = p.name.toLowerCase().contains(query);
        final matchesCity = p.city.toLowerCase().contains(query);
        final matchesAddress = p.address.toLowerCase().contains(query);
        if (!matchesName && !matchesCity && !matchesAddress) return false;
      }
      if (_typeFilter != 'ALL' && p.propertyType.toUpperCase() != _typeFilter) {
        return false;
      }
      if (_statusFilter != 'ALL' && p.status.toUpperCase() != _statusFilter) {
        return false;
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Text('No properties match your current search/filter criteria.', style: TextStyle(color: Color(0xFF84918A))),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 1150
            ? 3
            : constraints.maxWidth > 700
                ? 2
                : 1;
        return GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          itemCount: filtered.length + (provider.hasMore ? 1 : 0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.25,
          ),
          itemBuilder: (context, index) {
            if (index == filtered.length) {
              provider.loadProperties();
              return const Center(child: CircularProgressIndicator());
            }
            final property = filtered[index];
            return _PropertyCard(
              property: property,
              onTap: () => _showPropertyDetails(property),
              onEdit: () => _openEditor(property),
              onDelete: () => _deleteProperty(property),
            );
          },
        );
      },
    );
  }

  Future<void> _openEditor([PropertyModel? property]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PropertyEditor(property: property),
    );
  }

  Future<void> _showPropertyDetails(PropertyModel property) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PropertyDetailsSheet(property: property),
    );
  }

  Future<void> _deleteProperty(PropertyModel property) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${property.name}?'),
        content: const Text('This will archive the property and its listing.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB84C43),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<PropertyProvider>();
    final success = await provider.deleteProperty(property.id);
    if (success) {
      messenger.showSnackBar(const SnackBar(content: Text('Property archived successfully')));
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Delete failed')),
      );
    }
  }
}

class _PropertyCard extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PropertyCard({
    required this.property,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE7ECE8)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: property.images.isEmpty
                  ? _imageFallback()
                  : Image.network(
                      ApiEndpoints.resolveMediaUrl(property.images.first),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, _, _) => _imageFallback(),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          property.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Color(0xFF1C2E27),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${property.propertyType.isEmpty ? "Property" : property.propertyType}  •  ${property.city}  •  ${property.totalUnits} Units',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF84918A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'view') onTap();
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'view', child: Text('View Details')),
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback() => Container(
        color: const Color(0xFFDCEBE2),
        child: const Center(
          child: Icon(
            Icons.home_work_outlined,
            size: 48,
            color: Color(0xFF54836D),
          ),
        ),
      );
}

class _PropertyDetailsSheet extends StatelessWidget {
  final PropertyModel property;

  const _PropertyDetailsSheet({required this.property});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(top: 50, bottom: bottom),
      child: Material(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      property.name,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1C2E27)),
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 12),
              if (property.images.isNotEmpty)
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: property.images.length,
                    itemBuilder: (ctx, idx) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          ApiEndpoints.resolveMediaUrl(property.images[idx]),
                          width: 240,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 240,
                            color: const Color(0xFFDCEBE2),
                            child: const Icon(Icons.home_work_outlined, size: 48, color: Color(0xFF54836D)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _detailRow('Property Type', property.propertyType.isEmpty ? 'APARTMENT' : property.propertyType),
              _detailRow('Status', property.status.isEmpty ? 'ACTIVE' : property.status),
              _detailRow('Address', '${property.address}, ${property.city}, ${property.country}'),
              _detailRow('Total Configured Units', '${property.totalUnits}'),
              if (property.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('Description', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1C2E27))),
                const SizedBox(height: 4),
                Text(property.description, style: const TextStyle(color: Color(0xFF536159))),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.go('/units');
                      },
                      icon: const Icon(Icons.meeting_room_outlined),
                      label: const Text('Manage Units for Property'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF84918A), fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(color: Color(0xFF1C2E27), fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _PropertyEditor extends StatefulWidget {
  final PropertyModel? property;

  const _PropertyEditor({this.property});

  @override
  State<_PropertyEditor> createState() => _PropertyEditorState();
}

class _PropertyEditorState extends State<_PropertyEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _country;
  late final TextEditingController _units;
  late final TextEditingController _description;
  String _type = 'APARTMENT';
  String _status = 'ACTIVE';
  List<XFile> _images = [];

  bool get editing => widget.property != null;

  @override
  void initState() {
    super.initState();
    final property = widget.property;
    _name = TextEditingController(text: property?.name ?? '');
    _address = TextEditingController(text: property?.address ?? '');
    _city = TextEditingController(text: property?.city ?? '');
    _country = TextEditingController(text: property?.country ?? 'Kenya');
    _units = TextEditingController(text: '${property?.totalUnits ?? 1}');
    _description = TextEditingController(text: property?.description ?? '');
    _type = property?.propertyType.isNotEmpty == true
        ? property!.propertyType
        : _type;
    _status = property?.status.isNotEmpty == true
        ? property!.status
        : _status;
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _address,
      _city,
      _country,
      _units,
      _description,
    ]) {
      controller.dispose();
    }
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
                      editing ? 'Edit property' : 'Add property',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1C2E27),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _field(_name, 'Property name'),
                _field(_address, 'Address'),
                Row(
                  children: [
                    Expanded(child: _field(_city, 'City')),
                    const SizedBox(width: 12),
                    Expanded(child: _field(_country, 'Country')),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _type,
                        decoration: const InputDecoration(
                          labelText: 'Property type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'APARTMENT',
                            child: Text('Apartment'),
                          ),
                          DropdownMenuItem(value: 'HOTEL', child: Text('Hotel')),
                          DropdownMenuItem(
                            value: 'AIRBNB',
                            child: Text('Airbnb'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _type = value ?? _type),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _field(_units, 'Total units', numeric: true)),
                  ],
                ),
                if (editing)
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                      DropdownMenuItem(
                        value: 'INACTIVE',
                        child: Text('Inactive'),
                      ),
                      DropdownMenuItem(
                        value: 'MAINTENANCE',
                        child: Text('Maintenance'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _status = value ?? _status),
                  ),
                _field(
                  _description,
                  'Description',
                  maxLines: 3,
                  required: false,
                ),
                if (!editing) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(
                      _images.isEmpty
                          ? 'Choose property images'
                          : '${_images.length} image(s) selected',
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: context.watch<PropertyProvider>().isLoading
                        ? null
                        : _submit,
                    child: Text(editing ? 'Save changes' : 'Create property'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool numeric = false,
    int maxLines = 1,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (value) => value == null || value.trim().isEmpty
                ? '$label is required'
                : null
            : null,
      ),
    );
  }

  Future<void> _pickImages() async {
    final selected = await ImagePicker().pickMultiImage(imageQuality: 85);
    if (!mounted) return;
    setState(() => _images = selected.take(10).toList());
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final fields = <String, dynamic>{
      'name': _name.text.trim(),
      'property_type': _type,
      'address': _address.text.trim(),
      'city': _city.text.trim(),
      'country': _country.text.trim(),
      'total_units': int.tryParse(_units.text.trim()) ?? 1,
      'description': _description.text.trim(),
      if (editing) 'status': _status,
    };
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<PropertyProvider>();
    final success = editing
        ? await provider.updateProperty(widget.property!.id, fields)
        : await provider.createProperty(fields: fields, images: _images);
    if (success) {
      if (mounted) Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(content: Text(editing ? 'Property updated' : 'Property created')),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Save failed')),
      );
    }
  }
}

class _MessageState extends StatelessWidget {
  final String message;
  final VoidCallback? action;
  final String actionLabel;

  const _MessageState({
    required this.message,
    this.action,
    this.actionLabel = 'Retry',
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * .3),
        Center(child: Text(message, textAlign: TextAlign.center)),
        if (action != null)
          Center(
            child: TextButton.icon(
              onPressed: action,
              icon: const Icon(Icons.add),
              label: Text(actionLabel),
            ),
          ),
      ],
    );
  }
}
