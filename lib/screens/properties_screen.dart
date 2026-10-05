import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../services/api_service.dart';
import '../config.dart';
import '../theme/app_theme.dart';

class PropertiesScreen extends StatefulWidget {
  const PropertiesScreen({super.key});

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _properties = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _apiService.getProperties();
      if (response.containsKey('data') && response['data'] is List) {
         _properties = response['data'];
      } else if (response.containsKey('results') && response['results'] is List) {
         _properties = response['results'];
      } else if (response.containsKey('properties') && response['properties'] is List) {
         _properties = response['properties'];
      } else {
          _properties = response.values.firstWhere((v) => v is List, orElse: () => []);
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

  void _showAddPropertyDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddPropertyDialog(),
    ).then((result) {
      if (result == true) {
        _loadProperties();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 400;
    final pad = isSmall ? 16.0 : 28.0;

    return Padding(
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Responsive header
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Properties',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: isSmall ? 22 : 26,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your property portfolio',
                    style: GoogleFonts.dmSans(fontSize: isSmall ? 12 : 14, color: AppTheme.mutedText),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showAddPropertyDialog,
                icon: const Icon(Icons.add, size: 18),
                label: Text(isSmall ? 'Add' : 'Add Property'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.teal,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmall ? 16 : 28),
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
                            Text(_error!, style: TextStyle(color: Colors.red.shade700), textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadProperties,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _properties.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.home_work_outlined, size: 64, color: AppTheme.mutedText.withValues(alpha: 0.3)),
                                const SizedBox(height: 16),
                                Text(
                                  'No properties found',
                                  style: GoogleFonts.bricolageGrotesque(fontSize: 20, color: AppTheme.navy),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Get started by adding your first property.',
                                  style: GoogleFonts.dmSans(color: AppTheme.mutedText),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth < 400) {
                                // Single column list for very small screens
                                return ListView.builder(
                                  itemCount: _properties.length,
                                  itemBuilder: (context, index) {
                                    final property = _properties[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _PropertyCard(property: property),
                                    );
                                  },
                                );
                              }
                              return GridView.builder(
                                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 400,
                                  mainAxisExtent: 220,
                                  crossAxisSpacing: isSmall ? 12 : 20,
                                  mainAxisSpacing: isSmall ? 12 : 20,
                                ),
                                itemCount: _properties.length,
                                itemBuilder: (context, index) {
                                  final property = _properties[index];
                                  return _PropertyCard(property: property);
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final Map<String, dynamic> property;

  const _PropertyCard({required this.property});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Navigate to Property Details
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Property Image Header
                if (property['images'] != null && (property['images'] as List).isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      '${AppConfig.apiBaseUrl.replaceFirst('/api', '')}/media/${property['images'][0]['image']}',
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Icon(Icons.home_work_outlined, size: 40, color: Colors.grey.shade300),
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: property['status'] == 'ACTIVE' 
                              ? Colors.green.withValues(alpha: 0.1) 
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          property['status'] ?? 'UNKNOWN',
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: property['status'] == 'ACTIVE' ? Colors.green.shade700 : Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ),
                    const Icon(Icons.more_horiz, color: AppTheme.mutedText),
                  ],
                ),
                const Spacer(),
                Text(
                  property['name'] ?? 'Unnamed Property',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.navy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.mutedText),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${property['address'] ?? ''}, ${property['city'] ?? ''}',
                        style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.mutedText),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (property['description'] != null && property['description'].toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    property['description'],
                    style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.navy.withValues(alpha: 0.7)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: _buildMiniStat(Icons.door_sliding_outlined, '${property['total_units'] ?? 0} Units')),
                    const SizedBox(width: 8),
                    Flexible(child: _buildMiniStat(Icons.category_outlined, property['property_type'] ?? 'Property')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.navy),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.navy,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class AddPropertyDialog extends StatefulWidget {
  const AddPropertyDialog({super.key});

  @override
  State<AddPropertyDialog> createState() => _AddPropertyDialogState();
}

class _AddPropertyDialogState extends State<AddPropertyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _totalUnitsController = TextEditingController();
  final _amenitiesController = TextEditingController();
  
  String _propertyType = 'APARTMENT';
  bool _isLoading = false;
  String? _error;
  List<XFile> _selectedImages = [];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _descriptionController.dispose();
    _totalUnitsController.dispose();
    _amenitiesController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Create slug from name
      final slug = _nameController.text.toLowerCase().replaceAll(' ', '-').replaceAll(RegExp(r'[^a-z0-9\-]'), '');
      
      final data = {
        'name': _nameController.text,
        'slug': '$slug-${DateTime.now().millisecondsSinceEpoch}',
        'property_type': _propertyType,
        'address': _addressController.text,
        'city': _cityController.text,
        'country': _countryController.text,
        'description': _descriptionController.text,
        'status': 'ACTIVE',
        if (_totalUnitsController.text.isNotEmpty) 'total_units': _totalUnitsController.text,
        if (_amenitiesController.text.isNotEmpty) 'new_amenities': _amenitiesController.text.split(',').map((e) => e.trim()).toList(),
      };

      List<http.MultipartFile> multipartImages = [];
      for (var file in _selectedImages) {
        final bytes = await file.readAsBytes();
        
        String? mimeType = file.mimeType;
        String filename = file.name;

        if (mimeType == null || mimeType.isEmpty) {
          final ext = filename.contains('.') ? filename.split('.').last.toLowerCase() : '';
          if (ext == 'jpg' || ext == 'jpeg') mimeType = 'image/jpeg';
          else if (ext == 'png') mimeType = 'image/png';
          else if (ext == 'gif') mimeType = 'image/gif';
          else if (ext == 'webp') mimeType = 'image/webp';
          else mimeType = 'image/jpeg'; // Fallback
        }

        if (!filename.contains('.')) {
          if (mimeType == 'image/png') filename += '.png';
          else if (mimeType == 'image/gif') filename += '.gif';
          else if (mimeType == 'image/webp') filename += '.webp';
          else filename += '.jpg';
        }
        
        final typeSplit = mimeType.split('/');
        
        multipartImages.add(
          http.MultipartFile.fromBytes(
            'images',
            bytes,
            filename: filename,
            contentType: MediaType(
              typeSplit.isNotEmpty ? typeSplit[0] : 'image', 
              typeSplit.length > 1 ? typeSplit[1] : 'jpeg'
            ),
          ),
        );
      }

      await ApiService().createProperty(data, images: multipartImages);
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
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 400;
    final dialogPad = isSmall ? 16.0 : 28.0;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 40, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: EdgeInsets.all(dialogPad),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Add New Property',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: isSmall ? 18 : 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.navy,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                    ),
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration('Property Name'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _propertyType,
                    decoration: _inputDecoration('Property Type'),
                    items: const [
                      DropdownMenuItem(value: 'APARTMENT', child: Text('Apartment')),
                      DropdownMenuItem(value: 'HOTEL', child: Text('Hotel')),
                      DropdownMenuItem(value: 'AIRBNB', child: Text('Airbnb')),
                    ],
                    onChanged: (v) => setState(() => _propertyType = v!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    decoration: _inputDecoration('Address'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  if (isSmall) ...[
                    TextFormField(
                      controller: _cityController,
                      decoration: _inputDecoration('City'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _countryController,
                      decoration: _inputDecoration('Country'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ] else
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            decoration: _inputDecoration('City'),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _countryController,
                            decoration: _inputDecoration('Country'),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _totalUnitsController,
                    decoration: _inputDecoration('Total Units (Optional)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amenitiesController,
                    decoration: _inputDecoration('Amenities (comma separated)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: _inputDecoration('Description (Optional)'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Property Images',
                    style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.navy),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._selectedImages.map((file) => Chip(
                            label: Text(file.name, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                            onDeleted: () => setState(() => _selectedImages.remove(file)),
                          )),
                      ActionChip(
                        label: const Text('Add Images'),
                        avatar: const Icon(Icons.add_photo_alternate_outlined, size: 16),
                        onPressed: _pickImages,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('SAVE PROPERTY', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.teal, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }
}
