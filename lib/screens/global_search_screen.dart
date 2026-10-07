import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'property_details_screen.dart';
import 'unit_details_screen.dart';
import 'lease_details_screen.dart';

class GlobalSearchScreen extends StatefulWidget {
  final String initialQuery;

  const GlobalSearchScreen({super.key, this.initialQuery = ''});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  late TextEditingController _searchController;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  
  List<dynamic> _results = [];
  String _selectedScope = 'All';
  int _offset = 0;
  final int _limit = 20;

  final List<String> _categories = [
    'All',
    'Properties',
    'Units',
    'Tenants',
    'Leases',
    'Invoices',
    'Payments',
    'Maintenance',
    'Vendors',
    'Documents',
    'Inspections',
    'Notices'
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    
    // Filter categories based on role
    final role = AuthService().user?.role;
    if (role == 'TENANT') {
      _categories.remove('Tenants');
      _categories.remove('Vendors');
    }

    if (widget.initialQuery.isNotEmpty) {
      _performSearch(reset: true);
    }

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        _loadMore();
      }
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(reset: true);
    });
  }

  Future<void> _performSearch({bool reset = false}) async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _hasMore = false;
      });
      return;
    }

    if (reset) {
      setState(() {
        _offset = 0;
        _results = [];
        _isLoading = true;
        _hasMore = true;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final res = await ApiService().globalSearch(
        query,
        scope: _selectedScope,
        limit: _limit,
        offset: _offset,
      );
      
      final data = res['data'] as List<dynamic>? ?? [];
      
      if (mounted) {
        setState(() {
          if (reset) {
            _results = data;
          } else {
            _results.addAll(data);
          }
          
          if (data.length < _limit) {
            _hasMore = false; // Cursor pagination end
          } else {
            _offset += _limit;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Search failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _loadMore() {
    if (!_hasMore || _isLoading || _isLoadingMore) return;
    _performSearch(reset: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Global Search',
          style: GoogleFonts.bricolageGrotesque(color: AppTheme.navy, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.navy),
        actions: [
          // Advanced Filters Placeholder
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Advanced Filters',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Advanced filters & Operators coming soon!')),
              );
            },
          ),
          // Saved Searches Placeholder
          IconButton(
            icon: const Icon(Icons.bookmark_border_rounded),
            tooltip: 'Saved Searches',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saved searches coming soon!')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search anything (properties, tenants, documents...)',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0D9488)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedScope == category;
                      return ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedScope = category;
                            });
                            _performSearch(reset: true);
                          }
                        },
                        selectedColor: const Color(0xFF194635),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF475569),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        backgroundColor: const Color(0xFFF1F5F9),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Quick Actions Row (Placeholder)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF0D9488)),
                const SizedBox(width: 8),
                const Text('Quick Actions:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(width: 12),
                _buildQuickAction('Add Property'),
                const SizedBox(width: 8),
                _buildQuickAction('New Invoice'),
              ],
            ),
          ),
          const Divider(height: 1),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)))
                : _results.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _results.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _results.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator(color: Color(0xFF0D9488))),
                            );
                          }

                          final item = _results[index];
                          return _buildResultCard(item);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String label) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label action tapped')));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDFA),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFCCFBF1)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF0D9488))),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty ? 'Type to start searching' : 'No results found',
            style: const TextStyle(fontSize: 16, color: Color(0xFF64748B)),
          ),
          if (_searchController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your filters or search terms',
              style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
            ),
          ]
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'PROPERTY': return Icons.apartment_rounded;
      case 'UNIT': return Icons.meeting_room_rounded;
      case 'LEASE': return Icons.description_rounded;
      case 'TENANT': return Icons.person_rounded;
      case 'INVOICE': return Icons.receipt_rounded;
      case 'PAYMENT': return Icons.payments_rounded;
      case 'MAINTENANCE': return Icons.build_rounded;
      case 'VENDOR': return Icons.handyman_rounded;
      case 'DOCUMENT': return Icons.description_rounded;
      case 'INSPECTION': return Icons.fact_check_rounded;
      case 'NOTICE': return Icons.notifications_rounded;
      default: return Icons.insert_drive_file_rounded;
    }
  }

  Widget _buildResultCard(Map<String, dynamic> item) {
    final title = item['title'] ?? 'Unknown';
    final subtitle = item['subtitle'] ?? '';
    final type = item['type'] ?? 'OTHER';
    final icon = _getIconForType(type);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          final payload = item['payload'] as Map<String, dynamic>? ?? {};
          if (type == 'PROPERTY') {
            Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: payload)));
          } else if (type == 'UNIT') {
            Navigator.push(context, MaterialPageRoute(builder: (_) => UnitDetailsScreen(unit: payload)));
          } else if (type == 'LEASE') {
            Navigator.push(context, MaterialPageRoute(builder: (_) => LeaseDetailsScreen(lease: payload)));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Details for $type coming soon')));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF194635), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            type,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF94A3B8),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
