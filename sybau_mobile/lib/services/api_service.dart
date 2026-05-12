import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
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
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );
  static const String _apiHostOverride = String.fromEnvironment('API_HOST');
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
  static String? _resolvedBaseUrl;
  static Future<void>? _initializeFuture;

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

    final discovered = await _discoverLocalBackend(exclude: exclude);
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
      return _normalizeBaseUrl(_apiHostOverride);
    }

    if (kIsWeb) {
      return 'http://localhost:$_defaultPort';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:$_defaultPort';
      case TargetPlatform.iOS:
        return 'http://${_developmentHostnames.first}:$_defaultPort';
      default:
        return 'http://localhost:$_defaultPort';
    }
  }

  static String _normalizeBaseUrl(String input) {
    final normalizedInput = input.contains('://') ? input : 'http://$input';
    final uri = Uri.tryParse(normalizedInput);
    if (uri == null) return normalizedInput;
    if (uri.hasPort) {
      return '${uri.scheme}://${uri.host}:${uri.port}';
    }
    return '${uri.scheme}://${uri.host}:$_defaultPort';
  }

  static List<String> _baseUrlCandidates({
    String? cached,
    String? legacyManual,
  }) {
    final candidates = <String>[];

    void add(String? value) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isEmpty) return;
      final normalized = _normalizeBaseUrl(trimmed);
      if (!candidates.contains(normalized)) {
        candidates.add(normalized);
      }
    }

    add(_apiBaseUrlOverride);
    add(_apiHostOverride);
    if (!kIsWeb) {
      add('http://127.0.0.1:$_defaultPort');
      add('http://localhost:$_defaultPort');
    }
    add(cached);
    add(legacyManual);
    add(defaultBaseUrl);

    for (final host in _developmentHostnames) {
      add('http://$host:$_defaultPort');
    }

    if (!kIsWeb) {
      add('http://10.0.2.2:$_defaultPort');
      add('http://localhost:$_defaultPort');
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
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
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
        final prefs = await SharedPreferences.getInstance();
        final token = data['token'] ?? data['accessToken'];
        if (token != null) {
          await prefs.setString('token', token as String);
        }
        if (data['user'] != null) {
          await prefs.setString('user', jsonEncode(data['user']));
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
        final prefs = await SharedPreferences.getInstance();
        final token = data['token'] ?? data['accessToken'];
        if (token != null) {
          await prefs.setString('token', token as String);
        }
        if (data['user'] != null) {
          await prefs.setString('user', jsonEncode(data['user']));
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  static bool isUnauthorizedError(Object error) {
    return error is ApiException && error.statusCode == 401;
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('token');
  }

  static Future<Map<String, dynamic>?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('user');
    if (raw == null || raw.isEmpty) return null;
    try {
      final parsed = jsonDecode(raw);
      return parsed is Map<String, dynamic> ? parsed : null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(profile));
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
    final fromStr = from.toIso8601String().split('T').first;
    final toStr = to.toIso8601String().split('T').first;
    return _authedGetList(
      '/users/profile/weekly-activity?from=$fromStr&to=$toStr',
    );
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

  static Future<Map<String, dynamic>> updateProfile({String? userName}) async {
    final payload = <String, dynamic>{};
    if (userName != null) {
      payload['username'] = userName;
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
    final path = category == null || category.isEmpty
        ? '/workouts/exercises'
        : '/workouts/exercises?category=$category';
    return _authedGetList(path);
  }

  static Future<Map<String, dynamic>> logExercise({
    required int exerciseId,
    required int reps,
    int? elapsedSeconds,
  }) async {
    return _authedPostJson('/workouts/exercises/log', {
      'exerciseId': exerciseId,
      'reps': reps,
      if (elapsedSeconds != null) 'elapsedSeconds': elapsedSeconds,
    });
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
}
