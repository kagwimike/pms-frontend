class PropertyModel {
  final dynamic id;
  final String name;
  final String slug;
  final String propertyType;
  final String status;
  final String address;
  final String city;
  final String country;
  final int totalUnits;
  final String description;
  final List<String> images;

  const PropertyModel({
    required this.id,
    required this.name,
    this.slug = '',
    this.propertyType = '',
    this.status = '',
    this.address = '',
    this.city = '',
    this.country = '',
    this.totalUnits = 0,
    this.description = '',
    this.images = const [],
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    return PropertyModel(
      id: json['id'],
      name: json['name']?.toString() ?? 'Unnamed property',
      slug: json['slug']?.toString() ?? '',
      propertyType:
          json['property_type']?.toString() ??
          json['propertyType']?.toString() ??
          '',
      status: json['status']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      totalUnits: _toInt(json['total_units'] ?? json['totalUnits']),
      description: json['description']?.toString() ?? '',
      images: rawImages is List
          ? rawImages.map((image) => image.toString()).toList()
          : const [],
    );
  }

  static int _toInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '') ?? 0;
}
