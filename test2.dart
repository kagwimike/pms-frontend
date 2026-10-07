void main() { dynamic data = {'data': 'foo'}; List<dynamic> records = data is List ? data : (data['data'] ?? []); print(records); }
