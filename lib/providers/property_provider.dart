import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/property_model.dart';

class PropertyProvider with ChangeNotifier {
  final List<PropertyModel> _properties = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _nextCursor;

  List<PropertyModel> get properties => List.unmodifiable(_properties);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _nextCursor != null && _nextCursor!.isNotEmpty;
  String? get errorMessage => _errorMessage;

  Future<void> loadProperties({bool refresh = false}) async {
    if (_isLoading || _isLoadingMore) return;
    if (refresh) {
      _nextCursor = null;
      _properties.clear();
    }

    final loadingMore = _properties.isNotEmpty && !refresh;
    if (loadingMore) {
      _isLoadingMore = true;
    } else {
      _isLoading = true;
    }
    _errorMessage = null;
    notifyListeners();

    final response = await ApiClient.get(
      ApiEndpoints.properties,
      queryParameters: {
        'limit': 20,
        if (_nextCursor != null) 'cursor': _nextCursor,
      },
    );

    if (response.success) {
      final data = response.data;
      if (data is List) {
        _properties.addAll(
          data.whereType<Map>().map(
            (item) => PropertyModel.fromJson(Map<String, dynamic>.from(item)),
          ),
        );
      }
      _nextCursor = response.meta?['nextCursor']?.toString();
    } else {
      _errorMessage = response.message;
    }

    _isLoading = false;
    _isLoadingMore = false;
    notifyListeners();
  }
}
