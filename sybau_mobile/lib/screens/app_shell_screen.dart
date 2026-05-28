import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../services/health_sync_service.dart';
import '../services/notification_service.dart';
import '../theme_controller.dart';
import 'login_screen.dart';

part 'app_shell/dashboard_tab.dart';
part 'app_shell/models.dart';
part 'app_shell/workouts_tab.dart';
part 'app_shell/quests_tab.dart';
part 'app_shell/avatar_tab.dart';
part 'app_shell/shop_tab.dart';
part 'app_shell/friends_tab.dart';
part 'app_shell/leaderboard_tab.dart';
part 'app_shell/profile_tab.dart';
part 'app_shell/read_only_user_profile_sheet.dart';
part 'app_shell/shared_widgets.dart';

const String _noProfilePictureAsset = 'assets/Nopfp.png';
const String _appleHealthLogoAsset = 'assets/applehealth_logo.png';
const int _achievementPageSize = 4;
const Map<String, String> _mediaImageHeaders = <String, String>{
  'Accept': 'image/png,image/jpeg,image/webp,image/*,*/*;q=0.8',
};

String _lt({required String de, required String en}) {
  return de;
}

String _td(String value) {
  return value;
}

bool _isDataImageUrl(String? value) {
  final normalized = value?.trim().toLowerCase() ?? '';
  return normalized.startsWith('data:image/');
}

Uint8List? _decodeDataImageUrl(String? value) {
  final dataUrl = value?.trim();
  if (dataUrl == null || !_isDataImageUrl(dataUrl)) return null;

  final commaIndex = dataUrl.indexOf(',');
  if (commaIndex < 0 || commaIndex == dataUrl.length - 1) return null;

  final metadata = dataUrl.substring(0, commaIndex).toLowerCase();
  final payload = dataUrl.substring(commaIndex + 1);
  try {
    if (metadata.contains(';base64')) {
      return base64Decode(payload);
    }

    return Uint8List.fromList(utf8.encode(Uri.decodeComponent(payload)));
  } catch (_) {
    return null;
  }
}

String _optimizedMediaImageUrl(String value, {double? width, double? height}) {
  final trimmed = value.trim();
  final uri = Uri.tryParse(trimmed);
  if (uri == null ||
      !uri.hasScheme ||
      (uri.scheme != 'http' && uri.scheme != 'https')) {
    return trimmed;
  }

  if (uri.host != 'res.cloudinary.com') return trimmed;

  const marker = '/image/upload/';
  final markerIndex = uri.path.indexOf(marker);
  if (markerIndex < 0) return trimmed;

  final tail = uri.path.substring(markerIndex + marker.length);
  final alreadyTransformed =
      tail.startsWith('f_') ||
      tail.startsWith('q_') ||
      tail.startsWith('c_') ||
      tail.startsWith('w_') ||
      tail.startsWith('h_');
  if (alreadyTransformed) return trimmed;

  final logicalSize = math.max(width ?? 128, height ?? 128);
  final targetWidth = logicalSize <= 160
      ? 384
      : logicalSize <= 280
      ? 768
      : logicalSize <= 420
      ? 1024
      : 1280;
  final transform = 'f_auto,q_auto:eco,c_limit,w_$targetWidth';
  final optimizedPath =
      '${uri.path.substring(0, markerIndex + marker.length)}$transform/$tail';
  return uri.replace(path: optimizedPath).toString();
}

Widget _mediaImageErrorFallback(
  String imageUrl,
  Object error,
  Widget Function() fallback,
) {
  debugPrint('SYBAU image load failed: $imageUrl ($error)');
  return fallback();
}

Widget _buildMediaLoadingPlaceholder({double? width, double? height}) {
  if (width == null && height == null) return const SizedBox.shrink();
  return SizedBox(width: width, height: height);
}

int? _mediaDecodeDimension(double? value) {
  if (value == null || value <= 0) return null;
  return (value * 3).round().clamp(96, 1536);
}

