import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/search_provider.dart';
import '../models/search_result.dart';
import '../theme/app_theme.dart';
import 'property_details_screen.dart';
import 'unit_details_screen.dart';
import 'lease_details_screen.dart';
import 'maintenance_screen.dart';
import 'tenants_screen.dart';
import 'documents_screen.dart';
class SearchResultsScreen extends StatefulWidget {
  final String query;
  final String? initialCategory;

  const SearchResultsScreen({super.key, required this.query, this.initialCategory});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late SearchProvider _provider;
  final ScrollController _scrollCtrl = ScrollController();
  String? _statusFilter;
  String? _propertyFilter;
  String? _dateRangeFilter;

  @override
  void initState() {
    super.initState();
    _provider = context.read<SearchProvider>();
    // Need to defer this slightly to avoid setting state during build if opened immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.setQuery(widget.query);
      if (widget.initialCategory != null) {
        _provider.selectCategory(widget.initialCategory);
      }
    });

    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
        _provider.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Search Results', style: GoogleFonts.bricolageGrotesque(color: AppTheme.navy, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.navy),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: _buildSearchBar(),
          ),
        ),
      ),
      body: Consumer<SearchProvider>(
        builder: (context, provider, child) {
          if (provider.state == SearchState.loading && provider.results.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.state == SearchState.error && provider.results.isEmpty) {
            return Center(child: Text(provider.error ?? 'Error occurred'));
          }
          if (provider.state == SearchState.empty || (provider.results.isEmpty && provider.state == SearchState.idle)) {
            return const Center(child: Text('No results found.'));
          }

          final categories = ['All', ...provider.results.keys];
          
          return Column(
            children: [
              // Category Tabs
              Container(
                height: 50,
                color: Colors.white,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  itemBuilder: (ctx, idx) {
                    final cat = categories[idx];
                    final isSelected = (cat == 'All' && provider.selectedCategory == null) || (cat == provider.selectedCategory);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0, top: 8, bottom: 8),
                      child: ChoiceChip(
                        label: Text(cat.toUpperCase(), style: TextStyle(color: isSelected ? Colors.white : AppTheme.navy)),
                        selected: isSelected,
                        selectedColor: AppTheme.teal,
                        onSelected: (sel) {
                          if (sel) {
                            setState(() {
                              _statusFilter = null;
                              _propertyFilter = null;
                              _dateRangeFilter = null;
                            });
                            provider.selectCategory(cat == 'All' ? null : cat);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              
              if (provider.selectedCategory != null && provider.results[provider.selectedCategory] != null) ...[
                _buildDynamicFiltersRow(provider.results[provider.selectedCategory]!),
                const Divider(height: 1),
              ],

              Expanded(
                child: ListView(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (provider.selectedCategory == null)
                      ...provider.results.entries.map((e) => _buildCategorySection(e.key, e.value))
                    else if (provider.results.containsKey(provider.selectedCategory))
                      _buildCategorySection(provider.selectedCategory!, provider.results[provider.selectedCategory!]!),
                    
                    if (provider.isLoadingMore)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: TextEditingController(text: _provider.query)..selection = TextSelection.collapsed(offset: _provider.query.length),
      onChanged: (v) => _provider.setQuery(v),
      decoration: InputDecoration(
        hintText: 'Search...',
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
      ),
    );
  }

  Widget _buildCategorySection(String category, List<SearchResult> items) {
    var filteredItems = items;
    if (_statusFilter != null) {
      filteredItems = filteredItems.where((item) => item.status?.toUpperCase() == _statusFilter?.toUpperCase()).toList();
    }
    
    if (_propertyFilter != null) {
      filteredItems = filteredItems.where((item) {
        if (item.rawData.containsKey('propertyName') && item.rawData['propertyName'] != null) {
          return item.rawData['propertyName'].toString() == _propertyFilter;
        }
        return false;
      }).toList();
    }

    if (_dateRangeFilter != null) {
      final now = DateTime.now();
      DateTime threshold;
      switch (_dateRangeFilter) {
        case '7_DAYS': threshold = now.subtract(const Duration(days: 7)); break;
        case '30_DAYS': threshold = now.subtract(const Duration(days: 30)); break;
        case '6_MONTHS': threshold = now.subtract(const Duration(days: 180)); break;
        default: threshold = DateTime.fromMillisecondsSinceEpoch(0);
      }
      
      filteredItems = filteredItems.where((item) {
        if (item.rawData.containsKey('date') && item.rawData['date'] != null) {
          final itemDate = DateTime.tryParse(item.rawData['date'].toString());
          if (itemDate != null) {
            return itemDate.isAfter(threshold);
          }
        }
        return true; // Keep items with no date instead of hiding them aggressively, or hide them? Better to keep them if they can't be filtered, or hide them? Let's hide them if user explicitly wants recent things.
      }).toList();
    }

    if (filteredItems.isEmpty) return const SizedBox();
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(category.toUpperCase(), style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.navy)),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredItems.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, idx) => _buildResultItem(filteredItems[idx]),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicFiltersRow(List<SearchResult> items) {
    // Extract unique statuses
    final statuses = items.map((e) => e.status?.toUpperCase()).where((e) => e != null).toSet().cast<String>().toList();
    
    // Extract unique properties
    final properties = items.map((e) {
      if (e.rawData.containsKey('propertyName') && e.rawData['propertyName'] != null) {
        return e.rawData['propertyName'].toString();
      }
      return null;
    }).where((e) => e != null).toSet().cast<String>().toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade50,
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(Icons.filter_list, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text('Filters: ', style: GoogleFonts.dmSans(color: Colors.grey.shade700, fontSize: 12)),
            const SizedBox(width: 16),
            
            if (statuses.isNotEmpty) ...[
              DropdownButton<String>(
                value: _statusFilter,
                hint: Text('Status (All)', style: GoogleFonts.dmSans(fontSize: 12)),
                isDense: true,
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem(value: null, child: Text('Status (All)', style: GoogleFonts.dmSans(fontSize: 12))),
                  ...statuses.map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.dmSans(fontSize: 12)))),
                ],
                onChanged: (val) {
                  setState(() => _statusFilter = val);
                },
              ),
              const SizedBox(width: 16),
            ],

            if (properties.isNotEmpty) ...[
              DropdownButton<String>(
                value: _propertyFilter,
                hint: Text('Property (All)', style: GoogleFonts.dmSans(fontSize: 12)),
                isDense: true,
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem(value: null, child: Text('Property (All)', style: GoogleFonts.dmSans(fontSize: 12))),
                  ...properties.map((p) => DropdownMenuItem(value: p, child: Text(p, style: GoogleFonts.dmSans(fontSize: 12)))),
                ],
                onChanged: (val) {
                  setState(() => _propertyFilter = val);
                },
              ),
              const SizedBox(width: 16),
            ],
            
            DropdownButton<String>(
              value: _dateRangeFilter,
              hint: Text('Date (All Time)', style: GoogleFonts.dmSans(fontSize: 12)),
              isDense: true,
              underline: const SizedBox(),
              items: [
                DropdownMenuItem(value: null, child: Text('Date (All Time)', style: GoogleFonts.dmSans(fontSize: 12))),
                DropdownMenuItem(value: '7_DAYS', child: Text('Last 7 Days', style: GoogleFonts.dmSans(fontSize: 12))),
                DropdownMenuItem(value: '30_DAYS', child: Text('Last 30 Days', style: GoogleFonts.dmSans(fontSize: 12))),
                DropdownMenuItem(value: '6_MONTHS', child: Text('Last 6 Months', style: GoogleFonts.dmSans(fontSize: 12))),
              ],
              onChanged: (val) {
                setState(() => _dateRangeFilter = val);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(SearchResult item) {
    IconData icon = Icons.circle;
    switch(item.icon) {
      case 'person_rounded': icon = Icons.person_rounded; break;
      case 'apartment_rounded': icon = Icons.apartment_rounded; break;
      case 'meeting_room_rounded': icon = Icons.meeting_room_rounded; break;
      case 'build_rounded': icon = Icons.build_rounded; break;
      case 'handyman_rounded': icon = Icons.handyman_rounded; break;
      case 'description_rounded': icon = Icons.description_rounded; break;
      case 'receipt_rounded': icon = Icons.receipt_rounded; break;
      case 'payments_rounded': icon = Icons.payments_rounded; break;
      case 'fact_check_rounded': icon = Icons.fact_check_rounded; break;
      case 'notifications_rounded': icon = Icons.notifications_rounded; break;
      case 'forum_rounded': icon = Icons.forum_rounded; break;
    }

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppTheme.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: AppTheme.teal, size: 24),
      ),
      title: Text(item.title, style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
      subtitle: item.subtitle != null ? Text(item.subtitle!) : null,
      trailing: item.status != null ? _buildStatusChip(item.status!) : const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        _navigateToDetail(item);
      },
    );
  }

  Future<void> _navigateToDetail(SearchResult item) async {
    context.read<SearchProvider>().saveRecentRecord(item);
    final api = ApiService();
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // item.id is already an int
      final id = item.id;

      switch (item.type) {
        case 'PROPERTY':
          final res = await api.getProperty(id);
          Navigator.pop(context); // close loader
          Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: res['data'] ?? res)));
          break;
        case 'UNIT':
          final res = await api.getUnit(id);
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => UnitDetailsScreen(unit: res['data'] ?? res)));
          break;
        case 'LEASE':
        case 'FINANCE':
          final res = await api.getLease(id);
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => LeaseDetailsScreen(lease: res['data'] ?? res)));
          break;
        case 'OPERATIONS':
          Navigator.pop(context);
          // Assuming MaintenanceScreen doesn't take a specific object yet, or if it does, we pass it.
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MaintenanceScreen()));
          break;
        case 'PEOPLE':
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TenantsScreen()));
          break;
        case 'DOCUMENTS':
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentsScreen(isOwner: false)));
          break;
        default:
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selected ${item.title}')));
      }
    } catch (e) {
      Navigator.pop(context); // close loader
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load details: $e')));
    }
  }

  Widget _buildStatusChip(String status) {
    Color color = Colors.grey;
    if (status.toUpperCase() == 'ACTIVE' || status.toUpperCase() == 'COMPLETED') color = Colors.green;
    if (status.toUpperCase() == 'PENDING') color = Colors.orange;
    if (status.toUpperCase() == 'IN_PROGRESS') color = Colors.blue;
    if (status.toUpperCase() == 'CANCELLED' || status.toUpperCase() == 'UNPAID') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
