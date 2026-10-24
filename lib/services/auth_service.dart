import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config.dart';
import '../widgets/google_auth/web_wrapper.dart' as gsi;

class UserModel {
  final int id;
  final String username;
  final String email;
  final String role;
  final String? firstName;
  final String? lastName;
  final String? profilePicture;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.firstName,
    this.lastName,
    this.profilePicture,
  });

  String get displayName {
    if (firstName != null && firstName!.isNotEmpty) {
      if (lastName != null && lastName!.isNotEmpty) {
        return '$firstName $lastName';
      }
      return firstName!;
    }
    return username;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'GUEST',
      firstName: json['first_name'] ?? json['firstName'],
      lastName: json['last_name'] ?? json['lastName'],
      profilePicture: json['profile_picture'] ?? json['profilePicture'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'role': role,
        'first_name': firstName,
        'last_name': lastName,
        'profile_picture': profilePicture,
      };
}

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserModel? _user;
  String? _accessToken;
  String? _refreshToken;
  bool _isLoading = false;
  String? _error;

  static const String _kRememberMe = 'auth_remember_me';
  static const String _kRememberedEmail = 'auth_remembered_email';

  UserModel? get user => _user;
  String? get accessToken => _accessToken;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null && _accessToken != null;
  String? get error => _error;

  /// Get saved "Remember Me" preference
  Future<bool> getRememberMePreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kRememberMe) ?? false;
  }

  /// Get remembered email address
  Future<String?> getRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRememberedEmail);
  }

  /// Persist or clear remember me preference and email
  Future<void> saveRememberMe({required bool rememberMe, String? email}) async {
    final prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await prefs.setBool(_kRememberMe, true);
      if (email != null && email.trim().isNotEmpty) {
        await prefs.setString(_kRememberedEmail, email.trim());
      }
    } else {
      await prefs.setBool(_kRememberMe, false);
      await prefs.remove(_kRememberedEmail);
    }
  }

  /// Register a new user
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String role,
    String? phone,
    String? firstName,
    String? lastName,
    String? tenantIdPassport,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'username': username,
        'email': email,
        'password': password,
        'role': role,
      };
      if (phone != null && phone.isNotEmpty) body['phone'] = phone;
      if (firstName != null && firstName.isNotEmpty) body['first_name'] = firstName;
      if (lastName != null && lastName.isNotEmpty) body['last_name'] = lastName;
      if (tenantIdPassport != null && tenantIdPassport.isNotEmpty) {
        body['tenant_id_passport'] = tenantIdPassport;
      }

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        _accessToken = data['data']['access'];
        _refreshToken = data['data']['refresh'];
        _user = UserModel.fromJson(data['data']['user']);
        await _persistSession();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = data['message'] ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Connection error. Please check that the server is running.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Login with email and password
  Future<bool> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _accessToken = data['data']['access'];
        _refreshToken = data['data']['refresh'];
        _user = UserModel.fromJson(data['data']['user']);
        await _persistSession(rememberMe: rememberMe);
        await saveRememberMe(rememberMe: rememberMe, email: email);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = data['message'] ?? 'Invalid credentials';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Connection error. Please check that the server is running.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  bool _googleInitialized = false;
  String? _pendingRole;

  /// Set the preferred role for Google Fast-Track registration
  void setPendingRole(String? role) {
    _pendingRole = role;
  }

  /// Initialize Google Sign-In and register stream listener
  Future<void> initGoogleSignIn() async {
    if (_googleInitialized) return;
    try {
      gsi.ensureGoogleSignInWebPlugin();
      await GoogleSignIn.instance.initialize(
        clientId: AppConfig.googleClientId,
      );
      _googleInitialized = true;

      // Listen to incoming sign-in events from Google Identity Services
      GoogleSignIn.instance.authenticationEvents.listen(
        (event) async {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            final idToken = event.user.authentication.idToken;
            if (idToken != null && idToken.isNotEmpty) {
              await loginWithGoogleToken(idToken, role: _pendingRole);
            }
          }
        },
        onError: (err) {
          debugPrint('Google Sign-In stream error: $err');
          _error = 'Google Sign-In error: $err';
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Google Sign-In init error: $e');
    }
  }

  /// Exchange Google ID token or dev token with backend
  Future<bool> loginWithGoogleToken(String idToken, {String? role}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final targetRole = role ?? _pendingRole;
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': idToken,
          if (targetRole != null && targetRole.isNotEmpty) 'role': targetRole,
        }),
      );

      final data = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && data['success'] == true) {
        _accessToken = data['data']['access'];
        _refreshToken = data['data']['refresh'];
        _user = UserModel.fromJson(data['data']['user']);
        await _persistSession();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = data['message'] ?? 'Google authentication failed on server.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Connection error communicating with PMS Pro server: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in with Google (Cross-platform)
  Future<bool> signInWithGoogle({String? devToken, String? role}) async {
    if (role != null) _pendingRole = role;

    if (devToken != null && devToken.isNotEmpty) {
      return await loginWithGoogleToken(devToken, role: role);
    }

    await initGoogleSignIn();

    if (GoogleSignIn.instance.supportsAuthenticate()) {
      _isLoading = true;
      _error = null;
      notifyListeners();

      try {
        final account = await GoogleSignIn.instance.authenticate();
        final idToken = account.authentication.idToken;
        if (idToken != null && idToken.isNotEmpty) {
          return await loginWithGoogleToken(idToken, role: role);
        } else {
          _error = 'Could not obtain Google authentication token.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } catch (googleErr) {
        debugPrint('Google Sign-In authenticate error: $googleErr');
        _error = 'Google Sign-In was cancelled or failed: $googleErr';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } else {
      // On Web: GIS does not allow custom button clicks to call authenticate() directly.
      // We attempt lightweight / OneTap authentication
      try {
        final future = GoogleSignIn.instance.attemptLightweightAuthentication();
        if (future != null) {
          final account = await future;
          if (account != null) {
            final idToken = account.authentication.idToken;
            if (idToken != null && idToken.isNotEmpty) {
              return await loginWithGoogleToken(idToken, role: role);
            }
          }
        }
      } catch (e) {
        debugPrint('Google lightweight auth error: $e');
      }

      // If GIS button is needed on web, report the helpful instruction
      _error = 'Please click the Google button to sign in.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    if (_accessToken != null) {
      try {
        await http.post(
          Uri.parse('${AppConfig.apiBaseUrl}/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_accessToken',
          },
          body: jsonEncode({
            if (_refreshToken != null) 'refresh': _refreshToken,
          }),
        );
      } catch (e) {
        debugPrint('Error notifying backend of logout: $e');
      }
    }

    _user = null;
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_json');

    // If "Remember Me" was disabled, clean up remembered credentials
    final rememberMe = prefs.getBool(_kRememberMe) ?? false;
    if (!rememberMe) {
      await prefs.remove(_kRememberedEmail);
      await prefs.remove(_kRememberMe);
    }
    notifyListeners();
  }

  /// Restore session from SharedPreferences
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final userJson = prefs.getString('user_json');

    if (token != null && userJson != null) {
      _accessToken = token;
      _refreshToken = prefs.getString('refresh_token');
      _user = UserModel.fromJson(jsonDecode(userJson));
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> _persistSession({bool rememberMe = true}) async {
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) await prefs.setString('access_token', _accessToken!);
    if (_refreshToken != null) await prefs.setString('refresh_token', _refreshToken!);
    if (_user != null) await prefs.setString('user_json', jsonEncode(_user!.toJson()));
    await prefs.setBool(_kRememberMe, rememberMe);
  }
}