Future<void> _precacheMediaImage(
  BuildContext context,
  String? imageUrl, {
  double? width,
  double? height,
}) async {
  final resolved = ApiService.mediaUrl(imageUrl);
  final dataBytes = _decodeDataImageUrl(resolved);
  if (dataBytes != null || resolved == null || resolved.trim().isEmpty) {
    return;
  }

  final optimizedUrl = _optimizedMediaImageUrl(
    resolved,
    width: width,
    height: height,
  );
  await precacheImage(
    NetworkImage(optimizedUrl, headers: _mediaImageHeaders),
    context,
    onError: (error, _) {
      debugPrint('SYBAU image preload failed: $optimizedUrl ($error)');
    },
  );
}

Widget _buildProfileImageFromUrl(
  String? imageUrl, {
  BoxFit fit = BoxFit.cover,
  bool gaplessPlayback = false,
  Key? key,
}) {
  Widget fallback() => Image.asset(_noProfilePictureAsset, fit: fit);

  final dataBytes = _decodeDataImageUrl(imageUrl);
  if (dataBytes != null) {
    return Image.memory(
      dataBytes,
      key: key,
      fit: fit,
      gaplessPlayback: gaplessPlayback,
    );
  }

  if (imageUrl == null || imageUrl.trim().isEmpty) {
    return fallback();
  }

  final optimizedUrl = _optimizedMediaImageUrl(imageUrl);
  return Image.network(
    optimizedUrl,
    key: key,
    fit: fit,
    gaplessPlayback: gaplessPlayback,
    headers: _mediaImageHeaders,
    errorBuilder: (_, error, _) =>
        _mediaImageErrorFallback(optimizedUrl, error, fallback),
  );
}

Widget _buildMediaImageFromUrl(
  String? imageUrl, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.contain,
  FilterQuality filterQuality = FilterQuality.none,
  bool isAntiAlias = false,
  bool gaplessPlayback = true,
  required Widget Function() fallback,
}) {
  final resolved = ApiService.mediaUrl(imageUrl);
  final dataBytes = _decodeDataImageUrl(resolved);
  if (dataBytes != null) {
    return Image.memory(
      dataBytes,
      width: width,
      height: height,
      fit: fit,
      filterQuality: filterQuality,
      isAntiAlias: isAntiAlias,
      gaplessPlayback: gaplessPlayback,
    );
  }

  if (resolved == null || resolved.trim().isEmpty) {
    return fallback();
  }

  final optimizedUrl = _optimizedMediaImageUrl(
    resolved,
    width: width,
    height: height,
  );
  return Image.network(
    optimizedUrl,
    width: width,
    height: height,
    fit: fit,
    filterQuality: filterQuality,
    isAntiAlias: isAntiAlias,
    gaplessPlayback: gaplessPlayback,
    headers: _mediaImageHeaders,
    cacheWidth: _mediaDecodeDimension(width),
    loadingBuilder: (_, child, loadingProgress) {
      if (loadingProgress == null) return child;
      return _buildMediaLoadingPlaceholder(width: width, height: height);
    },
    errorBuilder: (_, error, _) =>
        _mediaImageErrorFallback(optimizedUrl, error, fallback),
  );
}

String _formatCompactNumber(int value) {
  if (value.abs() < 10000) return value.toString();

  const units = <({int amount, String suffix})>[
    (amount: 1000000000, suffix: 'B'),
    (amount: 1000000, suffix: 'M'),
    (amount: 1000, suffix: 'K'),
  ];

  for (final unit in units) {
    if (value.abs() >= unit.amount) {
      final compact = value / unit.amount;
      final rounded = compact >= 100
          ? compact.toStringAsFixed(0)
          : compact.toStringAsFixed(compact % 1 == 0 ? 0 : 1);
      return '${rounded.replaceAll('.', ',')}${unit.suffix}';
    }
  }

  return value.toString();
}

