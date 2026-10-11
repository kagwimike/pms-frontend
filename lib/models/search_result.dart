class SearchResult {
  final int id;
  final String type;
  final String title;
  final String? subtitle;
  final String? status;
  final String? icon;
  final Map<String, dynamic>? context;
  final Map<String, dynamic>? payload;
  final Map<String, dynamic> rawData;

  SearchResult({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.status,
    this.icon,
    this.context,
    this.payload,
    required this.rawData,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      id: json['id'],
      type: json['type'],
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      status: json['status'],
      icon: json['icon'],
      context: json['context'] as Map<String, dynamic>?,
      payload: json['payload'] as Map<String, dynamic>?,
      rawData: json,
    );
  }

  Map<String, dynamic> toJson() {
    return rawData;
  }
}
