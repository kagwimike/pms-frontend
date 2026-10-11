import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/search_result.dart';
import '../services/api_service.dart';

enum SearchState { idle, loading, results, empty, error }

class SearchProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  
  SearchProvider() {
    _loadRecentSearches();
  }

  SearchState _state = SearchState.idle;
  SearchState get state => _state;

  String _query = '';
  String get query => _query;

  String? _error;
  String? get error => _error;

  Map<String, List<SearchResult>> _results = {};
  Map<String, List<SearchResult>> get results => _results;

  Timer? _debounce;
  
  // Specific category search state for full search page
  String? _selectedCategory;
  String? get selectedCategory => _selectedCategory;
  
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;
  
  String? _nextCursor;
  bool get hasMore => _nextCursor != null;

  List<String> _recentSearches = [];
  List<String> get recentSearches => _recentSearches;

  List<SearchResult> _recentRecords = [];
  List<SearchResult> get recentRecords => _recentRecords;

  static const String _recentSearchesKey = 'recent_searches_key';
  static const String _recentRecordsKey = 'recent_records_key';

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_recentSearchesKey) ?? [];
    _recentSearches = list.where((e) => e != null && e.toString().trim().length > 0).cast<String>().toList();
    
    final recordsList = prefs.getStringList(_recentRecordsKey) ?? [];
    try {
      _recentRecords = recordsList.map((e) => SearchResult.fromJson(jsonDecode(e))).toList();
    } catch (e) {
      _recentRecords = [];
    }
    
    notifyListeners();
  }

  Future<void> saveRecentRecord(SearchResult record) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Remove if already exists to put it at the top
    _recentRecords.removeWhere((e) => e.id == record.id && e.type == record.type);
    
    _recentRecords.insert(0, record);
    if (_recentRecords.length > 5) {
      _recentRecords = _recentRecords.sublist(0, 5);
    }
    
    final encodedList = _recentRecords.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_recentRecordsKey, encodedList);
    notifyListeners();
  }

  Future<void> _saveSearch(String query) async {
    if (query.trim().length < 2) return;
    
    final prefs = await SharedPreferences.getInstance();
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
    
    if (_recentSearches.length > 5) {
      _recentSearches = _recentSearches.sublist(0, 5);
    }
    
    await prefs.setStringList(_recentSearchesKey, _recentSearches);
    notifyListeners();
  }

  Future<void> clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
    _recentSearches = [];
    notifyListeners();
  }

  Future<void> removeRecentSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    _recentSearches.remove(query);
    await prefs.setStringList(_recentSearchesKey, _recentSearches);
    notifyListeners();
  }

  void reset() {
    _query = '';
    _selectedCategory = null;
    _state = SearchState.idle;
    _results = {};
    _nextCursor = null;
    _error = null;
    _debounce?.cancel();
    notifyListeners();
  }

  void setQuery(String value) {
    if (_query == value) return;
    _query = value;
    
    if (_query.length < 2) {
      _state = SearchState.idle;
      _results = {};
      _nextCursor = null;
      _error = null;
      _debounce?.cancel();
      notifyListeners();
      return;
    }

    _state = SearchState.loading;
    _error = null;
    notifyListeners();

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
  }

  void selectCategory(String? category) {
    _selectedCategory = category;
    _nextCursor = null;
    _results = {};
    if (_query.length >= 2) {
      _state = SearchState.loading;
      notifyListeners();
      _performSearch();
    } else {
      notifyListeners();
    }
  }

  Future<void> _performSearch() async {
    try {
      final response = await _api.globalSearch(_query, type: _selectedCategory, limit: _selectedCategory == null ? 3 : 20);
      final data = response['data']?['results'] as Map<String, dynamic>?;
      
      _results = {};
      int totalResults = 0;
      
      if (data != null) {
        data.forEach((key, value) {
          if (value is List && (value as List).length > 0) {
            _results[key] = value.map((e) => SearchResult.fromJson(e)).toList();
            totalResults += _results[key]!.length;
          }
        });
      }

      _nextCursor = response['meta']?['nextCursor'];
      _state = totalResults > 0 ? SearchState.results : SearchState.empty;
      _error = null;
      if (_state == SearchState.results) {
        _saveSearch(_query);
      }
    } catch (e) {
      _state = SearchState.error;
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore || _selectedCategory == null) return;
    
    _isLoadingMore = true;
    notifyListeners();

    try {
      final response = await _api.globalSearch(_query, type: _selectedCategory, limit: 20, cursor: _nextCursor);
      final data = response['data']?['results'] as Map<String, dynamic>?;
      
      if (data != null && data.containsKey(_selectedCategory)) {
        final newItems = (data[_selectedCategory] as List).map((e) => SearchResult.fromJson(e)).toList();
        _results[_selectedCategory!]!.addAll(newItems);
      }
      
      _nextCursor = response['meta']?['nextCursor'];
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
