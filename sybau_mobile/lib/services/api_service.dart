import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.body});

  final String message;
  final int? statusCode;
  final String? body;

  @override
  String toString() {
    final status = statusCode == null ? '' : ' ($statusCode)';
    final responseBody = body == null || body!.isEmpty ? '' : ': $body';
    return '$message$status$responseBody';
  }
}

class ApiService {
  static const String _autoBaseUrlKey = 'server.autoBaseUrl';
  static const String _savedBaseUrlKey = 'server.baseUrl';
  static const String _tokenKey = 'auth.token';
  static const String _userKey = 'auth.user';
  static const String _legacyTokenKey = 'token';
  static const String _legacyUserKey = 'user';
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );
  static const String _apiHostOverride = String.fromEnvironment('API_HOST');
  static const String _liveBaseUrl = 'https://sybau-xll5.onrender.com';
  static const String _defaultPort = '5243';
  static const Duration _healthTimeout = Duration(milliseconds: 900);
  static const Duration _discoveryHealthTimeout = Duration(milliseconds: 250);
  static const Duration _requestTimeout = Duration(seconds: 8);
  static const List<String> _developmentHostnames = <String>[
    'Air-von-David.local',
    'Air-von-David.telekom.ip',
    'MacBook-Air-von-David.local',
    'sybau.local',
    'sybau-backend.local',
  ];
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static String? _resolvedBaseUrl;
  static Future<void>? _initializeFuture;
  static String? _cachedToken;
  static String? _cachedUserJson;

  static Future<void> initialize() async {
    _initializeFuture ??= _resolveHealthyBaseUrl();
    await _initializeFuture;
  }

  static Future<void> _ensureInitialized() async {
    if (_resolvedBaseUrl != null && _resolvedBaseUrl!.isNotEmpty) return;
    await initialize();
  }

  static Future<void> _resolveHealthyBaseUrl({String? exclude}) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_autoBaseUrlKey)?.trim();
    final legacyManual = prefs.getString(_savedBaseUrlKey)?.trim();

    final canUseLocalDiscovery = _apiHostOverride.isNotEmpty;
    final discovered = canUseLocalDiscovery
        ? await _discoverLocalBackend(exclude: exclude)
        : null;
    if (discovered != null) {
      await _setResolvedBaseUrl(discovered, prefs);
      return;
    }

    for (final candidate in _baseUrlCandidates(
      cached: cached,
      legacyManual: legacyManual,
    )) {
      if (candidate == exclude) continue;
      if (await _isHealthy(candidate)) {
        await _setResolvedBaseUrl(candidate, prefs);
        return;
      }
    }

    _resolvedBaseUrl = defaultBaseUrl;
    debugPrint('SYBAU API fallback baseUrl: $_resolvedBaseUrl');
  }

  static Future<void> _setResolvedBaseUrl(
    String candidate,
    SharedPreferences prefs,
  ) async {
    _resolvedBaseUrl = candidate;
    debugPrint('SYBAU API resolved baseUrl: $_resolvedBaseUrl');
    await prefs.setString(_autoBaseUrlKey, candidate);
    await prefs.remove(_savedBaseUrlKey);
  }

  static void _cacheSessionString(String key, String? value) {
    if (key == _tokenKey) {
      _cachedToken = value;
    } else if (key == _userKey) {
      _cachedUserJson = value;
    }
  }

  static String? _cachedSessionString(String key) {
    if (key == _tokenKey) return _cachedToken;
    if (key == _userKey) return _cachedUserJson;
    return null;
  }

  static Future<String?> _readSessionString(
    String key,
    String legacyKey,
  ) async {
    final cached = _cachedSessionString(key);
    if (cached != null && cached.isNotEmpty) return cached;

    try {
      final secureValue = await _secureStorage.read(key: key);
      if (secureValue != null && secureValue.isNotEmpty) {
        _cacheSessionString(key, secureValue);
        return secureValue;
      }
    } catch (_) {
      // Secure storage is unavailable in some test/desktop contexts. Fall back to legacy storage there.
    }

    final prefs = await SharedPreferences.getInstance();
    final legacyValue = prefs.getString(legacyKey);
    if (legacyValue == null || legacyValue.isEmpty) return null;

    try {
      await _secureStorage.write(key: key, value: legacyValue);
      await prefs.remove(legacyKey);
    } catch (_) {
      // Keep legacy value if migration could not complete.
    }
    _cacheSessionString(key, legacyValue);
    return legacyValue;
  }

  static Future<void> _writeSessionString(
    String key,
    String legacyKey,
    String value,
  ) async {
    _cacheSessionString(key, value);
    final prefs = await SharedPreferences.getInstance();
    try {
      await _secureStorage.write(key: key, value: value);
      await prefs.remove(legacyKey);
    } catch (_) {
      await prefs.setString(legacyKey, value);
    }
  }

  static Future<void> _deleteSessionString(String key, String legacyKey) async {
    _cacheSessionString(key, null);
    try {
      await _secureStorage.delete(key: key);
    } catch (_) {
      // Ignore unavailable secure storage in test/desktop contexts.
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(legacyKey);
  }

  static String get baseUrl {
    if (_resolvedBaseUrl != null && _resolvedBaseUrl!.isNotEmpty) {
      return _resolvedBaseUrl!;
    }

    return defaultBaseUrl;
  }

  static String get defaultBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _normalizeBaseUrl(_apiBaseUrlOverride);
    }

    if (_apiHostOverride.isNotEmpty) {
      return _normalizeBaseUrl(_apiHostOverride, appendDefaultPort: true);
    }

    return _liveBaseUrl;
  }

  static String _normalizeBaseUrl(
    String input, {
    bool appendDefaultPort = false,
  }) {
    final trimmedInput = input.trim().replaceFirst(RegExp(r'/+$'), '');
    final normalizedInput = trimmedInput.contains('://')
        ? trimmedInput
        : 'http://$trimmedInput';
    final uri = Uri.tryParse(normalizedInput);
    if (uri == null || uri.host.isEmpty) return normalizedInput;
    final path = uri.path == '/'
        ? ''
        : uri.path.replaceFirst(RegExp(r'/+$'), '');
    if (uri.hasPort) {
      return '${uri.scheme}://${uri.host}:${uri.port}$path';
    }
    final port = appendDefaultPort ? ':$_defaultPort' : '';
    return '${uri.scheme}://${uri.host}$port$path';
  }

  static List<String> _baseUrlCandidates({
    String? cached,
    String? legacyManual,
  }) {
    final candidates = <String>[];

    void add(String? value, {bool appendDefaultPort = false}) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isEmpty) return;
      final normalized = _normalizeBaseUrl(
        trimmed,
        appendDefaultPort: appendDefaultPort,
      );
      if (!candidates.contains(normalized)) {
        candidates.add(normalized);
      }
    }

    add(_apiBaseUrlOverride);
    add(_apiHostOverride, appendDefaultPort: true);
    add(defaultBaseUrl);
    if (!kReleaseMode) {
      add(cached);
      add(legacyManual);
    }

    if (!kReleaseMode && _apiHostOverride.isNotEmpty) {
      for (final host in _developmentHostnames) {
        add('http://$host:$_defaultPort');
      }

      if (!kIsWeb) {
        add('http://10.0.2.2:$_defaultPort');
        add('http://localhost:$_defaultPort');
      }
    }

    return candidates;
  }

  static Future<bool> _isHealthy(
    String candidate, {
    Duration timeout = _healthTimeout,
  }) async {
    try {
      final response = await http
          .get(Uri.parse('$candidate/health'))
          .timeout(timeout);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> _discoverLocalBackend({String? exclude}) async {
    if (kIsWeb) return null;

    final subnetPrefixes = <String>{};
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          final parts = address.address.split('.');
          if (parts.length != 4) continue;
          final first = int.tryParse(parts[0]) ?? -1;
          final second = int.tryParse(parts[1]) ?? -1;
          final isPrivate =
              first == 10 ||
              (first == 192 && second == 168) ||
              (first == 172 && second >= 16 && second <= 31);
          if (!isPrivate) continue;
          subnetPrefixes.add('${parts[0]}.${parts[1]}.${parts[2]}');
        }
      }
    } catch (_) {
      return null;
    }

    for (final prefix in subnetPrefixes) {
      final candidates = List<String>.generate(
        254,
        (index) => 'http://$prefix.${index + 1}:$_defaultPort',
      ).where((candidate) => candidate != exclude).toList(growable: false);

      for (var start = 0; start < candidates.length; start += 64) {
        final batch = candidates.skip(start).take(64).toList(growable: false);
        final checks = await Future.wait(
          batch.map(
            (candidate) async =>
                await _isHealthy(candidate, timeout: _discoveryHealthTimeout)
                ? candidate
                : null,
          ),
        );
        for (final match in checks) {
          if (match != null) return match;
        }
      }
    }

    return null;
  }

  static Future<http.Response> _sendWithReconnect(
    Future<http.Response> Function(String resolvedBaseUrl) request,
  ) async {
    await _ensureInitialized();
    final firstBaseUrl = baseUrl;

    try {
      return await request(firstBaseUrl).timeout(_requestTimeout);
    } catch (_) {
      await _resolveHealthyBaseUrl(exclude: firstBaseUrl);
      final nextBaseUrl = baseUrl;
      if (nextBaseUrl == firstBaseUrl) rethrow;
      return request(nextBaseUrl).timeout(_requestTimeout);
    }
  }

  static Future<http.StreamedResponse> _sendMultipartWithReconnect(
    Future<http.MultipartRequest> Function(String resolvedBaseUrl)
    createRequest,
  ) async {
    await _ensureInitialized();
    final firstBaseUrl = baseUrl;

    try {
      return await (await createRequest(
        firstBaseUrl,
      )).send().timeout(_requestTimeout);
    } catch (_) {
      await _resolveHealthyBaseUrl(exclude: firstBaseUrl);
      final nextBaseUrl = baseUrl;
      if (nextBaseUrl == firstBaseUrl) rethrow;
      return (await createRequest(nextBaseUrl)).send().timeout(_requestTimeout);
    }
  }

  static String? mediaUrl(String? path) {
    final trimmedPath = path?.trim();
    if (trimmedPath == null || trimmedPath.isEmpty) return null;
    if (RegExp(
      r'^(https?:|data:|blob:)',
      caseSensitive: false,
    ).hasMatch(trimmedPath)) {
      return trimmedPath;
    }
    final normalizedPath = trimmedPath.startsWith('/')
        ? trimmedPath
        : '/$trimmedPath';
    return '$baseUrl$normalizedPath';
  }

  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    try {
      final response = await _sendWithReconnect(
        (serverUrl) => http.post(
          Uri.parse('$serverUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'] ?? data['accessToken'];
        if (token != null) {
          await _writeSessionString(
            _tokenKey,
            _legacyTokenKey,
            token as String,
          );
        }
        if (data['user'] != null) {
          await _writeSessionString(
            _userKey,
            _legacyUserKey,
            jsonEncode(data['user']),
          );
        }
        return data;
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error logging in: $e');
    }
  }

  static Future<Map<String, dynamic>?> register(
    String username,
    String email,
    String password,
  ) async {
    try {
      final response = await _sendWithReconnect(
        (serverUrl) => http.post(
          Uri.parse('$serverUrl/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userName': username,
            'email': email,
            'password': password,
          }),
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Registration failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error registering: $e');
    }
  }

  static Future<Map<String, dynamic>?> googleLogin(String idToken) async {
    try {
      final response = await _sendWithReconnect(
        (serverUrl) => http.post(
          Uri.parse('$serverUrl/auth/google'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'idToken': idToken}),
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'] ?? data['accessToken'];
        if (token != null) {
          await _writeSessionString(
            _tokenKey,
            _legacyTokenKey,
            token as String,
          );
        }
        if (data['user'] != null) {
          await _writeSessionString(
            _userKey,
            _legacyUserKey,
            jsonEncode(data['user']),
          );
        }
        return data;
      } else {
        throw Exception('Google login failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error logging in with Google: $e');
    }
  }

  static Future<void> logout() async {
    await Future.wait<void>([
      _deleteSessionString(_tokenKey, _legacyTokenKey),
      _deleteSessionString(_userKey, _legacyUserKey),
    ]);
  }

  static bool isUnauthorizedError(Object error) {
    return error is ApiException && error.statusCode == 401;
  }

  static Future<bool> isLoggedIn() async {
    final token = await _readSessionString(_tokenKey, _legacyTokenKey);
    return token != null && token.isNotEmpty;
  }

  static Future<Map<String, dynamic>?> getStoredUser() async {
    final raw = await _readSessionString(_userKey, _legacyUserKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final parsed = jsonDecode(raw);
      return parsed is Map<String, dynamic> ? parsed : null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await _readSessionString(_tokenKey, _legacyTokenKey);
    return {
      'Content-Type': 'application/json',
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> _authedGetJson(String path) async {
    final headers = await _authHeaders();
    final response = await _sendWithReconnect(
      (serverUrl) => http.get(Uri.parse('$serverUrl$path'), headers: headers),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return <String, dynamic>{};
      }
      final parsed = jsonDecode(response.body);
      return parsed is Map<String, dynamic>
          ? parsed
          : <String, dynamic>{'data': parsed};
    }

    debugPrint(
      'SYBAU API GET $path failed: ${response.statusCode} ${response.body}',
    );
    throw ApiException(
      'Request failed',
      statusCode: response.statusCode,
      body: response.body,
    );
  }

  static Future<List<dynamic>> _authedGetList(String path) async {
    final headers = await _authHeaders();
    final response = await _sendWithReconnect(
      (serverUrl) => http.get(Uri.parse('$serverUrl$path'), headers: headers),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return <dynamic>[];
      }
      final parsed = jsonDecode(response.body);
      return parsed is List<dynamic> ? parsed : <dynamic>[];
    }

    debugPrint(
      'SYBAU API GET $path failed: ${response.statusCode} ${response.body}',
    );
    throw ApiException(
      'Request failed',
      statusCode: response.statusCode,
      body: response.body,
    );
  }

  static Future<void> _authedPut(String path, Map<String, dynamic> body) async {
    final headers = await _authHeaders();
    final encodedBody = jsonEncode(body);
    final response = await _sendWithReconnect(
      (serverUrl) => http.put(
        Uri.parse('$serverUrl$path'),
        headers: headers,
        body: encodedBody,
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Request failed (${response.statusCode}): ${response.body}',
      );
    }
  }

  static Future<Map<String, dynamic>> _authedPutJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final headers = await _authHeaders();
    final encodedBody = jsonEncode(body);
    final response = await _sendWithReconnect(
      (serverUrl) => http.put(
        Uri.parse('$serverUrl$path'),
        headers: headers,
        body: encodedBody,
      ),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return <String, dynamic>{};
      }
      final parsed = jsonDecode(response.body);
      return parsed is Map<String, dynamic>
          ? parsed
          : <String, dynamic>{'data': parsed};
    }

    throw Exception(
      'Request failed (${response.statusCode}): ${response.body}',
    );
  }

  static Future<Map<String, dynamic>> _authedPostJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final headers = await _authHeaders();
    final encodedBody = jsonEncode(body);
    final response = await _sendWithReconnect(
      (serverUrl) => http.post(
        Uri.parse('$serverUrl$path'),
        headers: headers,
        body: encodedBody,
      ),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return <String, dynamic>{};
      }
      final parsed = jsonDecode(response.body);
      return parsed is Map<String, dynamic>
          ? parsed
          : <String, dynamic>{'data': parsed};
    }

    throw Exception(
      'Request failed (${response.statusCode}): ${response.body}',
    );
  }

  static Future<void> _authedPost(
    String path,
    Map<String, dynamic> body,
  ) async {
    final headers = await _authHeaders();
    final encodedBody = jsonEncode(body);
    final response = await _sendWithReconnect(
      (serverUrl) => http.post(
        Uri.parse('$serverUrl$path'),
        headers: headers,
        body: encodedBody,
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Request failed (${response.statusCode}): ${response.body}',
      );
    }
  }

  static Future<void> _authedDelete(String path) async {
    final headers = await _authHeaders();
    final response = await _sendWithReconnect(
      (serverUrl) =>
          http.delete(Uri.parse('$serverUrl$path'), headers: headers),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Request failed (${response.statusCode}): ${response.body}',
      );
    }
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final profile = await _authedGetJson('/users/profile');
    await _writeSessionString(_userKey, _legacyUserKey, jsonEncode(profile));
    return profile;
  }

  static Future<Map<String, dynamic>> getUserProfile(int userId) async {
    return _authedGetJson('/users/$userId/profile');
  }

  static Future<List<dynamic>> getAchievements() async {
    return _authedGetList('/achievements');
  }

  static Future<Map<String, dynamic>> getProfileStats() async {
    return _authedGetJson('/achievements/stats');
  }

  static Future<Map<String, dynamic>> getTodayXp() async {
    return _authedGetJson('/achievements/today-xp');
  }

  static Future<List<dynamic>> getMyQuests() async {
    return _authedGetList('/quests');
  }

  static Future<List<dynamic>> getRecentActivities({int limit = 10}) async {
    return _authedGetList('/users/profile/recent-activities?limit=$limit');
  }

  static Future<List<dynamic>> getWeeklyActivity({
    required DateTime from,
    required DateTime to,
  }) async {
    final fromStr = _formatDate(from);
    final toStr = _formatDate(to);
    return _authedGetList(
      '/users/profile/weekly-activity?from=$fromStr&to=$toStr',
    );
  }

  static Future<List<dynamic>> getActivityYears() async {
    return _authedGetList('/users/profile/activity-years');
  }

  static Future<List<dynamic>> getLeaderboard() async {
    return _authedGetList('/users/leaderboard');
  }

  static Future<List<dynamic>> getUserBoosters() async {
    return _authedGetList('/users/boosts');
  }

  static Future<void> updateBoostSlots(List<int?> slots) async {
    await _authedPut('/users/boosts/slots', {'slots': slots});
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? userName,
    bool? isProfilePrivate,
  }) async {
    final payload = <String, dynamic>{};
    if (userName != null) {
      payload['username'] = userName;
    }
    if (isProfilePrivate != null) {
      payload['isProfilePrivate'] = isProfilePrivate;
    }

    await _authedPut('/users/profile', payload);
    return getProfile();
  }

  static Future<Map<String, dynamic>> uploadProfileImage(
    String filePath,
  ) async {
    final headers = await _authHeaders();
    final streamed = await _sendMultipartWithReconnect((serverUrl) async {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$serverUrl/users/profile/image'),
      );
      request.headers.addAll({
        if (headers['Authorization'] != null)
          'Authorization': headers['Authorization']!,
      });
      request.files.add(await http.MultipartFile.fromPath('image', filePath));
      return request;
    });

    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Request failed (${response.statusCode}): ${response.body}',
      );
    }

    final profile = await getProfile();
    if (response.body.isEmpty) {
      return profile;
    }

    final parsed = jsonDecode(response.body);
    return parsed is Map<String, dynamic>
        ? <String, dynamic>{...profile, ...parsed}
        : profile;
  }

  static Future<Map<String, dynamic>> removeProfileImage() async {
    await _authedDelete('/users/profile/image');
    return getProfile();
  }

  static Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _authedPost('/users/profile/change-password', {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });
  }

  static Future<void> deleteAccount() async {
    await _authedDelete('/users/profile');
  }

  static Future<List<dynamic>> getShopItems() async {
    return _authedGetList('/shop/items');
  }

  static Future<Map<String, dynamic>> getDailyShop() async {
    return _authedGetJson('/shop/daily');
  }

  static Future<void> buyItem(int itemId) async {
    await _authedPost('/shop/buy-item/$itemId', <String, dynamic>{});
  }

  static Future<List<dynamic>> getChests() async {
    return _authedGetList('/shop/chests');
  }

  static Future<Map<String, dynamic>> openChest(int chestId) async {
    return _authedPostJson('/shop/chests/$chestId/open', <String, dynamic>{});
  }

  static Future<List<dynamic>> getUserItems() async {
    return _authedGetList('/users/boosts');
  }

  static Future<Map<String, dynamic>> sellItem(int itemId) async {
    return _authedPostJson('/shop/sell-item/$itemId', <String, dynamic>{});
  }

  static Future<List<dynamic>> getWorkouts({String? category}) async {
    final path = category == null || category.isEmpty
        ? '/workouts'
        : '/workouts?category=$category';
    return _authedGetList(path);
  }

  static Future<List<dynamic>> getExercises({String? category}) async {
    final query = <String, String>{
      if (category != null && category.isNotEmpty) 'category': category,
      'date': _formatDate(DateTime.now()),
    };
    final uri = Uri(path: '/workouts/exercises', queryParameters: query);
    final path = uri.toString();
    return _authedGetList(path);
  }

  static Future<Map<String, dynamic>> logExercise({
    required int exerciseId,
    required int reps,
    int? elapsedSeconds,
  }) async {
    final body = <String, dynamic>{
      'exerciseId': exerciseId,
      'reps': reps,
      'date': _formatDate(DateTime.now()),
    };
    if (elapsedSeconds != null) {
      body['elapsedSeconds'] = elapsedSeconds;
    }
    return _authedPostJson('/workouts/exercises/log', body);
  }

  static Future<Map<String, dynamic>> createWorkout(
    Map<String, dynamic> payload,
  ) async {
    return _authedPostJson('/workouts', payload);
  }

  static Future<Map<String, dynamic>> getQuestStats() async {
    return _authedGetJson('/quests/stats');
  }

  static Future<Map<String, dynamic>> claimQuestReward(int userQuestId) async {
    return _authedPostJson('/quests/$userQuestId/claim', <String, dynamic>{});
  }

  static Future<Map<String, dynamic>> logQuestActivity({
    required String type,
    required double value,
  }) async {
    return _authedPostJson('/quests/activity', {'type': type, 'value': value});
  }

  static Future<Map<String, dynamic>> syncQuestActivityTotal({
    required String type,
    required double value,
    required String date,
  }) async {
    return _authedPostJson('/quests/activity/daily-total', {
      'type': type,
      'value': value,
      'date': date,
    });
  }

  static Future<Map<String, dynamic>> getTodayActivity() async {
    return _authedGetJson('/quests/activity/today');
  }

  static Future<List<dynamic>> getFriends() async {
    return _authedGetList('/friends');
  }

  static Future<List<dynamic>> getPendingFriendRequests() async {
    return _authedGetList('/friends/requests');
  }

  static Future<List<dynamic>> getSentFriendRequests() async {
    return _authedGetList('/friends/requests/sent');
  }

  static Future<Map<String, dynamic>> sendFriendRequest(String userName) async {
    return _authedPostJson('/friends/request', {'userName': userName});
  }

  static Future<Map<String, dynamic>> acceptFriendRequest(int requestId) async {
    return _authedPostJson(
      '/friends/requests/$requestId/accept',
      <String, dynamic>{},
    );
  }

  static Future<Map<String, dynamic>> declineFriendRequest(
    int requestId,
  ) async {
    return _authedPostJson(
      '/friends/requests/$requestId/decline',
      <String, dynamic>{},
    );
  }

  static Future<Map<String, dynamic>> removeFriend(int friendId) async {
    await _authedDelete('/friends/$friendId');
    return <String, dynamic>{'ok': true};
  }

  static Future<List<dynamic>> getFriendsLeaderboard() async {
    return _authedGetList('/friends/leaderboard');
  }

  static Future<List<dynamic>> getFriendChallenges() async {
    return _authedGetList('/friends/challenges');
  }

  static Future<List<dynamic>> getPendingFriendChallenges() async {
    return _authedGetList('/friends/challenges/pending');
  }

  static Future<Map<String, dynamic>> createFriendChallenge({
    required int opponentId,
    required String title,
    String? description,
    required int goalAmount,
    required String goalUnit,
    required int durationHours,
  }) async {
    return _authedPostJson('/friends/challenges', {
      'opponentId': opponentId,
      'title': title,
      'description': description,
      'goalAmount': goalAmount,
      'goalUnit': goalUnit,
      'durationHours': durationHours,
    });
  }

  static Future<Map<String, dynamic>> acceptFriendChallenge(int id) async {
    return _authedPostJson(
      '/friends/challenges/$id/accept',
      <String, dynamic>{},
    );
  }

  static Future<Map<String, dynamic>> declineFriendChallenge(int id) async {
    return _authedPostJson(
      '/friends/challenges/$id/decline',
      <String, dynamic>{},
    );
  }

  static Future<Map<String, dynamic>> deleteFriendChallenge(int id) async {
    await _authedDelete('/friends/challenges/$id');
    return <String, dynamic>{'ok': true};
  }

  static Future<Map<String, dynamic>> hideFriendChallenge(int id) async {
    await _authedDelete('/friends/challenges/$id');
    return <String, dynamic>{'ok': true};
  }

  static Future<Map<String, dynamic>> updateFriendChallengeProgress({
    required int id,
    required int amount,
  }) async {
    return _authedPutJson('/friends/challenges/$id/progress', {
      'amount': amount,
    });
  }

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
