import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../ui/widgets/responsive_helper.dart';

class DocumentsScreen extends StatefulWidget {
  final bool isOwner;
  const DocumentsScreen({super.key, required this.isOwner});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _documents = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await _apiService.getDocuments();
      setState(() {
        _documents = ApiService.extractList(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showAddDocumentDialog() {
    ResponsiveHelper.showResponsiveDialog(
      context: context,
      builder: (context) => const AddDocumentDialog(),
    ).then((val) {
      if (val == true) _loadDocuments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Documents', style: GoogleFonts.inter(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: _showAddDocumentDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Upload Document'),
              style: AppTheme.actionButtonStyle,
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
              : _documents.isEmpty
                  ? const Center(child: Text('No documents uploaded.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _documents.length,
                      itemBuilder: (context, index) {
                        final doc = _documents[index];
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.teal.withValues(alpha: 0.1),
                              child: const Icon(Icons.description, color: AppTheme.teal),
                            ),
                            title: Text(doc['name'] ?? 'Document', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Type: ${doc['document_type']} | Exp: ${doc['expiry_date'] ?? 'N/A'}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.download, color: AppTheme.teal),
                              onPressed: () {
                                // In a real app, you would download or view it.
                                // We can just print for now or use url_launcher.
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading file...')));
                              },
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

class AddDocumentDialog extends StatefulWidget {
  const AddDocumentDialog({super.key});

  @override
  State<AddDocumentDialog> createState() => _AddDocumentDialogState();
}

class _AddDocumentDialogState extends State<AddDocumentDialog> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  final _nameCtrl = TextEditingController();
  String _docType = 'LEASE_AGREEMENT';
  XFile? _selectedFile;
  bool _isSubmitting = false;

  Future<void> _pickFile() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedFile = image;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields and select a file.')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final bytes = await _selectedFile!.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'file', 
        bytes, 
        filename: _selectedFile!.name,
      );

      await _apiService.createDocument({
        'name': _nameCtrl.text,
        'document_type': _docType,
      }, file: multipartFile);
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload document. Please check your connection.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 400;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isSmall ? const BorderRadius.vertical(top: Radius.circular(20)) : BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmall ? 16.0 : 28.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Flexible(child: Text('Upload Document', style: GoogleFonts.bricolageGrotesque(fontSize: isSmall ? 18 : 22, fontWeight: FontWeight.w700, color: AppTheme.navy))),
                IconButton(icon: const Icon(Icons.close), onPressed: _isSubmitting ? null : () => Navigator.pop(context)),
              ]),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Document Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                      enabled: !_isSubmitting,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _docType,
                      decoration: InputDecoration(
                        labelText: 'Document Type',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'LEASE_AGREEMENT', child: Text('Lease Agreement')),
                        DropdownMenuItem(value: 'ID_COPY', child: Text('ID Copy')),
                        DropdownMenuItem(value: 'INSPECTION_REPORT', child: Text('Inspection Report')),
                        DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                      ],
                      onChanged: _isSubmitting ? null : (v) => setState(() => _docType = v!),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : _pickFile,
                        icon: const Icon(Icons.attach_file),
                        label: Text(_selectedFile == null ? 'Select File' : _selectedFile!.name),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.teal, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('UPLOAD DOCUMENT', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
