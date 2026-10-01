class AppError implements Exception {
  final String message;
  final int? statusCode;

  AppError(this.message, {this.statusCode});

  @override
  String toString() => 'AppError: $message ${statusCode != null ? '($statusCode)' : ''}';
}
