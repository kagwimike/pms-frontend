class UnitTypeModel {
  final dynamic id;
  final String name;
  final String code;
  final String description;
  final double baseRent;

  const UnitTypeModel({
    required this.id,
    required this.name,
    this.code = '',
    this.description = '',
    this.baseRent = 0.0,
  });

  factory UnitTypeModel.fromJson(Map<String, dynamic> json) {
    return UnitTypeModel(
      id: json['id'],
      name: json['name']?.toString() ?? 'Unnamed Unit Type',
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      baseRent: double.tryParse(json['base_rent']?.toString() ?? json['baseRent']?.toString() ?? '') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'description': description,
      'base_rent': baseRent,
    };
  }
}
