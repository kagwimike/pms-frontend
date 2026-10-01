import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class UnitsScreen extends StatefulWidget {
  const UnitsScreen({super.key});

  @override
  State<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends State<UnitsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _units = [];
  String? _error;
  String _statusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final status = _statusFilter == 'ALL' ? null : _statusFilter;
      final response = await _apiService.getUnits(status: status);
      
      if (response.containsKey('data') && response['data'] is List) {
         _units = response['data'];
      } else if (response.containsKey('results') && response['results'] is List) {
         _units = response['results'];
      } else if (response.containsKey('units') && response['units'] is List) {
         _units = response['units'];
      } else {
          _units = response.values.firstWhere((v) => v is List, orElse: () => []);
      }
      
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAddUnitDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddUnitDialog(),
    ).then((result) {
      if (result == true) {
        _loadUnits();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Units',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage all units across your properties',
                    style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.mutedText),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showAddUnitDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Unit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Filter Bar
          Row(
            children: [
              _buildFilterChip('ALL', 'All Units'),
              const SizedBox(width: 8),
              _buildFilterChip('VACANT', 'Vacant'),
              const SizedBox(width: 8),
              _buildFilterChip('OCCUPIED', 'Occupied'),
              const SizedBox(width: 8),
              _buildFilterChip('MAINTENANCE', 'Maintenance'),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.teal))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
                            const SizedBox(height: 16),
                            Text(_error!, style: TextStyle(color: Colors.red.shade700)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadUnits,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _units.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.door_sliding_outlined, size: 64, color: AppTheme.mutedText.withOpacity(0.3)),
                                const SizedBox(height: 16),
                                Text(
                                  'No units found',
                                  style: GoogleFonts.bricolageGrotesque(fontSize: 20, color: AppTheme.navy),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try changing the filter or adding a new unit.',
                                  style: GoogleFonts.dmSans(color: AppTheme.mutedText),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _units.length,
                            itemBuilder: (context, index) {
                              final unit = _units[index];
                              return _UnitListItem(unit: unit);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: GoogleFonts.dmSans(
        color: isSelected ? Colors.white : AppTheme.navy,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
      backgroundColor: Colors.white,
      selectedColor: AppTheme.navy,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? AppTheme.navy : AppTheme.border),
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() => _statusFilter = value);
          _loadUnits();
        }
      },
    );
  }
}

class _UnitListItem extends StatelessWidget {
  final Map<String, dynamic> unit;

  const _UnitListItem({required this.unit});

  @override
  Widget build(BuildContext context) {
    final status = unit['status'] ?? 'UNKNOWN';
    Color statusColor = Colors.grey;
    if (status == 'VACANT') statusColor = Colors.green;
    if (status == 'OCCUPIED') statusColor = AppTheme.navy;
    if (status == 'MAINTENANCE') statusColor = Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Navigate to Unit Details
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.bgGreyGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      unit['unit_number'] ?? '?',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.navy,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unit ${unit['unit_number']}',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.navy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.bed_outlined, size: 14, color: AppTheme.mutedText),
                          const SizedBox(width: 4),
                          Text('${unit['bedrooms'] ?? 1} Bed', style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.mutedText)),
                          const SizedBox(width: 12),
                          Icon(Icons.stairs_outlined, size: 14, color: AppTheme.mutedText),
                          const SizedBox(width: 4),
                          Text('Floor ${unit['floor'] ?? 1}', style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.mutedText)),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'KSh ${unit['rent_price'] ?? 0}',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.mutedText.withOpacity(0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AddUnitDialog extends StatefulWidget {
  const AddUnitDialog({super.key});

  @override
  State<AddUnitDialog> createState() => _AddUnitDialogState();
}

class _AddUnitDialogState extends State<AddUnitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _unitNumberController = TextEditingController();
  final _floorController = TextEditingController(text: '1');
  final _bedroomsController = TextEditingController(text: '1');
  final _rentPriceController = TextEditingController();
  
  // We need to associate a unit with a property. In a real app, you'd fetch properties and select one.
  // For simplicity in this dialog, we'll assume the user types a property ID, or we fetch them.
  final ApiService _apiService = ApiService();
  List<dynamic> _properties = [];
  int? _selectedPropertyId;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    try {
      final response = await _apiService.getProperties(limit: 50);
      List<dynamic> props = [];
      if (response.containsKey('data') && response['data'] is List) props = response['data'];
      else if (response.containsKey('results') && response['results'] is List) props = response['results'];
      else props = response.values.firstWhere((v) => v is List, orElse: () => []);
      
      setState(() {
        _properties = props;
        if (props.isNotEmpty) {
          _selectedPropertyId = props[0]['id'];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Failed to load properties. Can't add unit.";
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _unitNumberController.dispose();
    _floorController.dispose();
    _bedroomsController.dispose();
    _rentPriceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPropertyId == null) {
      setState(() => _error = "Please select a property");
      return;
    }
    
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final data = {
        'property_id': _selectedPropertyId,
        'unit_number': _unitNumberController.text,
        'floor': int.parse(_floorController.text),
        'bedrooms': int.parse(_bedroomsController.text),
        'rent_price': double.parse(_rentPriceController.text),
        'status': 'VACANT',
      };

      await _apiService.createUnit(data);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
       return const Dialog(child: SizedBox(width: 100, height: 100, child: Center(child: CircularProgressIndicator())));
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add New Unit',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.navy,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
                ),
              if (_properties.isEmpty)
                 const Text("You must create a property first before adding units.", style: TextStyle(color: Colors.red)),
              if (_properties.isNotEmpty)
              DropdownButtonFormField<int>(
                value: _selectedPropertyId,
                decoration: _inputDecoration('Select Property'),
                items: _properties.map((p) => DropdownMenuItem<int>(
                  value: p['id'], 
                  child: Text(p['name'] ?? 'Unknown'),
                )).toList(),
                onChanged: (v) => setState(() => _selectedPropertyId = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _unitNumberController,
                decoration: _inputDecoration('Unit Number (e.g. A-101)'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _floorController,
                      decoration: _inputDecoration('Floor'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _bedroomsController,
                      decoration: _inputDecoration('Bedrooms'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rentPriceController,
                decoration: _inputDecoration('Monthly Rent (KSh)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting || _properties.isEmpty ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('SAVE UNIT', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppTheme.teal, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }
}
