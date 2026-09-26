import 'unit_type_model.dart';
import 'property_model.dart';

class UnitModel {
  final dynamic id;
  final dynamic propertyId;
  final dynamic unitTypeId;
  final String unitNumber;
  final int floor;
  final int bedrooms;
  final int windowPanes;
  final int bulbs;
  final double rentPrice;
  final String status;
  final String description;
  final PropertyModel? property;
  final UnitTypeModel? unitType;

  const UnitModel({
    required this.id,
    required this.unitNumber,
    this.propertyId,
    this.unitTypeId,
    this.floor = 1,
    this.bedrooms = 1,
    this.windowPanes = 0,
    this.bulbs = 0,
    this.rentPrice = 0.0,
    this.status = 'VACANT',
    this.description = '',
    this.property,
    this.unitType,
  });

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      id: json['id'],
      propertyId: json['property_id'] ?? json['propertyId'],
      unitTypeId: json['unit_type_id'] ?? json['unitTypeId'],
      unitNumber: json['unit_number']?.toString() ?? json['unitNumber']?.toString() ?? 'Unit',
      floor: int.tryParse(json['floor']?.toString() ?? '') ?? 1,
      bedrooms: int.tryParse(json['bedrooms']?.toString() ?? '') ?? 1,
      windowPanes: int.tryParse(json['window_panes']?.toString() ?? json['windowPanes']?.toString() ?? '') ?? 0,
      bulbs: int.tryParse(json['bulbs']?.toString() ?? '') ?? 0,
      rentPrice: double.tryParse(json['rent_price']?.toString() ?? json['rentPrice']?.toString() ?? '') ?? 0.0,
      status: json['status']?.toString() ?? 'VACANT',
      description: json['description']?.toString() ?? '',
      property: json['property'] is Map ? PropertyModel.fromJson(Map<String, dynamic>.from(json['property'])) : null,
      unitType: json['unit_type'] is Map
          ? UnitTypeModel.fromJson(Map<String, dynamic>.from(json['unit_type']))
          : json['unitType'] is Map
              ? UnitTypeModel.fromJson(Map<String, dynamic>.from(json['unitType']))
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'property_id': propertyId,
      'unit_type_id': unitTypeId,
      'unit_number': unitNumber,
      'floor': floor,
      'bedrooms': bedrooms,
      'window_panes': windowPanes,
      'bulbs': bulbs,
      'rent_price': rentPrice,
      'status': status,
      'description': description,
    };
  }
}