int _lastAchievementPageStart(int count) {
  if (count <= _achievementPageSize) return 0;
  return ((count - 1) ~/ _achievementPageSize) * _achievementPageSize;
}

String _normalizeBodyStage(String stage) {
  switch (stage.trim().toLowerCase()) {
    case 'bodybuilder':
      return 'Bodybuilder';
    case 'defined':
      return 'Defined';
    case 'skinny':
    default:
      return 'Skinny';
  }
}

enum AppTab {
  dashboard,
  workouts,
  quests,
  avatar,
  shop,
  friends,
  leaderboard,
  profile,
}

class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key, this.initialTab = AppTab.dashboard});

  final AppTab initialTab;

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  late AppTab _currentTab;

  Map<String, dynamic> _profile = <String, dynamic>{};
  bool _notificationsEnabled = true;
  List<Map<String, dynamic>> _notifications = <Map<String, dynamic>>[];
  Set<String> _knownNotificationKeys = <String>{};
  Timer? _notificationPollTimer;
  Timer? _rewardFlashTimer;
  bool _headerRefreshInFlight = false;
  int _rewardFlashXp = 0;
  int _rewardFlashCoins = 0;
  int _rewardFlashToken = 0;
  bool _hasClaimableQuest = false;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    unawaited(_loadHeaderProfile());
    unawaited(_syncHealthOnLogin());
    unawaited(_refreshQuestBadge());
    _startNotificationPolling();
  }

  @override
  void dispose() {
    _notificationPollTimer?.cancel();
    _rewardFlashTimer?.cancel();
    super.dispose();
  }

  void _showHeaderReward({int xp = 0, int coins = 0}) {
    if (!mounted || (xp <= 0 && coins <= 0)) return;
    _rewardFlashTimer?.cancel();
    setState(() {
      _rewardFlashXp = math.max(0, xp);
      _rewardFlashCoins = math.max(0, coins);
      _rewardFlashToken++;
    });
    _rewardFlashTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() {
        _rewardFlashXp = 0;
        _rewardFlashCoins = 0;
      });
    });
  }

  bool _isClaimableQuest(dynamic quest) {
    final map = _map(quest);
    final completed = _toBool(map['isCompleted'] ?? map['IsCompleted']);
    final claimed = _toBool(map['isRewardClaimed'] ?? map['IsRewardClaimed']);
    return completed && !claimed;
  }

  Future<void> _refreshQuestBadge() async {
    try {
      final quests = await ApiService.getMyQuests();
      if (!mounted) return;
      setState(() {
        _hasClaimableQuest = quests.any(_isClaimableQuest);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasClaimableQuest = false;
      });
    }
  }

  Future<void> _loadHeaderProfile({bool showError = true}) async {
    if (_headerRefreshInFlight) return;
    _headerRefreshInFlight = true;
    try {
      final profile = await ApiService.getProfile();
      var notificationsEnabled = _notificationsEnabled;
      try {
        notificationsEnabled = await NotificationService.isEnabled();
      } catch (_) {
        // Notification settings are local convenience data and should not break the header.
      }
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _notificationsEnabled = notificationsEnabled;
      });
    } catch (e) {
      if (!mounted) return;
      if (ApiService.isUnauthorizedError(e)) {
        await ApiService.logout();
        if (!mounted) return;
        _showSnack('Sitzung abgelaufen. Bitte melde dich neu an.');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
        return;
      }

      final storedUser = await ApiService.getStoredUser();
      if (!mounted) return;
      setState(() {
        if (storedUser != null) {
          _profile = storedUser;
        }
      });
      debugPrint('SYBAU Header load failed: $e');
      if (showError) {
        _showSnack('Header-Daten konnten nicht geladen werden.');
      }
    } finally {
      _headerRefreshInFlight = false;
    }
  }

  Future<void> _refreshHeaderData({bool showError = true}) async {
    await _loadHeaderProfile(showError: showError);
    await _refreshQuestBadge();
  }

  void _selectTab(AppTab tab) {
    if (_currentTab != tab) {
      setState(() => _currentTab = tab);
    }
    unawaited(_refreshHeaderData(showError: false));
  }

  void _startNotificationPolling() {
    unawaited(_refreshNotifications(seedOnly: true));
    _notificationPollTimer?.cancel();
    _notificationPollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      unawaited(_refreshNotifications());
    });
  }

  Future<void> _syncHealthOnLogin() async {
    try {
      final result = await HealthSyncService.syncIfEnabled();
      if (result == null || !mounted) return;
      if (result.hasNewData) {
        await _loadHeaderProfile();
        await _refreshQuestBadge();
      }
      if (result.hasRewards) {
        _showHeaderReward(xp: result.xpEarned, coins: result.coinsEarned);
        _showSnack(
          'Health automatisch synchronisiert: +${_formatCompactNumber(result.xpEarned)} XP, +${_formatCompactNumber(result.coinsEarned)} Coins.',
        );
      }
    } catch (_) {
      // Automatic Health sync should never block login or opening the app.
    }
  }

  Future<void> _refreshNotifications({bool seedOnly = false}) async {
    try {
      final results = await Future.wait<dynamic>([
        ApiService.getPendingFriendRequests(),
        ApiService.getPendingFriendChallenges(),
        NotificationService.isEnabled(),
      ]);

      final requests = (results[0] as List<dynamic>?) ?? <dynamic>[];
      final challenges = (results[1] as List<dynamic>?) ?? <dynamic>[];
      final enabled = results[2] as bool;

      final notifications = <Map<String, dynamic>>[
        ...requests.map((dynamic item) {
          final map = _map(item);
          final id = _toInt(map['id']);
          final userName = _string(
            map['userName'],
            fallback: _string(map['requesterName'], fallback: 'Unbekannt'),
          );
          return <String, dynamic>{
            'key': 'request-$id',
            'kind': 'request',
            'title': 'Freundschaftsanfrage',
            'subtitle': '$userName hat dir eine Anfrage geschickt.',
            'userName': userName,
          };
        }),
        ...challenges.map((dynamic item) {
          final map = _map(item);
          final id = _toInt(map['id']);
          final challenger = _string(
            map['challengerUserName'],
            fallback: 'Unbekannt',
          );
          final title = _string(map['title'], fallback: 'Neue Challenge');
          return <String, dynamic>{
            'key': 'challenge-$id',
            'kind': 'challenge',
            'title': 'Challenge-Einladung',
            'subtitle': '$challenger fordert dich heraus: $title',
            'userName': challenger,
          };
        }),
      ];

      final keys = notifications
          .map((Map<String, dynamic> item) => item['key'] as String)
          .toSet();
      final newKeys = keys.difference(_knownNotificationKeys);

      if (!mounted) return;
      setState(() {
        _notificationsEnabled = enabled;
        _notifications = notifications;
        _knownNotificationKeys = keys;
      });

      if (!seedOnly && enabled && newKeys.isNotEmpty) {
        final firstNew = notifications.firstWhere(
          (item) => newKeys.contains(item['key']),
          orElse: () => <String, dynamic>{},
        );
        final message = _string(firstNew['subtitle']);
        if (message.isNotEmpty) {
          _showSnack(message);
        }
      }
    } catch (_) {
      // In-app notifications should fail quietly so the rest of the shell keeps working.
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    final lower = message.toLowerCase();
    final isError =
        lower.contains('fehl') ||
        lower.contains('konnte nicht') ||
        lower.contains('konnten nicht') ||
        lower.contains('nicht geladen') ||
        lower.contains('nicht freigegeben') ||
        lower.contains('denied') ||
        lower.contains('failed') ||
        lower.contains('error') ||
        lower.contains('abgelaufen') ||
        lower.contains('unauthorized');
    final bg = isError
        ? Color(0xFF781919).withOpacity(0.95)
        : Color(0xFF10552D).withOpacity(0.95);
    final border = isError
        ? Color(0xFFF87171).withOpacity(0.7)
        : Color(0xFF22C55E).withOpacity(0.7);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Color(0xFFDCFCE7)),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border),
        ),
      ),
    );
  }

  int get _level => _toInt(_map(_profile['avatar'])['level']);
  int get _xp {
    final avatar = _map(_profile['avatar']);
    return _toInt(
      _profile['totalXp'],
      fallback: _calculateTotalXp(
        _toInt(avatar['level'], fallback: 1),
        _toInt(avatar['experience']),
      ),
    );
  }

  int get _coins => _toInt(_profile['coins']);

  int _calculateTotalXp(int level, int experience) {
    var total = 0;
    for (var lvl = 1; lvl < level; lvl++) {
      total += 100 + lvl * lvl * 20;
    }
    return total + experience;
  }

  double _contentMaxWidth(double screenWidth) {
    if (screenWidth >= 1180) return 980;
    if (screenWidth >= 900) return 860;
    if (screenWidth >= 720) return 760;
    return screenWidth;
  }

  Widget _buildTopHeader() {
    final isLight = SybauThemeController.isLight;
    final notificationCount = _notifications.length;
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          color: isLight
              ? Colors.white.withOpacity(0.94)
              : Color(0xFF050A12).withOpacity(0.92),
          border: Border(
            bottom: BorderSide(
              color: isLight
                  ? Colors.black.withOpacity(0.08)
                  : Colors.white.withOpacity(0.08),
            ),
          ),
        ),
        child: Row(
          children: [
            Image.asset(
              'assets/Sybau_logo_short.png',
              height: 32,
              width: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  children: [
                    _StatChip(
                      assetPath: 'assets/Star_Pixel.png',
                      label: 'Level',
                      value: '$_level',
                    ),
                    const SizedBox(width: 10),
                    _StatChip(
                      assetPath: 'assets/XP_Pixel.png',
                      label: 'XP',
                      value: _formatCompactNumber(_xp),
                      delta: _rewardFlashXp > 0
                          ? '+${_formatCompactNumber(_rewardFlashXp)}'
                          : null,
                      deltaColor: const Color(0xFF60A5FA),
                      deltaToken: _rewardFlashToken,
                    ),
                    const SizedBox(width: 10),
                    _StatChip(
                      assetPath: 'assets/SYBAU_Coin.png',
                      label: 'Coins',
                      value: _formatCompactNumber(_coins),
                      delta: _rewardFlashCoins > 0
                          ? '+${_formatCompactNumber(_rewardFlashCoins)}'
                          : null,
                      deltaColor: const Color(0xFFFBBF24),
                      deltaToken: _rewardFlashToken,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _openNotificationsSheet,
              borderRadius: BorderRadius.circular(999),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isLight
                          ? const Color(0xFFF8FAFC)
                          : Colors.white.withOpacity(0.06),
                      border: Border.all(
                        color: isLight
                            ? Colors.black.withOpacity(0.08)
                            : Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: Icon(
                      Icons.notifications_rounded,
                      color: isLight ? const Color(0xFF0F172A) : Colors.white,
                      size: 20,
                    ),
                  ),
                  if (notificationCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFFEC4899),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          notificationCount > 9 ? '9+' : '$notificationCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openNotificationsSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Benachrichtigungen',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            if (_notifications.isEmpty)
              Text(
                'Gerade ist alles ruhig. Neue Anfragen und Challenges tauchen hier auf.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.68),
                  height: 1.4,
                ),
              )
            else
              ..._notifications.map((item) {
                final kind = _string(item['kind']);
                final icon = kind == 'challenge'
                    ? Icons.emoji_events_rounded
                    : Icons.person_add_alt_1_rounded;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withOpacity(0.04),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Color(0xFFEC4899).withOpacity(0.14),
                      ),
                      child: Icon(icon, color: Color(0xFFFDA4AF)),
                    ),
                    title: Text(
                      _string(item['title']),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      _string(item['subtitle']),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.62),
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white38,
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _selectTab(AppTab.friends);
                    },
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentTab) {
      case AppTab.dashboard:
        return DashboardTab(
          onRefreshHeader: () => _loadHeaderProfile(),
          onOpenAvatar: () => _selectTab(AppTab.avatar),
          showSnack: _showSnack,
        );
      case AppTab.workouts:
        return WorkoutsTab(
          onRefreshHeader: () => _loadHeaderProfile(),
          onRewardEarned: _showHeaderReward,
          onQuestStatusChanged: _refreshQuestBadge,
          showSnack: _showSnack,
        );
      case AppTab.quests:
        return QuestsTab(
          onRefreshHeader: () => _loadHeaderProfile(),
          onRewardEarned: _showHeaderReward,
          onQuestStatusChanged: _refreshQuestBadge,
          showSnack: _showSnack,
        );
      case AppTab.avatar:
        return AvatarTab(
          onRefreshHeader: () => _loadHeaderProfile(),
          onRewardEarned: _showHeaderReward,
          showSnack: _showSnack,
        );
      case AppTab.shop:
        return ShopTab(
          onRefreshHeader: () => _loadHeaderProfile(),
          showSnack: _showSnack,
          initialCoins: _coins,
        );
      case AppTab.friends:
        return FriendsTab(
          onRefreshHeader: () => _loadHeaderProfile(),
          onRewardEarned: _showHeaderReward,
          showSnack: _showSnack,
        );
      case AppTab.leaderboard:
        return LeaderboardTab(showSnack: _showSnack);
      case AppTab.profile:
        return ProfileTab(
          onRefreshHeader: () => _loadHeaderProfile(),
          onRewardEarned: _showHeaderReward,
          showSnack: _showSnack,
        );
    }
  }

  Widget _buildBottomNav() {
    final isLight = SybauThemeController.isLight;
    final activeColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final inactiveColor = isLight ? const Color(0xFF475569) : Colors.white70;
    final entries = <_NavEntry>[
      _NavEntry(AppTab.dashboard, Icons.dashboard, 'Dashboard'),
      _NavEntry(
        AppTab.workouts,
        Icons.fitness_center,
        _lt(de: 'Workouts', en: 'Workouts'),
      ),
      _NavEntry(AppTab.quests, Icons.emoji_events, 'Quests'),
      _NavEntry(AppTab.avatar, Icons.person, 'Avatar'),
      _NavEntry(AppTab.shop, Icons.storefront, 'Shop'),
      _NavEntry(
        AppTab.friends,
        Icons.groups,
        _lt(de: 'Freunde', en: 'Friends'),
      ),
      _NavEntry(AppTab.leaderboard, Icons.leaderboard, 'Leaderboard'),
      _NavEntry(
        AppTab.profile,
        Icons.flash_on,
        _lt(de: 'Profil', en: 'Profile'),
      ),
    ];

    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isLight
                ? Colors.white.withOpacity(0.84)
                : Color(0xFF03070D).withOpacity(0.78),
            border: Border(
              bottom: BorderSide(
                color: isLight
                    ? Colors.black.withOpacity(0.08)
                    : Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: entries
                  .map((entry) {
                    final isActive = _currentTab == entry.tab;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _selectTab(entry.tab),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Icon(
                                        entry.icon,
                                        size: 18,
                                        color: isActive
                                            ? activeColor
                                            : inactiveColor,
                                      ),
                                      if (entry.tab == AppTab.quests &&
                                          _hasClaimableQuest)
                                        Positioned(
                                          top: -4,
                                          right: -5,
                                          child: Container(
                                            width: 9,
                                            height: 9,
                                            decoration: BoxDecoration(
                                              color: Color(0xFFEF4444),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isLight
                                                    ? Colors.white.withOpacity(
                                                        0.94,
                                                      )
                                                    : Color(
                                                        0xFF03070D,
                                                      ).withOpacity(0.92),
                                                width: 1.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Color(
                                                    0xFFEF4444,
                                                  ).withOpacity(0.75),
                                                  blurRadius: 8,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    entry.label,
                                    style: TextStyle(
                                      color: isActive
                                          ? activeColor
                                          : inactiveColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOut,
                                height: 2.5,
                                width: isActive ? 52 : 0,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFEC4899),
                                      Color(0xFFF43F5E),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(999),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = SybauThemeController.isLight;
    return Scaffold(
      backgroundColor: isLight
          ? const Color(0xFFF8FAFC)
          : const Color(0xFF01040A),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isLight
                      ? const [
                          Color(0xFFFFFFFF),
                          Color(0xFFF8FAFC),
                          Color(0xFFEFF6FF),
                          Color(0xFFFFFFFF),
                        ]
                      : const [
                          Color(0xFF01040A),
                          Color(0xFF02060E),
                          Color(0xFF06101E),
                          Color(0xFF020408),
                        ],
                  stops: const [0.0, 0.38, 0.74, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                children: [
                  Positioned(
                    top: -120,
                    left: -90,
                    child: _BackgroundGlow(
                      size: 220,
                      color: (isLight ? Color(0xFF93C5FD) : Color(0xFF2563EB))
                          .withOpacity(isLight ? 0.18 : 0.16),
                    ),
                  ),
                  Positioned(
                    top: 110,
                    right: -90,
                    child: _BackgroundGlow(
                      size: 200,
                      color: (isLight ? Color(0xFFF9A8D4) : Color(0xFF0EA5E9))
                          .withOpacity(isLight ? 0.14 : 0.07),
                    ),
                  ),
                  Positioned(
                    bottom: -110,
                    left: -70,
                    child: _BackgroundGlow(
                      size: 240,
                      color: (isLight ? Color(0xFFBFDBFE) : Color(0xFF38BDF8))
                          .withOpacity(isLight ? 0.16 : 0.05),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Column(
            children: [
              _buildTopHeader(),
              _buildBottomNav(),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = _contentMaxWidth(constraints.maxWidth);
                    return Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: math.min(constraints.maxWidth, maxWidth),
                        child: _buildBody(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
          stops: const [0.0, 1.0],
        ),
        boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 16)],
      ),
    );
  }
}

class _NavEntry {
  const _NavEntry(this.tab, this.icon, this.label);

  final AppTab tab;
  final IconData icon;
  final String label;
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    this.icon,
    this.assetPath,
    this.delta,
    this.deltaColor = Colors.white,
    this.deltaToken = 0,
    required this.label,
    required this.value,
  }) : assert(icon != null || assetPath != null);

  final IconData? icon;
  final String? assetPath;
  final String? delta;
  final Color deltaColor;
  final int deltaToken;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isLight = SybauThemeController.isLight;
    final labelColor = isLight ? const Color(0xFF64748B) : Colors.white54;
    final valueColor = isLight ? const Color(0xFF0F172A) : Colors.white;

    return Row(
      children: [
        assetPath != null
            ? Image.asset(
                assetPath!,
                width: 18,
                height: 18,
                fit: BoxFit.contain,
              )
            : Icon(icon, size: 16),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: labelColor, fontSize: 9)),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            SizedBox(
              height: 14,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  final offset = Tween<Offset>(
                    begin: const Offset(0, -0.25),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: offset, child: child),
                  );
                },
                child: delta == null
                    ? const SizedBox(
                        key: ValueKey<String>('reward-empty'),
                        height: 14,
                      )
                    : Text(
                        delta!,
                        key: ValueKey<String>(
                          'reward-$label-$deltaToken-$delta',
                        ),
                        style: TextStyle(
                          color: deltaColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          height: 1,
                          shadows: <Shadow>[
                            Shadow(color: deltaColor, blurRadius: 10),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
