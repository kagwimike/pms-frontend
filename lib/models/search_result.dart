class SearchResult {
  final int id;
  final String type;
  final String title;
  final String? subtitle;
  final String? status;
  final String? icon;
  final Map<String, dynamic>? context;
  final Map<String, dynamic>? payload;

  SearchResult({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.status,
    this.icon,
    this.context,
    this.payload,
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
    );
  }
}
