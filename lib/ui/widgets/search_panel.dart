import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../screens/property_details_screen.dart';
import '../../screens/unit_details_screen.dart';
import '../../screens/lease_details_screen.dart';
import '../../screens/global_search_screen.dart';

class SearchPanelDialog extends StatefulWidget {
  const SearchPanelDialog({super.key});

  @override
  State<SearchPanelDialog> createState() => _SearchPanelDialogState();
}

class _SearchPanelDialogState extends State<SearchPanelDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  bool _isLoading = false;
  List<dynamic> _results = [];
  String _selectedScope = 'All';
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _focusNode.requestFocus();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  Future<void> _saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList('recent_searches') ?? [];
    searches.remove(query); // Remove if exists to move to top
    searches.insert(0, query);
    if (searches.length > 5) {
      searches.removeLast();
    }
    await prefs.setStringList('recent_searches', searches);
    setState(() {
      _recentSearches = searches;
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final res = await ApiService().globalSearch(query, scope: _selectedScope);
        if (mounted) {
          setState(() {
            _results = res['data'] ?? [];
            _isLoading = false;
          });
          _saveRecentSearch(query);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Search failed: $e')));
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 80, left: 16, right: 16, bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 24,
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search Input Area
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'Search tenants, properties, leases...',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 18),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0D9488), size: 28),
                        border: InputBorder.none,
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  });
                                },
                              )
                            : null,
                      ),
                      style: const TextStyle(fontSize: 18, color: Color(0xFF1E293B)),
                      onChanged: (val) {
                        setState(() {});
                        _onSearchChanged(val);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Search Content Area
            Expanded(
              child: _searchController.text.isEmpty
                  ? _buildInitialView()
                  : _buildSearchResults(_searchController.text),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Search in:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip('All'),
            _buildFilterChip('Properties'),
            _buildFilterChip('Units'),
            _buildFilterChip('Tenants'),
            _buildFilterChip('Leases'),
            _buildFilterChip('Invoices'),
            _buildFilterChip('Payments'),
            _buildFilterChip('Maintenance'),
            _buildFilterChip('Vendors'),
            _buildFilterChip('Documents'),
            _buildFilterChip('Inspections'),
          ],
        ),
        const SizedBox(height: 32),
        if (_recentSearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent searches',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('recent_searches');
                  setState(() {
                    _recentSearches = [];
                  });
                },
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Clear', style: TextStyle(fontSize: 12, color: Color(0xFF0D9488))),
              )
            ],
          ),
          const SizedBox(height: 8),
          ..._recentSearches.map((text) => _buildRecentItem(text, Icons.history)),
        ],
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedScope == label;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedScope = label;
          if (_searchController.text.isNotEmpty) {
            _onSearchChanged(_searchController.text);
          }
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF194635) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF194635) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF475569),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentItem(String text, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
      title: Text(
        text,
        style: const TextStyle(color: Color(0xFF334155), fontSize: 14),
      ),
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: EdgeInsets.zero,
      onTap: () {
        setState(() {
          _searchController.text = text;
        });
        _onSearchChanged(text);
      },
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'PROPERTY':
        return Icons.apartment_rounded;
      case 'UNIT':
        return Icons.meeting_room_rounded;
      case 'LEASE':
        return Icons.description_rounded;
      case 'TENANT':
        return Icons.person_rounded;
      case 'INVOICE':
        return Icons.receipt_rounded;
      case 'PAYMENT':
        return Icons.payments_rounded;
      case 'MAINTENANCE':
        return Icons.build_rounded;
      case 'VENDOR':
        return Icons.handyman_rounded;
      case 'DOCUMENT':
        return Icons.description_rounded;
      case 'INSPECTION':
        return Icons.fact_check_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Widget _buildSearchResults(String query) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)));
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            Text(
              'No results found for "$query"',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Group results by type
    final grouped = <String, List<dynamic>>{};
    for (var r in _results) {
      final t = r['type'] ?? 'OTHER';
      grouped.putIfAbsent(t, () => []).add(r);
    }

    final children = <Widget>[];
    grouped.forEach((type, items) {
      children.add(_buildCategoryHeader(type + 'S', items.length));
      for (var item in items) {
        children.add(_buildResultCard(
          title: item['title'] ?? 'Unknown',
          subtitle: item['subtitle'] ?? '',
          icon: _getIconForType(item['type']),
          tag: item['type'] ?? 'OTHER',
          item: item,
        ));
      }
    });

    children.add(
      Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: TextButton(
          onPressed: () {
            Navigator.pop(context);
            // Navigate to the full search screen
            Navigator.push(context, MaterialPageRoute(builder: (_) => GlobalSearchScreen(initialQuery: query)));
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.all(16),
            backgroundColor: const Color(0xFFF1F5F9),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('View all results', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF194635))),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: 18, color: Color(0xFF194635)),
            ],
          ),
        ),
      ),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: children,
    );
  }

  Widget _buildCategoryHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 1.0,
            ),
          ),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String tag,
    required Map<String, dynamic> item,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pop(context); // Close the dialog
            final payload = item['payload'] as Map<String, dynamic>? ?? {};
            
            if (item['type'] == 'PROPERTY') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: payload)));
            } else if (item['type'] == 'UNIT') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => UnitDetailsScreen(unit: payload)));
            } else if (item['type'] == 'LEASE') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => LeaseDetailsScreen(lease: payload)));
            }
            // Add other navigation logic here if you have screens for TENANT
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
                          Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF94A3B8),
                              letterSpacing: 0.5,
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
      ),
    );
  }
}
