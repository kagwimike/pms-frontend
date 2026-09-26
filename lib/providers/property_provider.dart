import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

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

  Future<bool> createProperty({
    required Map<String, dynamic> fields,
    List<XFile> images = const [],
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final response = await ApiClient.postMultipart(
      ApiEndpoints.properties,
      fields: fields,
      images: images,
    );
    _isLoading = false;
    if (!response.success) {
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }
    await loadProperties(refresh: true);
    return true;
  }

  Future<bool> updateProperty(dynamic id, Map<String, dynamic> fields) async {
    _errorMessage = null;
    notifyListeners();
    final response = await ApiClient.put(
      '${ApiEndpoints.properties}/$id',
      fields,
    );
    if (!response.success) {
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }
    await loadProperties(refresh: true);
    return true;
  }

  Future<bool> deleteProperty(dynamic id) async {
    _errorMessage = null;
    notifyListeners();
    final response = await ApiClient.delete('${ApiEndpoints.properties}/$id');
    if (!response.success) {
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }
    _properties.removeWhere((property) => property.id.toString() == id.toString());
    notifyListeners();
    return true;
  }

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
