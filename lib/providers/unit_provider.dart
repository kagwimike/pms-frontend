import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/unit_model.dart';
import '../models/unit_type_model.dart';

class UnitProvider with ChangeNotifier {
  final List<UnitModel> _units = [];
  final List<UnitTypeModel> _unitTypes = [];
  bool _isLoading = false;
  bool _isLoadingUnitTypes = false;
  String? _errorMessage;
  String? _unitTypeErrorMessage;

  List<UnitModel> get units => List.unmodifiable(_units);
  List<UnitTypeModel> get unitTypes => List.unmodifiable(_unitTypes);
  bool get isLoading => _isLoading;
  bool get isLoadingUnitTypes => _isLoadingUnitTypes;
  String? get errorMessage => _errorMessage;
  String? get unitTypeErrorMessage => _unitTypeErrorMessage;

  // ==================== UNITS CRUD ====================

  Future<void> loadUnits({dynamic propertyId, bool refresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    if (refresh) _units.clear();
    notifyListeners();

    final queryParams = <String, dynamic>{'limit': 100};
    if (propertyId != null) {
      queryParams['property'] = propertyId.toString();
    }

    final response = await ApiClient.get(
      ApiEndpoints.units,
      queryParameters: queryParams,
    );

    if (response.success) {
      _units.clear();
      final data = response.data;
      if (data is List) {
        _units.addAll(
          data.whereType<Map>().map(
            (item) => UnitModel.fromJson(Map<String, dynamic>.from(item)),
          ),
        );
      } else if (data is Map && data['rows'] is List) {
        _units.addAll(
          (data['rows'] as List).whereType<Map>().map(
            (item) => UnitModel.fromJson(Map<String, dynamic>.from(item)),
          ),
        );
      }
    } else {
      _errorMessage = response.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createUnit(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiClient.post(ApiEndpoints.units, data);
    _isLoading = false;

    if (!response.success) {
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }

    await loadUnits(refresh: true);
    return true;
  }

  Future<bool> updateUnit(dynamic id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiClient.put('${ApiEndpoints.units}/$id', data);
    _isLoading = false;

    if (!response.success) {
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }

    await loadUnits(refresh: true);
    return true;
  }

  Future<bool> deleteUnit(dynamic id) async {
    _errorMessage = null;
    notifyListeners();

    final response = await ApiClient.delete('${ApiEndpoints.units}/$id');
    if (!response.success) {
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }

    _units.removeWhere((unit) => unit.id.toString() == id.toString());
    notifyListeners();
    return true;
  }

  // ==================== UNIT TYPES CRUD ====================

  Future<void> loadUnitTypes({bool refresh = false}) async {
    if (_isLoadingUnitTypes) return;
    _isLoadingUnitTypes = true;
    _unitTypeErrorMessage = null;
    if (refresh) _unitTypes.clear();
    notifyListeners();

    final response = await ApiClient.get(
      ApiEndpoints.unitTypes,
      queryParameters: {'limit': 100},
    );

    if (response.success) {
      _unitTypes.clear();
      final data = response.data;
      if (data is List) {
        _unitTypes.addAll(
          data.whereType<Map>().map(
            (item) => UnitTypeModel.fromJson(Map<String, dynamic>.from(item)),
          ),
        );
      } else if (data is Map && data['rows'] is List) {
        _unitTypes.addAll(
          (data['rows'] as List).whereType<Map>().map(
            (item) => UnitTypeModel.fromJson(Map<String, dynamic>.from(item)),
          ),
        );
      }
    } else {
      _unitTypeErrorMessage = response.message;
    }

    _isLoadingUnitTypes = false;
    notifyListeners();
  }

  Future<bool> createUnitType(Map<String, dynamic> data) async {
    _isLoadingUnitTypes = true;
    _unitTypeErrorMessage = null;
    notifyListeners();

    final response = await ApiClient.post(ApiEndpoints.unitTypes, data);
    _isLoadingUnitTypes = false;

    if (!response.success) {
      _unitTypeErrorMessage = response.message;
      notifyListeners();
      return false;
    }

    await loadUnitTypes(refresh: true);
    return true;
  }

  Future<bool> updateUnitType(dynamic id, Map<String, dynamic> data) async {
    _isLoadingUnitTypes = true;
    _unitTypeErrorMessage = null;
    notifyListeners();

    final response = await ApiClient.put('${ApiEndpoints.unitTypes}/$id', data);
    _isLoadingUnitTypes = false;

    if (!response.success) {
      _unitTypeErrorMessage = response.message;
      notifyListeners();
      return false;
    }

    await loadUnitTypes(refresh: true);
    return true;
  }

  Future<bool> deleteUnitType(dynamic id) async {
    _unitTypeErrorMessage = null;
    notifyListeners();

    final response = await ApiClient.delete('${ApiEndpoints.unitTypes}/$id');
    if (!response.success) {
      _unitTypeErrorMessage = response.message;
      notifyListeners();
      return false;
    }

    _unitTypes.removeWhere((type) => type.id.toString() == id.toString());
    notifyListeners();
    return true;
  }
}
