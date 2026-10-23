import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../ui/widgets/responsive_helper.dart';

class DocumentsScreen extends StatefulWidget {
  final bool isOwner;
  const DocumentsScreen({super.key, this.isOwner = true});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  List<dynamic> _documents = [];
  String? _nextCursor;

  String _selectedCategory = 'ALL';
  String _selectedStatus = 'ALL';

  final List<String> _categories = [
    'ALL',
    'LEASE_AGREEMENT',
    'ID_COPY',
    'INSPECTION_REPORT',
    'RECEIPT',
    'INSURANCE',
    'PERMIT',
    'WORK_ORDER',
    'OTHER',
  ];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments({bool loadMore = false}) async {
    if (loadMore) {
      if (_nextCursor == null || _isLoadingMore) return;
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final response = await _apiService.getDocuments(
        limit: 15,
        cursor: loadMore ? _nextCursor : null,
        docType: _selectedCategory == 'ALL' ? null : _selectedCategory,
        status: _selectedStatus == 'ALL' ? null : _selectedStatus,
        search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      );

      final newItems = ApiService.extractList(response);
      final meta = response['meta'] as Map<String, dynamic>?;
      final cursor = meta?['nextCursor']?.toString();

      setState(() {
        if (loadMore) {
          _documents.addAll(newItems);
        } else {
          _documents = newItems;
        }
        _nextCursor = cursor;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
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

  void _showNewVersionDialog(Map<String, dynamic> doc) {
    ResponsiveHelper.showResponsiveDialog(
      context: context,
      builder: (context) => UploadNewVersionDialog(parentDoc: doc),
    ).then((val) {
      if (val == true) _loadDocuments();
    });
  }

  void _showDetailsDialog(Map<String, dynamic> doc) {
    showDialog(
      context: context,
      builder: (context) => _DocumentDetailsDialog(
        documentId: doc['id'].toString(),
        initialDoc: doc,
        onRefreshNeeded: () => _loadDocuments(),
      ),
    );
  }

  Future<void> _openFile(dynamic docId, {bool preview = false}) async {
    final url = _apiService.getDocumentDownloadUrl(docId, preview: preview);
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Cannot launch URL';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open document: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _archiveDocument(dynamic docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive Document'),
        content: const Text('Are you sure you want to archive this document? It will be hidden from the active list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _apiService.deleteDocument(docId, permanent: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document archived successfully'), backgroundColor: Colors.green),
        );
      }
      _loadDocuments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to archive: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatFileSize(dynamic bytes) {
    if (bytes == null) return '0 B';
    final size = num.tryParse(bytes.toString()) ?? 0;
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _getFileIcon(String? mimeType, String? title) {
    final mime = (mimeType ?? '').toLowerCase();
    final ext = (title ?? '').toLowerCase();
    if (mime.contains('pdf') || ext.endsWith('.pdf')) return Icons.picture_as_pdf_outlined;
    if (mime.contains('image') || ext.endsWith('.jpg') || ext.endsWith('.png')) return Icons.image_outlined;
    if (mime.contains('word') || ext.endsWith('.doc') || ext.endsWith('.docx')) return Icons.article_outlined;
    if (mime.contains('sheet') || mime.contains('excel') || ext.endsWith('.xls') || ext.endsWith('.csv')) {
      return Icons.table_chart_outlined;
    }
    return Icons.description_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Documents', style: GoogleFonts.bricolageGrotesque(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 20)),
            Text('Centralized leases, reports, permits, and KYC records', style: GoogleFonts.dmSans(fontSize: 12, color: Colors.grey)),
          ],
        ),
        backgroundColor: cardBg,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _loadDocuments(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: _showAddDocumentDialog,
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: const Text('Upload Document'),
              style: AppTheme.actionButtonStyle,
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            color: cardBg,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search documents by title or file name...',
                          hintStyle: const TextStyle(fontSize: 13),
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    _loadDocuments();
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                          fillColor: isDark ? const Color(0xFF262626) : Colors.grey.shade50,
                          filled: true,
                        ),
                        onSubmitted: (_) => _loadDocuments(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _loadDocuments(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Search'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Category Filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF262626) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            isDense: true,
                            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text('Category: ${c.replaceAll('_', ' ')}', style: const TextStyle(fontSize: 12)))).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedCategory = val);
                                _loadDocuments();
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status Filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF262626) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStatus,
                            isDense: true,
                            items: ['ALL', 'APPROVED', 'FINALIZED', 'PENDING', 'ARCHIVED'].map((s) => DropdownMenuItem(value: s, child: Text('Status: $s', style: const TextStyle(fontSize: 12)))).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedStatus = val);
                                _loadDocuments();
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Main document list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.teal))
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                              const SizedBox(height: 12),
                              Text('Error loading documents: $_error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => _loadDocuments(),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Try Again'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _documents.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.folder_open_rounded, size: 56, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text('No documents found', style: GoogleFonts.bricolageGrotesque(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                                const SizedBox(height: 4),
                                const Text('Upload your first document or change the active filters.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: AppTheme.teal,
                            onRefresh: () => _loadDocuments(),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _documents.length + (_nextCursor != null ? 1 : 0),
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                if (index == _documents.length) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                                      child: _isLoadingMore
                                          ? const CircularProgressIndicator(color: AppTheme.teal)
                                          : OutlinedButton(
                                              onPressed: () => _loadDocuments(loadMore: true),
                                              child: const Text('Load More Documents'),
                                            ),
                                    ),
                                  );
                                }

                                final doc = _documents[index] as Map<String, dynamic>;
                                final docId = doc['id'];
                                final title = doc['title'] ?? doc['name'] ?? 'Untitled Document';
                                final docType = doc['document_type'] ?? 'GENERAL';
                                final entityType = doc['entity_type'] ?? 'GENERAL';
                                final entityId = doc['entity_id'];
                                final version = doc['version'] ?? 1;
                                final isFinalized = doc['is_finalized'] == true;
                                final fileSize = _formatFileSize(doc['file_size']);
                                final mime = doc['mime_type']?.toString();
                                final uploader = (doc['uploaded_by'] as Map<String, dynamic>?)?['username'] ?? 'Staff';
                                final expiryDate = doc['expiry_date']?.toString();
                                final createdAt = doc['created_at'] != null ? DateTime.tryParse(doc['created_at']) : null;
                                final dateStr = createdAt != null ? DateFormat('MMM dd, yyyy').format(createdAt.toLocal()) : '';

                                return Card(
                                  elevation: 0,
                                  color: cardBg,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: borderColor),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            CircleAvatar(
                                              radius: 22,
                                              backgroundColor: AppTheme.teal.withValues(alpha: 0.12),
                                              child: Icon(_getFileIcon(mime, title), color: AppTheme.teal, size: 22),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          title,
                                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                        ),
                                                      ),
                                                      // Version Badge
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: Colors.blue.withValues(alpha: 0.12),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text('v$version', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11)),
                                                      ),
                                                      if (isFinalized) ...[
                                                        const SizedBox(width: 6),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: Colors.green.withValues(alpha: 0.12),
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: const Text('FINALIZED', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${docType.replaceAll('_', ' ')}  •  $entityType${entityId != null ? ' #$entityId' : ''}  •  $fileSize',
                                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        const Divider(height: 1),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Text(
                                              'Uploaded by $uploader • $dateStr',
                                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                            ),
                                            if (expiryDate != null) ...[
                                              const SizedBox(width: 12),
                                              Icon(Icons.event_outlined, size: 14, color: Colors.amber.shade800),
                                              const SizedBox(width: 4),
                                              Text('Expires: $expiryDate', style: TextStyle(fontSize: 11, color: Colors.amber.shade800, fontWeight: FontWeight.w600)),
                                            ],
                                            const Spacer(),
                                            // Preview button
                                            IconButton(
                                              tooltip: 'Preview',
                                              icon: const Icon(Icons.visibility_outlined, size: 19, color: AppTheme.teal),
                                              onPressed: () => _openFile(docId, preview: true),
                                            ),
                                            // Download button
                                            IconButton(
                                              tooltip: 'Download',
                                              icon: const Icon(Icons.download_outlined, size: 19, color: AppTheme.teal),
                                              onPressed: () => _openFile(docId, preview: false),
                                            ),
                                            // Action menu
                                            PopupMenuButton<String>(
                                              icon: const Icon(Icons.more_vert, size: 19, color: Colors.grey),
                                              onSelected: (val) {
                                                switch (val) {
                                                  case 'details':
                                                    _showDetailsDialog(doc);
                                                    break;
                                                  case 'new_version':
                                                    _showNewVersionDialog(doc);
                                                    break;
                                                  case 'archive':
                                                    _archiveDocument(docId);
                                                    break;
                                                }
                                              },
                                              itemBuilder: (ctx) => [
                                                const PopupMenuItem(value: 'details', child: Text('Details & Versions')),
                                                if (!isFinalized) const PopupMenuItem(value: 'new_version', child: Text('Upload New Version')),
                                                const PopupMenuItem(value: 'archive', child: Text('Archive Document', style: TextStyle(color: Colors.red))),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
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

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _entityIdCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();

  String _docType = 'LEASE_AGREEMENT';
  String _entityType = 'GENERAL';
  final String _accessScope = 'ORGANIZATION';
  XFile? _selectedFile;
  bool _isSubmitting = false;

  final List<String> _docTypes = [
    'LEASE_AGREEMENT',
    'ID_COPY',
    'INSPECTION_REPORT',
    'RECEIPT',
    'INSURANCE',
    'PERMIT',
    'WORK_ORDER',
    'OTHER',
  ];

  final List<String> _entityTypes = [
    'GENERAL',
    'LEASE',
    'PROPERTY',
    'UNIT',
    'TENANT',
    'INSPECTION',
    'MAINTENANCE',
    'FINANCE',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _entityIdCtrl.dispose();
    _expiryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        _selectedFile = file;
        if (_titleCtrl.text.isEmpty) {
          _titleCtrl.text = file.name.split('.').first.replaceAll('_', ' ');
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file and fill all required fields.')),
      );
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

      final payload = <String, dynamic>{
        'title': _titleCtrl.text.trim(),
        'document_type': _docType,
        'entity_type': _entityType,
        'access_scope': _accessScope,
      };

      if (_entityIdCtrl.text.trim().isNotEmpty) {
        payload['entity_id'] = _entityIdCtrl.text.trim();
      }
      if (_descCtrl.text.trim().isNotEmpty) {
        payload['description'] = _descCtrl.text.trim();
      }
      if (_expiryCtrl.text.trim().isNotEmpty) {
        payload['expiry_date'] = _expiryCtrl.text.trim();
      }

      await _apiService.createDocument(payload, file: multipartFile);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload document: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Upload New Document', style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navy)),
                    IconButton(icon: const Icon(Icons.close), onPressed: _isSubmitting ? null : () => Navigator.pop(context)),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(labelText: 'Document Title *', border: OutlineInputBorder()),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        enabled: !_isSubmitting,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _docType,
                              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                              items: _docTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' '), style: const TextStyle(fontSize: 12)))).toList(),
                              onChanged: _isSubmitting ? null : (v) => setState(() => _docType = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _entityType,
                              decoration: const InputDecoration(labelText: 'Linked Module', border: OutlineInputBorder()),
                              items: _entityTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12)))).toList(),
                              onChanged: _isSubmitting ? null : (v) => setState(() => _entityType = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _entityIdCtrl,
                              decoration: const InputDecoration(labelText: 'Resource ID (Optional)', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                              enabled: !_isSubmitting,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _expiryCtrl,
                              decoration: const InputDecoration(labelText: 'Expiry Date (YYYY-MM-DD)', border: OutlineInputBorder()),
                              enabled: !_isSubmitting,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _descCtrl,
                        decoration: const InputDecoration(labelText: 'Description / Notes', border: OutlineInputBorder()),
                        maxLines: 2,
                        enabled: !_isSubmitting,
                      ),
                      const SizedBox(height: 16),
                      // File picker trigger
                      OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : _pickFile,
                        icon: const Icon(Icons.attach_file),
                        label: Text(_selectedFile == null ? 'Select Document File' : 'Selected: ${_selectedFile!.name}'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.teal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('UPLOAD AND SAVE', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UploadNewVersionDialog extends StatefulWidget {
  final Map<String, dynamic> parentDoc;
  const UploadNewVersionDialog({super.key, required this.parentDoc});

  @override
  State<UploadNewVersionDialog> createState() => _UploadNewVersionDialogState();
}

class _UploadNewVersionDialogState extends State<UploadNewVersionDialog> {
  final ApiService _apiService = ApiService();
  final _descCtrl = TextEditingController();
  XFile? _selectedFile;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _selectedFile = file);
  }

  Future<void> _submit() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a file for the new version.')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final bytes = await _selectedFile!.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes('file', bytes, filename: _selectedFile!.name);

      await _apiService.uploadDocumentVersion(
        widget.parentDoc['id'],
        {'description': _descCtrl.text.trim()},
        file: multipartFile,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New version uploaded successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload new version: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentVer = widget.parentDoc['version'] ?? 1;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Upload New Version', style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Upgrading "${widget.parentDoc['title']}" from v$currentVer to v${currentVer + 1}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Version change notes (optional)', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _pickFile,
                icon: const Icon(Icons.attach_file),
                label: Text(_selectedFile == null ? 'Select New File' : 'Selected: ${_selectedFile!.name}'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.teal, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 48)),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('UPLOAD VERSION ${currentVer + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentDetailsDialog extends StatefulWidget {
  final String documentId;
  final Map<String, dynamic> initialDoc;
  final VoidCallback onRefreshNeeded;

  const _DocumentDetailsDialog({
    required this.documentId,
    required this.initialDoc,
    required this.onRefreshNeeded,
  });

  @override
  State<_DocumentDetailsDialog> createState() => _DocumentDetailsDialogState();
}

class _DocumentDetailsDialogState extends State<_DocumentDetailsDialog> {
  final ApiService _apiService = ApiService();
  late Map<String, dynamic> _doc;

  @override
  void initState() {
    super.initState();
    _doc = widget.initialDoc;
    _fetchFullDetails();
  }

  Future<void> _fetchFullDetails() async {
    try {
      final res = await _apiService.getDocument(widget.documentId);
      final data = ApiService.extractMap(res);
      if (mounted) setState(() { _doc = data; });
    } catch (_) {}
  }

  Future<void> _finalizeDocument() async {
    try {
      await _apiService.updateDocument(_doc['id'], {'is_finalized': true, 'status': 'FINALIZED'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document finalized. Overwrites are locked.'), backgroundColor: Colors.green));
        Navigator.pop(context);
        widget.onRefreshNeeded();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final versions = (_doc['versions'] as List<dynamic>?) ?? [];
    final isFinalized = _doc['is_finalized'] == true;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(_doc['title'] ?? 'Document Details', style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _row('Document ID', '#${_doc['id']}'),
                      _row('Current Version', 'v${_doc['version'] ?? 1}'),
                      _row('Category', '${_doc['document_type']}'),
                      _row('Linked Entity', '${_doc['entity_type']} ${_doc['entity_id'] != null ? '#${_doc['entity_id']}' : ''}'),
                      _row('MIME Type', '${_doc['mime_type'] ?? 'Unknown'}'),
                      _row('File Size', '${_doc['file_size'] ?? 0} bytes'),
                      if (_doc['checksum'] != null) _row('SHA-256 Checksum', '${_doc['checksum']}'),
                      _row('Access Scope', '${_doc['access_scope'] ?? 'ORGANIZATION'}'),
                      _row('Finalized Status', isFinalized ? 'FINALIZED (Immutable)' : 'Active (Replacements Allowed)'),
                      if (_doc['description'] != null) _row('Description', '${_doc['description']}'),
                      const SizedBox(height: 16),
                      Text('Version History (${versions.length + 1} records):', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      // Current root version
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(radius: 14, backgroundColor: AppTheme.teal, child: Text('v1', style: TextStyle(color: Colors.white, fontSize: 11))),
                        title: Text('Root version • ${_doc['original_name'] ?? 'File'}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: Text('Uploaded on ${_doc['created_at']?.toString().split('T').first ?? ''}', style: const TextStyle(fontSize: 11)),
                      ),
                      // Child versions
                      ...versions.map((v) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(radius: 14, backgroundColor: Colors.blue.shade700, child: Text('v${v['version']}', style: const TextStyle(color: Colors.white, fontSize: 11))),
                        title: Text('Version ${v['version']} • ${v['original_name'] ?? 'File'}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: Text(v['description'] ?? 'Uploaded on ${v['created_at']?.toString().split('T').first ?? ''}', style: const TextStyle(fontSize: 11)),
                      )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!isFinalized)
                    OutlinedButton.icon(
                      onPressed: _finalizeDocument,
                      icon: const Icon(Icons.lock_outline, size: 16),
                      label: const Text('Finalize Document'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.green.shade700),
                    )
                  else
                    const SizedBox(),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.teal, foregroundColor: Colors.white),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
