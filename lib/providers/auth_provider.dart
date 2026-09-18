import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/storage/token_storage.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  AuthProvider() {
    loadSession();
  }

  Future<void> loadSession() async {
    _isLoading = true;
    notifyListeners();
    try {
      final userDataStr = await TokenStorage.getUserData();
      final accessToken = await TokenStorage.getAccessToken();
      if (userDataStr != null && accessToken != null) {
        _user = UserModel.fromRawJson(userDataStr);
      }
    } catch (e) {
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiClient.post(
      ApiEndpoints.login,
      {
        'email': email,
        'password': password,
      },
      withAuth: false,
    );

    if (response.success && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      final access = data['access'] as String;
      final refresh = data['refresh'] as String;
      final userObj = UserModel.fromJson(data['user']);

      await TokenStorage.saveTokens(access: access, refresh: refresh);
      await TokenStorage.saveUserData(userObj.toRawJson());

      _user = userObj;
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String username,
    required String password,
    String role = 'OWNER',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiClient.post(
      ApiEndpoints.register,
      {
        'email': email,
        'username': username,
        'password': password,
        'role': role,
      },
      withAuth: false,
    );

    if (response.success && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      final access = data['access'] as String;
      final refresh = data['refresh'] as String;
      final userObj = UserModel.fromJson(data['user']);

      await TokenStorage.saveTokens(access: access, refresh: refresh);
      await TokenStorage.saveUserData(userObj.toRawJson());

      _user = userObj;
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> googleSignIn() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;

      if (idToken == null) {
        _errorMessage = "Failed to obtain Google ID Token";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await ApiClient.post(
        ApiEndpoints.googleAuth,
        {
          'token': idToken,
        },
        withAuth: false,
      );

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final access = data['access'] as String;
        final refresh = data['refresh'] as String;
        final userObj = UserModel.fromJson(data['user']);

        await TokenStorage.saveTokens(access: access, refresh: refresh);
        await TokenStorage.saveUserData(userObj.toRawJson());

        _user = userObj;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = "Google Sign In error: $e";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await TokenStorage.clearAll();
    _user = null;
    notifyListeners();
  }
}

