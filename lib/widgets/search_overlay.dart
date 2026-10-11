import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/search_provider.dart';
import '../models/search_result.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../screens/search_results_screen.dart';
import '../screens/property_details_screen.dart';
import '../screens/unit_details_screen.dart';
import '../screens/lease_details_screen.dart';
import '../screens/maintenance_screen.dart';
import '../screens/tenants_screen.dart';
import '../screens/documents_screen.dart';
class SearchOverlay extends StatefulWidget {
  const SearchOverlay({super.key});

  @override
  State<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  int _selectedIndex = -1;
  final List<SearchResult> _flatResults = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchProvider>().reset();
    });
    _searchCtrl.addListener(() {
      context.read<SearchProvider>().setQuery(_searchCtrl.text);
      if (mounted) {
        setState(() {
          _selectedIndex = -1;
        });
      }
    });

    _searchFocusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          setState(() {
            if (_selectedIndex < _flatResults.length - 1) {
              _selectedIndex++;
            }
          });
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          setState(() {
            if (_selectedIndex > 0) {
              _selectedIndex--;
            }
          });
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.enter) {
          if (_selectedIndex >= 0 && _selectedIndex < _flatResults.length) {
            Navigator.pop(context);
            _navigateToDetail(_flatResults[_selectedIndex]);
            return KeyEventResult.handled;
          } else if (_searchCtrl.text.isNotEmpty) {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => SearchResultsScreen(query: _searchCtrl.text)));
            return KeyEventResult.handled;
          }
        }
      }
      return KeyEventResult.ignored;
    };
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final selectedCat = provider.selectedCategory;

    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: kToolbarHeight + 16, left: 16, right: 16, bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    if (selectedCat != null)
                      IconButton(
                        icon: const Icon(Icons.arrow_back, size: 20),
                        onPressed: () => provider.selectCategory(null),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                    else
                      const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        focusNode: _searchFocusNode,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: selectedCat != null ? 'Search ${selectedCat.toUpperCase()}...' : 'Search tenants, units, maintenance...',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: GoogleFonts.dmSans(fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () {
                        provider.selectCategory(null);
                        provider.setQuery('');
                        Navigator.pop(context);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              
              // Search Body
              Flexible(
                child: Consumer<SearchProvider>(
                  builder: (context, provider, child) {
                    if (provider.state == SearchState.idle) {
                      return _buildIdleState(provider);
                    }
                    if (provider.state == SearchState.loading) {
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        shrinkWrap: true,
                        itemCount: 4,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(width: double.infinity, height: 16, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
                                    const SizedBox(height: 8),
                                    Container(width: 150, height: 12, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    }
                    if (provider.state == SearchState.error) {
                      return Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(child: Text(provider.error ?? 'Error searching')),
                      );
                    }
                    if (provider.state == SearchState.empty) {
                      return _buildEmptyState();
                    }

                    _flatResults.clear();
                    for (var entry in provider.results.entries) {
                      _flatResults.addAll(entry.value.take(3));
                    }
                    if (_selectedIndex >= _flatResults.length && _flatResults.isNotEmpty) {
                      _selectedIndex = _flatResults.length - 1;
                    }

                    return _buildResultsState(provider);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdleState(SearchProvider provider) {
    if (provider.selectedCategory != null) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('Search in ${provider.selectedCategory!.toUpperCase()}', style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
              const SizedBox(height: 8),
              Text('Start typing to find records.', style: GoogleFonts.dmSans(color: Colors.grey.shade500)),
            ],
          ),
        ),
      );
    }

    final List<Map<String, dynamic>> searchCategories = [
      {'title': 'People', 'id': 'PEOPLE', 'icon': Icons.people_rounded},
      {'title': 'Property', 'id': 'PROPERTY', 'icon': Icons.apartment_rounded},
      {'title': 'Finance', 'id': 'LEASE & FINANCE', 'icon': Icons.payments_rounded},
      {'title': 'Operations', 'id': 'OPERATIONS', 'icon': Icons.build_rounded},
      {'title': 'Comms', 'id': 'COMMUNICATION', 'icon': Icons.forum_rounded},
      {'title': 'Docs', 'id': 'DOCUMENTS', 'icon': Icons.description_rounded},
    ];

    return Flexible(
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        shrinkWrap: true,
        children: [
          if (provider.recentRecords.isNotEmpty) ...[
            Text('Recently Viewed', style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.navy)),
            const SizedBox(height: 8),
            ...provider.recentRecords.map((item) => _buildResultItem(item, false)),
            const SizedBox(height: 24),
          ],
          if ((provider.recentSearches as dynamic) != null && (provider.recentSearches as dynamic).length > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Searches', style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.navy)),
                TextButton(
                  onPressed: () => provider.clearRecentSearches(),
                  child: Text('Clear', style: GoogleFonts.dmSans(fontSize: 12)),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: provider.recentSearches.map((query) => InputChip(
                label: Text(query, style: GoogleFonts.dmSans(color: AppTheme.navy)),
                backgroundColor: Colors.grey.shade100,
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => provider.removeRecentSearch(query),
                onPressed: () {
                  _searchCtrl.text = query;
                  _searchCtrl.selection = TextSelection.collapsed(offset: query.length);
                  provider.setQuery(query);
                },
              )).toList(),
            ),
            const SizedBox(height: 24),
          ],
          Text('Search Categories', style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.navy)),
          const SizedBox(height: 12),
          ...searchCategories.map((cat) => ListTile(
            leading: Icon(cat['icon'] as IconData, color: AppTheme.teal),
            title: Text(cat['title'] as String, style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: AppTheme.navy)),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            contentPadding: EdgeInsets.zero,
            onTap: () {
              provider.selectCategory(cat['id'] as String);
            },
          )),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No results found', style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Try checking spelling or using a different term.', style: GoogleFonts.dmSans(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsState(SearchProvider provider) {
    int currentIndex = 0;
    return ListView(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      children: [
        ...provider.results.entries.map((entry) {
          final category = entry.key;
          final items = entry.value.take(3).toList();
          
          final categoryWidgets = <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 16),
              child: Text(category.toUpperCase(), style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey.shade500)),
            ),
          ];

          for (var item in items) {
            final isSelected = currentIndex == _selectedIndex;
            categoryWidgets.add(_buildResultItem(item, isSelected));
            currentIndex++;
          }

          if (entry.value.length > 3) {
            categoryWidgets.add(TextButton(
              onPressed: () {
                Navigator.pop(context); // Close overlay
                Navigator.push(context, MaterialPageRoute(builder: (_) => SearchResultsScreen(query: _searchCtrl.text, initialCategory: category)));
              },
              child: Text('View all $category results →'),
            ));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: categoryWidgets,
          );
        }),
        const Divider(height: 32),
        Center(
          child: TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => SearchResultsScreen(query: _searchCtrl.text)));
            },
            child: const Text('View all results'),
          ),
        )
      ],
    );
  }

  Widget _buildResultItem(SearchResult item, bool isSelected) {
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

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.grey.shade100 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppTheme.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AppTheme.teal, size: 20),
        ),
        title: Text(item.title, style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
        subtitle: item.subtitle != null ? Text(item.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
        onTap: () {
          Navigator.pop(context);
          _navigateToDetail(item);
        },
      ),
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

      final id = item.id;
      switch (item.type) {
        case 'PROPERTY':
          final res = await api.getProperty(id);
          Navigator.pop(context);
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
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load details: $e')));
    }
  }
}
