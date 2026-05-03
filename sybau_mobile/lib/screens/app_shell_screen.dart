import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../services/health_sync_service.dart';
import '../services/notification_service.dart';
import 'login_screen.dart';

const String _noProfilePictureAsset = 'assets/Nopfp.png';
const String _appleHealthLogoAsset = 'assets/applehealth_logo.png';
const int _achievementPageSize = 4;

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
  bool _loadingHeader = true;

  Map<String, dynamic> _profile = <String, dynamic>{};
  bool _notificationsEnabled = true;
  List<Map<String, dynamic>> _notifications = <Map<String, dynamic>>[];
  Set<String> _knownNotificationKeys = <String>{};
  Timer? _notificationPollTimer;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    unawaited(_loadHeaderProfile());
    unawaited(_syncHealthOnLogin());
    _startNotificationPolling();
  }

  @override
  void dispose() {
    _notificationPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadHeaderProfile() async {
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
        _loadingHeader = false;
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
        _loadingHeader = false;
      });
      debugPrint('SYBAU Header load failed: $e');
      _showSnack('Header-Daten konnten nicht geladen werden.');
    }
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
      }
      if (result.hasRewards) {
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
        ? const Color(0xFF781919).withOpacity(0.95)
        : const Color(0xFF10552D).withOpacity(0.95);
    final border = isError
        ? const Color(0xFFF87171).withOpacity(0.7)
        : const Color(0xFF22C55E).withOpacity(0.7);

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

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
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
    final notificationCount = _notifications.length;
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF050A12).withOpacity(0.92),
          border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.08)),
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
                    ),
                    const SizedBox(width: 10),
                    _StatChip(
                      assetPath: 'assets/SYBAU_Coin.png',
                      label: 'Coins',
                      value: _formatCompactNumber(_coins),
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
                      color: Colors.white.withOpacity(0.06),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: const Icon(
                      Icons.notifications_rounded,
                      color: Colors.white,
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
                          color: const Color(0xFFEC4899),
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
      backgroundColor: const Color(0xFF0F172A),
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
                        color: const Color(0xFFEC4899).withOpacity(0.14),
                      ),
                      child: Icon(icon, color: const Color(0xFFFDA4AF)),
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
                      setState(() => _currentTab = AppTab.friends);
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
          onRefreshHeader: _loadHeaderProfile,
          onOpenAvatar: () => setState(() => _currentTab = AppTab.avatar),
          showSnack: _showSnack,
        );
      case AppTab.workouts:
        return WorkoutsTab(
          onRefreshHeader: _loadHeaderProfile,
          showSnack: _showSnack,
        );
      case AppTab.quests:
        return QuestsTab(
          onRefreshHeader: _loadHeaderProfile,
          showSnack: _showSnack,
        );
      case AppTab.avatar:
        return AvatarTab(
          onRefreshHeader: _loadHeaderProfile,
          showSnack: _showSnack,
        );
      case AppTab.shop:
        return ShopTab(
          onRefreshHeader: _loadHeaderProfile,
          showSnack: _showSnack,
        );
      case AppTab.friends:
        return FriendsTab(
          onRefreshHeader: _loadHeaderProfile,
          showSnack: _showSnack,
        );
      case AppTab.leaderboard:
        return LeaderboardTab(showSnack: _showSnack);
      case AppTab.profile:
        return ProfileTab(
          onRefreshHeader: _loadHeaderProfile,
          showSnack: _showSnack,
        );
    }
  }

  Widget _buildBottomNav() {
    final entries = <_NavEntry>[
      _NavEntry(AppTab.dashboard, Icons.dashboard, 'Dashboard'),
      _NavEntry(AppTab.workouts, Icons.fitness_center, 'Workouts'),
      _NavEntry(AppTab.quests, Icons.emoji_events, 'Quests'),
      _NavEntry(AppTab.avatar, Icons.person, 'Avatar'),
      _NavEntry(AppTab.shop, Icons.storefront, 'Shop'),
      _NavEntry(AppTab.friends, Icons.groups, 'Friends'),
      _NavEntry(AppTab.leaderboard, Icons.leaderboard, 'Leaderboard'),
      _NavEntry(AppTab.profile, Icons.flash_on, 'Profile'),
    ];

    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF03070D).withOpacity(0.78),
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.08)),
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
                        onTap: () => setState(() => _currentTab = entry.tab),
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
                                  Icon(
                                    entry.icon,
                                    size: 18,
                                    color: isActive
                                        ? Colors.white
                                        : Colors.white70,
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    entry.label,
                                    style: TextStyle(
                                      color: isActive
                                          ? Colors.white
                                          : Colors.white70,
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
                                decoration: const BoxDecoration(
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
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF01040A),
                    Color(0xFF02060E),
                    Color(0xFF06101E),
                    Color(0xFF020408),
                  ],
                  stops: [0.0, 0.38, 0.74, 1.0],
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
                      color: const Color(0xFF2563EB).withOpacity(0.16),
                    ),
                  ),
                  Positioned(
                    top: 110,
                    right: -90,
                    child: _BackgroundGlow(
                      size: 200,
                      color: const Color(0xFF0EA5E9).withOpacity(0.07),
                    ),
                  ),
                  Positioned(
                    bottom: -110,
                    left: -70,
                    child: _BackgroundGlow(
                      size: 240,
                      color: const Color(0xFF38BDF8).withOpacity(0.05),
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
    this.iconColor,
    this.assetPath,
    required this.label,
    required this.value,
  }) : assert(icon != null || assetPath != null);

  final IconData? icon;
  final Color? iconColor;
  final String? assetPath;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        assetPath != null
            ? Image.asset(
                assetPath!,
                width: 18,
                height: 18,
                fit: BoxFit.contain,
              )
            : Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 9),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class DashboardTab extends StatefulWidget {
  const DashboardTab({
    required this.onRefreshHeader,
    required this.showSnack,
    required this.onOpenAvatar,
    super.key,
  });

  final Future<void> Function() onRefreshHeader;
  final void Function(String) showSnack;
  final VoidCallback onOpenAvatar;

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  bool _loading = true;

  String _userName = 'Champion';
  String _bodyStage = 'Skinny';
  int _level = 1;
  int _currentXp = 0;
  int _xpForNextLevel = 1000;
  int _totalXp = 0;
  int _todayXp = 0;

  int _currentStreak = 0;
  int _unlockedAchievements = 0;
  int _totalAchievements = 0;
  int _completedQuests = 0;
  int _activeQuests = 0;
  int _totalQuests = 0;
  String _leaderboardRank = '-';

  final List<Booster?> _boostSlots = <Booster?>[null, null, null, null];
  List<Booster> _ownedBoosters = <Booster>[];

  int get _progressPercent {
    final denom = _xpForNextLevel <= 0 ? 1 : _xpForNextLevel;
    final ratio = (_currentXp / denom).clamp(0, 1);
    return (ratio * 100).floor();
  }

  double get _arcProgress => _progressPercent / 100;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait<dynamic>([
        ApiService.getProfile(),
        ApiService.getProfileStats(),
        ApiService.getTodayXp(),
        ApiService.getAchievements(),
        ApiService.getMyQuests(),
        ApiService.getLeaderboard(),
        ApiService.getUserBoosters(),
      ]);

      final profile = _map(results[0]);
      final stats = _map(results[1]);
      final todayXp = _map(results[2]);
      final achievements = (results[3] as List<dynamic>?) ?? <dynamic>[];
      final quests = (results[4] as List<dynamic>?) ?? <dynamic>[];
      final leaderboard = (results[5] as List<dynamic>?) ?? <dynamic>[];
      final boostersRaw = (results[6] as List<dynamic>?) ?? <dynamic>[];

      final avatar = _map(profile['avatar']);
      final boosters = boostersRaw
          .map((dynamic b) => Booster.fromJson(_map(b)))
          .where((Booster b) => b.id != null)
          .toList(growable: false);

      final slotNames = <String?>[
        _string(avatar['boost1']).isEmpty ? null : _string(avatar['boost1']),
        _string(avatar['boost2']).isEmpty ? null : _string(avatar['boost2']),
        _string(avatar['boost3']).isEmpty ? null : _string(avatar['boost3']),
        _string(avatar['boost4']).isEmpty ? null : _string(avatar['boost4']),
      ];

      final slots = slotNames
          .map(
            (String? name) => name == null
                ? null
                : boosters
                      .where((Booster b) => b.name == name)
                      .cast<Booster?>()
                      .firstWhere(
                        (Booster? b) => b != null,
                        orElse: () => Booster.placeholder(name),
                      ),
          )
          .toList(growable: false);

      final unlockedAchievements = achievements
          .where((e) => _map(e)['unlocked'] == true)
          .length;
      final completedQuests = quests
          .where((e) => _map(e)['isCompleted'] == true)
          .length;

      String leaderboardRank = '-';
      final lowerName = _string(
        profile['userName'],
        fallback: _string(profile['UserName']),
      ).toLowerCase();
      for (var i = 0; i < leaderboard.length; i++) {
        final row = _map(leaderboard[i]);
        final rowName = _string(
          row['userName'],
          fallback: _string(row['UserName']),
        ).toLowerCase();
        if (rowName == lowerName) {
          final rank = _toInt(
            row['rank'],
            fallback: _toInt(row['Rank'], fallback: i + 1),
          );
          leaderboardRank = '#$rank';
          break;
        }
      }

      if (!mounted) return;
      setState(() {
        _userName = _string(
          profile['userName'],
          fallback: _string(profile['UserName'], fallback: 'Champion'),
        );
        _bodyStage = _normalizeBodyStage(
          _string(avatar['bodyStage'], fallback: 'Skinny'),
        );
        _level = _toInt(
          avatar['level'],
          fallback: _toInt(avatar['Level'], fallback: 1),
        );
        _currentXp = _toInt(
          avatar['experience'],
          fallback: _toInt(avatar['Experience']),
        );
        _xpForNextLevel = _toInt(
          avatar['xpForNextLevel'],
          fallback: _toInt(avatar['XpForNextLevel'], fallback: 1000),
        );

        _currentStreak = _toInt(stats['currentStreak']);
        _totalXp = _toInt(todayXp['totalXp']);
        _todayXp = _toInt(todayXp['todayXp']);
        _totalAchievements = achievements.length;
        _unlockedAchievements = unlockedAchievements;
        _totalQuests = quests.length;
        _completedQuests = completedQuests;
        _activeQuests = quests.length - completedQuests;
        _leaderboardRank = leaderboardRank;

        _ownedBoosters = boosters;
        for (int i = 0; i < 4; i++) {
          _boostSlots[i] = i < slots.length ? slots[i] : null;
        }

        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      widget.showSnack('Dashboard-Daten konnten nicht geladen werden.');
    }
  }

  int _availableQuantity(Booster booster, int selectedSlotIndex) {
    final usedElsewhere = _boostSlots
        .asMap()
        .entries
        .where(
          (entry) =>
              entry.key != selectedSlotIndex && entry.value?.id == booster.id,
        )
        .length;
    return booster.quantity - usedElsewhere;
  }

  Future<void> _saveSlotsAndRefresh(List<Booster?> slots) async {
    final ids = slots.map((Booster? b) => b?.id).toList(growable: false);
    await ApiService.updateBoostSlots(ids);
    if (!mounted) return;
    setState(() {
      for (int i = 0; i < 4; i++) {
        _boostSlots[i] = i < slots.length ? slots[i] : null;
      }
    });
    await widget.onRefreshHeader();
  }

  Future<void> _openBoosterModal(int slotIndex) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Booster auswaehlen',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Text(
                      'Slot ${slotIndex + 1}',
                      style: const TextStyle(
                        color: Color(0xFFA855F7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_ownedBoosters.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      'Keine Booster vorhanden. Kaufe Booster im Shop.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                else
                  ..._ownedBoosters.map((Booster booster) {
                    final available = _availableQuantity(booster, slotIndex);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: available <= 0
                            ? null
                            : () async {
                                final next = List<Booster?>.from(_boostSlots);
                                next[slotIndex] = booster;
                                await _saveSlotsAndRefresh(next);
                                if (context.mounted) Navigator.pop(context);
                              },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: available <= 0
                                ? Colors.white.withOpacity(0.03)
                                : const Color(0xFFA855F7).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: available <= 0
                                  ? Colors.white.withOpacity(0.08)
                                  : const Color(0xFFA855F7).withOpacity(0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Text('⚡', style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      booster.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '+${booster.bestBoostPercent}% Boost',
                                      style: const TextStyle(
                                        color: Color(0xFFC084FC),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${available}x',
                                style: const TextStyle(
                                  color: Color(0xFFA855F7),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                if (_boostSlots[slotIndex] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: TextButton.icon(
                      onPressed: () async {
                        final next = List<Booster?>.from(_boostSlots);
                        next[slotIndex] = null;
                        await _saveSlotsAndRefresh(next);
                        if (context.mounted) Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      label: const Text(
                        'Slot leeren',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEquipmentSlot(int index) {
    final booster = _boostSlots[index];
    final isEquipped = booster != null;

    return GestureDetector(
      onTap: widget.onOpenAvatar,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isEquipped
              ? const Color(0xFFA855F7).withOpacity(0.14)
              : const Color(0xFF0F172A).withOpacity(0.55),
          border: Border.all(
            color: isEquipped
                ? const Color(0xFFA855F7).withOpacity(0.45)
                : const Color(0xFFA855F7).withOpacity(0.25),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isEquipped ? '⚡' : '◈',
              style: TextStyle(
                fontSize: isEquipped ? 20 : 16,
                color: const Color(0xFFC084FC),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isEquipped ? booster.name : 'Booster',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(isEquipped ? 0.95 : 0.65),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            Text(
              isEquipped ? '+${booster.bestBoostPercent}%' : 'Leer',
              style: TextStyle(
                color: isEquipped ? const Color(0xFFC084FC) : Colors.white24,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final isSmall = MediaQuery.sizeOf(context).width < 410;

    return RefreshIndicator(
      onRefresh: () async {
        await _load();
        await widget.onRefreshHeader();
      },
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          isSmall ? 10 : 14,
          14,
          isSmall ? 10 : 14,
          20,
        ),
        children: [
          Stack(
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                top: 22,
                child: Container(
                  width: isSmall ? 280 : 370,
                  height: isSmall ? 320 : 440,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF2563EB).withOpacity(0.10),
                        const Color(0xFF0EA5E9).withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    _userName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.78),
                      fontSize: isSmall ? 16 : 20,
                      letterSpacing: isSmall ? 3.2 : 4.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          _buildEquipmentSlot(0),
                          const SizedBox(height: 10),
                          _buildEquipmentSlot(1),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Column(
                        children: [
                          SizedBox(
                            width: isSmall ? 176 : 242,
                            height: isSmall ? 198 : 256,
                            child: OverflowBox(
                              alignment: const Alignment(0, -0.45),
                              minWidth: 0,
                              minHeight: 0,
                              maxWidth: double.infinity,
                              maxHeight: double.infinity,
                              child: _SpriteAnimator(
                                stage: _bodyStage,
                                frameWidth: 128,
                                frameHeight: 128,
                                columns: 2,
                                frameCount: 4,
                                speed: const Duration(milliseconds: 1000),
                                scale: isSmall ? 2.52 : 3.34,
                              ),
                            ),
                          ),
                          Container(
                            width: isSmall ? 108 : 138,
                            height: 16,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF2563EB).withOpacity(0.62),
                                  const Color(0xFF2563EB).withOpacity(0.16),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Column(
                        children: [
                          _buildEquipmentSlot(2),
                          const SizedBox(height: 10),
                          _buildEquipmentSlot(3),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 220,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        CustomPaint(
                          size: const Size(220, 120),
                          painter: _XpArcPainter(progress: _arcProgress),
                        ),
                        Positioned(
                          bottom: 4,
                          child: Column(
                            children: [
                              Text(
                                '$_progressPercent%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                '${(_xpForNextLevel - _currentXp).clamp(0, 1 << 30)} bis Lv${_level + 1}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.35),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Level',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$_level',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 18,
                        color: Colors.white.withOpacity(0.08),
                        margin: const EdgeInsets.symmetric(horizontal: 18),
                      ),
                      Row(
                        children: [
                          Text(
                            'Gesamt XP',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatCompactNumber(_totalXp),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _DashBarItem(
                          icon: Icons.local_fire_department,
                          color: const Color(0xFFF97316),
                          value: '$_currentStreak Tage',
                          label: 'Streak',
                        ),
                      ),
                      Expanded(
                        child: _DashBarItem(
                          icon: Icons.emoji_events,
                          color: const Color(0xFFFBBF24),
                          value: '$_unlockedAchievements/$_totalAchievements',
                          label: 'Badges',
                        ),
                      ),
                      Expanded(
                        child: _DashBarItem(
                          icon: Icons.track_changes,
                          color: const Color(0xFFA855F7),
                          value: '$_completedQuests/$_totalQuests',
                          label: 'Quests',
                        ),
                      ),
                      Expanded(
                        child: _DashBarItem(
                          icon: Icons.military_tech,
                          color: const Color(0xFFEC4899),
                          value: _leaderboardRank,
                          label: 'Rang',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.06,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            children: [
              _DashStatCard(
                icon: Icons.local_fire_department,
                label: 'Streak',
                value: '$_currentStreak Tage',
                accent: const Color(0xFFF97316),
              ),
              _DashStatCard(
                icon: Icons.emoji_events,
                label: 'Achievements',
                value: '$_unlockedAchievements/$_totalAchievements',
                accent: const Color(0xFFFBBF24),
              ),
              _DashStatCard(
                icon: Icons.track_changes,
                label: 'Quests',
                value: '$_completedQuests/$_totalQuests',
                trend: '$_activeQuests aktiv',
                accent: const Color(0xFFA855F7),
              ),
              _DashStatCard(
                icon: Icons.trending_up,
                label: 'Gesamt XP',
                value: _formatCompactNumber(_totalXp),
                trend: '+${_formatCompactNumber(_todayXp)} XP heute',
                accent: const Color(0xFF22D3EE),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashBarItem extends StatelessWidget {
  const _DashBarItem({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _DashStatCard extends StatelessWidget {
  const _DashStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.trend,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? trend;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 170;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          padding: EdgeInsets.all(compact ? 14 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: accent, size: compact ? 28 : 32),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: compact ? 13 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 22 : 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (trend != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      trend!,
                      style: TextStyle(
                        color: accent,
                        fontSize: compact ? 12 : 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _XpArcPainter extends CustomPainter {
  _XpArcPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = math.min(size.width * 0.41, size.height * 0.82);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF3B82F6).withOpacity(0.18);

    final gradientPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    const start = math.pi;
    const sweep = math.pi;
    final activeSweep = sweep * progress.clamp(0, 1);

    canvas.drawArc(rect, start, sweep, false, backgroundPaint);
    canvas.drawArc(rect, start, activeSweep, false, gradientPaint);
  }

  @override
  bool shouldRepaint(covariant _XpArcPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _SpriteAnimator extends StatefulWidget {
  const _SpriteAnimator({
    required this.stage,
    required this.frameWidth,
    required this.frameHeight,
    required this.columns,
    required this.frameCount,
    required this.speed,
    required this.scale,
  });

  final String stage;
  final int frameWidth;
  final int frameHeight;
  final int columns;
  final int frameCount;
  final Duration speed;
  final double scale;

  @override
  State<_SpriteAnimator> createState() => _SpriteAnimatorState();
}

class _SpriteAnimatorState extends State<_SpriteAnimator> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ui.Image? _image;
  int _frame = 0;
  Timer? _timer;

  String get _assetPath {
    switch (_normalizeBodyStage(widget.stage)) {
      case 'Bodybuilder':
        return 'assets/Spritesheet_Bodybuilder.png';
      case 'Defined':
        return 'assets/Spritesheet_Normal.png';
      case 'Skinny':
      default:
        return 'assets/Spritesheet_Skinny.png';
    }
  }

  @override
  void initState() {
    super.initState();
    _resolveImage();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _SpriteAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stage != widget.stage) {
      _resolveImage();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.speed, (_) {
      if (!mounted) return;
      setState(() {
        _frame = (_frame + 1) % widget.frameCount;
      });
    });
  }

  void _resolveImage() {
    final provider = AssetImage(_assetPath);
    final stream = provider.resolve(const ImageConfiguration());

    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }

    _listener = ImageStreamListener((ImageInfo info, bool _) {
      if (!mounted) return;
      setState(() => _image = info.image);
    });

    stream.addListener(_listener!);
    _stream = stream;
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.frameWidth * widget.scale;
    final height = widget.frameHeight * widget.scale;

    return CustomPaint(
      size: Size(width, height),
      painter: _SpriteFramePainter(
        image: _image,
        frame: _frame,
        frameWidth: widget.frameWidth,
        frameHeight: widget.frameHeight,
        columns: widget.columns,
      ),
    );
  }
}

class _SpriteFramePainter extends CustomPainter {
  _SpriteFramePainter({
    required this.image,
    required this.frame,
    required this.frameWidth,
    required this.frameHeight,
    required this.columns,
  });

  final ui.Image? image;
  final int frame;
  final int frameWidth;
  final int frameHeight;
  final int columns;

  @override
  void paint(Canvas canvas, Size size) {
    if (image == null) return;

    final col = frame % columns;
    final row = frame ~/ columns;

    final src = Rect.fromLTWH(
      col * frameWidth.toDouble(),
      row * frameHeight.toDouble(),
      frameWidth.toDouble(),
      frameHeight.toDouble(),
    );

    final dst = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawImageRect(
      image!,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(covariant _SpriteFramePainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.frame != frame;
  }
}

class Booster {
  Booster({
    required this.id,
    required this.name,
    required this.quantity,
    required this.xpBoostPercentage,
    required this.coinBoostPercentage,
  });

  final int? id;
  final String name;
  final int quantity;
  final int xpBoostPercentage;
  final int coinBoostPercentage;

  int get bestBoostPercent =>
      xpBoostPercentage > 0 ? xpBoostPercentage : coinBoostPercentage;

  static Booster fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return Booster(
      id: json['id'] is int ? json['id'] as int : null,
      name: (json['name'] ?? '') as String,
      quantity: parseInt(json['quantity']),
      xpBoostPercentage: parseInt(json['xpBoostPercentage']),
      coinBoostPercentage: parseInt(json['coinBoostPercentage']),
    );
  }

  static Booster placeholder(String name) {
    return Booster(
      id: null,
      name: name,
      quantity: 1,
      xpBoostPercentage: 0,
      coinBoostPercentage: 0,
    );
  }
}

class _BoosterSelection {
  const _BoosterSelection._({this.booster, required this.clear});

  const _BoosterSelection.clear() : this._(clear: true);

  const _BoosterSelection.booster(this.booster) : clear = false;

  final Booster? booster;
  final bool clear;
}

class WorkoutsTab extends StatefulWidget {
  const WorkoutsTab({
    required this.onRefreshHeader,
    required this.showSnack,
    super.key,
  });

  final Future<void> Function() onRefreshHeader;
  final void Function(String) showSnack;

  @override
  State<WorkoutsTab> createState() => _WorkoutsTabState();
}

class _WorkoutsTabState extends State<WorkoutsTab> {
  bool _loading = true;
  List<dynamic> _workouts = <dynamic>[];
  List<dynamic> _exercises = <dynamic>[];
  Map<String, dynamic> _profileStats = <String, dynamic>{};
  Map<String, dynamic> _todayActivity = <String, dynamic>{};
  String _activeFilter = 'Alle';
  final Map<int, int> _repsDraft = <int, int>{};
  final Set<int> _expandedRepEditors = <int>{};
  bool _showCreateWorkoutForm = false;
  bool _creatingWorkout = false;
  final TextEditingController _newWorkoutNameController =
      TextEditingController();
  final TextEditingController _newWorkoutDescriptionController =
      TextEditingController();
  int? _newWorkoutCategory;
  List<Map<String, int>> _newWorkoutExercises = <Map<String, int>>[
    <String, int>{'exerciseId': 0, 'dailyLimit': 50},
  ];

  static const List<String> _filters = <String>[
    'Alle',
    'Cardio',
    'Strength',
    'Core',
    'Flexibility',
  ];

  List<dynamic> get _filteredExercises {
    if (_activeFilter == 'Alle') return _exercises;
    return _exercises
        .where((dynamic item) {
          final m = _map(item);
          return _categoryLabel(m['category']) == _activeFilter;
        })
        .toList(growable: false);
  }

  List<dynamic> get _filteredWorkouts {
    if (_activeFilter == 'Alle') return _workouts;
    return _workouts
        .where((dynamic item) {
          final m = _map(item);
          return _categoryLabel(m['category']) == _activeFilter;
        })
        .toList(growable: false);
  }

  int get _todayReps {
    return _exercises.fold<int>(0, (int sum, dynamic e) {
      final m = _map(e);
      return sum + _toInt(m['todayCount']);
    });
  }

  int get _todayXp {
    return _exercises.fold<int>(0, (int sum, dynamic e) {
      final m = _map(e);
      final reps = _toInt(m['todayCount']);
      final xpPerRep = _toInt(m['xpPerRep'], fallback: 1);
      return sum + (reps * xpPerRep);
    });
  }

  int get _totalReps {
    return _toInt(_profileStats['totalExercises'], fallback: _todayReps);
  }

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _newWorkoutNameController.dispose();
    _newWorkoutDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait<dynamic>([
        ApiService.getWorkouts(),
        ApiService.getExercises(),
        ApiService.getProfileStats(),
        ApiService.getTodayActivity(),
      ]);

      final workouts = (results[0] as List<dynamic>?) ?? <dynamic>[];
      final exercises = (results[1] as List<dynamic>?) ?? <dynamic>[];
      final profileStats = _map(results[2]);
      final todayActivity = _map(results[3]);

      if (!mounted) return;
      setState(() {
        _workouts = workouts;
        _exercises = exercises;
        _profileStats = profileStats;
        _todayActivity = todayActivity;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      widget.showSnack('Workouts konnten nicht geladen werden.');
    }
  }

  int _remainingFor(Map<String, dynamic> exercise) {
    final dailyLimit = _toInt(exercise['dailyLimit'], fallback: 300);
    final todayCount = _toInt(exercise['todayCount']);
    final remaining = dailyLimit - todayCount;
    return remaining < 0 ? 0 : remaining;
  }

  int _draftFor(Map<String, dynamic> exercise) {
    final id = _toInt(exercise['id']);
    if (id == 0) return 10;
    final remaining = _remainingFor(exercise);
    if (remaining <= 0) return 0;
    return _repsDraft[id] ?? (remaining < 10 ? remaining : 10);
  }

  void _changeDraft(dynamic exercise, int delta) {
    final map = _map(exercise);
    final id = _toInt(map['id']);
    if (id == 0) return;
    final remaining = _remainingFor(map);
    if (remaining <= 0) return;
    final current = _draftFor(map);
    final next = (current + delta).clamp(1, remaining);
    setState(() {
      _repsDraft[id] = next;
    });
  }

  Future<void> _logExerciseWithReps(dynamic exercise, int reps) async {
    final map = _map(exercise);
    final id = _toInt(map['id']);
    if (id == 0 || reps <= 0) return;
    try {
      await ApiService.logExercise(exerciseId: id, reps: reps);
      if (!mounted) return;
      setState(() {
        map['todayCount'] = _toInt(map['todayCount']) + reps;
        final remaining = _remainingFor(map);
        _repsDraft[id] = remaining <= 0
            ? 0
            : (remaining < reps ? remaining : reps);
        _expandedRepEditors.remove(id);
      });

      widget.showSnack('$reps Reps eingetragen.');
      await widget.onRefreshHeader();
    } catch (_) {
      widget.showSnack('Exercise-Log fehlgeschlagen.');
    }
  }

  bool _isRepEditorOpen(int id) => _expandedRepEditors.contains(id);

  void _openRepEditor(int id) {
    if (id == 0) return;
    setState(() {
      _expandedRepEditors.add(id);
    });
  }

  void _closeRepEditor(int id) {
    setState(() {
      _expandedRepEditors.remove(id);
    });
  }

  List<Map<String, dynamic>> get _exerciseOptions {
    return _exercises
        .map((dynamic e) {
          final m = _map(e);
          final id = _toInt(m['id']);
          if (id == 0) return null;
          return <String, dynamic>{
            'id': id,
            'name': _string(m['name'], fallback: 'Übung $id'),
          };
        })
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  void _resetCreateWorkoutForm() {
    _newWorkoutNameController.clear();
    _newWorkoutDescriptionController.clear();
    _newWorkoutCategory = null;
    _newWorkoutExercises = <Map<String, int>>[
      <String, int>{'exerciseId': 0, 'dailyLimit': 50},
    ];
  }

  void _openCreateWorkoutForm() {
    setState(() {
      _showCreateWorkoutForm = true;
      _resetCreateWorkoutForm();
    });
  }

  void _closeCreateWorkoutForm() {
    setState(() {
      _showCreateWorkoutForm = false;
      _resetCreateWorkoutForm();
    });
  }

  void _addWorkoutExerciseRow() {
    setState(() {
      _newWorkoutExercises.add(<String, int>{
        'exerciseId': 0,
        'dailyLimit': 50,
      });
    });
  }

  void _removeWorkoutExerciseRow(int index) {
    if (_newWorkoutExercises.length <= 1) return;
    setState(() {
      _newWorkoutExercises.removeAt(index);
    });
  }

  void _setWorkoutExerciseId(int index, int? exerciseId) {
    setState(() {
      _newWorkoutExercises[index]['exerciseId'] = exerciseId ?? 0;
    });
  }

  void _changeWorkoutDailyLimit(int index, int delta) {
    final current = _newWorkoutExercises[index]['dailyLimit'] ?? 1;
    final next = (current + delta).clamp(1, 9999);
    setState(() {
      _newWorkoutExercises[index]['dailyLimit'] = next;
    });
  }

  Future<void> _createWorkout() async {
    if (_creatingWorkout) return;

    final name = _newWorkoutNameController.text.trim();
    if (name.isEmpty) {
      widget.showSnack('Bitte gib einen Workout-Namen ein.');
      return;
    }

    final category = _newWorkoutCategory;
    if (category == null) {
      widget.showSnack('Bitte wähle eine Kategorie.');
      return;
    }

    final selectedExercises = _newWorkoutExercises
        .where((row) => (row['exerciseId'] ?? 0) > 0)
        .map(
          (row) => <String, dynamic>{
            'exerciseId': row['exerciseId'],
            'dailyLimit': row['dailyLimit'] ?? 50,
          },
        )
        .toList(growable: false);

    if (selectedExercises.isEmpty) {
      widget.showSnack('Bitte mindestens eine Übung hinzufügen.');
      return;
    }

    setState(() => _creatingWorkout = true);
    try {
      await ApiService.createWorkout(<String, dynamic>{
        'name': name,
        'description': _newWorkoutDescriptionController.text.trim().isEmpty
            ? null
            : _newWorkoutDescriptionController.text.trim(),
        'category': category,
        'exercises': selectedExercises,
      });

      if (!mounted) return;
      setState(() {
        _creatingWorkout = false;
        _showCreateWorkoutForm = false;
        _resetCreateWorkoutForm();
      });
      widget.showSnack('Workout erstellt.');
      await _load();
    } catch (_) {
      if (!mounted) return;
      setState(() => _creatingWorkout = false);
      widget.showSnack('Workout konnte nicht erstellt werden.');
    }
  }

  String _categoryLabel(dynamic raw) {
    if (raw is int) {
      switch (raw) {
        case 0:
          return 'Strength';
        case 1:
          return 'Core';
        case 2:
          return 'Cardio';
        case 3:
          return 'Flexibility';
        default:
          return 'Strength';
      }
    }

    final s = _string(raw).toLowerCase();
    if (s == 'cardio') return 'Cardio';
    if (s == 'core') return 'Core';
    if (s == 'flexibility') return 'Flexibility';
    return 'Strength';
  }

  String _difficultyLabel(dynamic raw) {
    if (raw is int) {
      switch (raw) {
        case 0:
          return 'Easy';
        case 2:
          return 'Hard';
        default:
          return 'Medium';
      }
    }

    final s = _string(raw).toLowerCase();
    if (s == 'easy') return 'Easy';
    if (s == 'hard') return 'Hard';
    return 'Medium';
  }

  Color _categoryBg(String category) {
    switch (category) {
      case 'Cardio':
        return const Color(0xFFEF4444).withOpacity(0.16);
      case 'Core':
        return const Color(0xFFEC4899).withOpacity(0.16);
      case 'Flexibility':
        return const Color(0xFF22C55E).withOpacity(0.16);
      case 'Strength':
      default:
        return const Color(0xFFA855F7).withOpacity(0.16);
    }
  }

  Color _categoryBorder(String category) {
    switch (category) {
      case 'Cardio':
        return const Color(0xFFEF4444).withOpacity(0.45);
      case 'Core':
        return const Color(0xFFEC4899).withOpacity(0.45);
      case 'Flexibility':
        return const Color(0xFF22C55E).withOpacity(0.45);
      case 'Strength':
      default:
        return const Color(0xFFA855F7).withOpacity(0.45);
    }
  }

  Color _categoryText(String category) {
    switch (category) {
      case 'Cardio':
        return const Color(0xFFFCA5A5);
      case 'Core':
        return const Color(0xFFF9A8D4);
      case 'Flexibility':
        return const Color(0xFF86EFAC);
      case 'Strength':
      default:
        return const Color(0xFFC4B5FD);
    }
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return const Color(0xFF86EFAC);
      case 'Hard':
        return const Color(0xFFFCA5A5);
      case 'Medium':
      default:
        return const Color(0xFFFDE047);
    }
  }

  Widget _buildStatPill({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 17, color: accent),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.64),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthMetricCard({
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withOpacity(0.045),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(CupertinoIcons.flame_fill, color: iconColor, size: 18),
            const SizedBox(height: 10),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.58),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text(
            'Deine Übungen',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Wähle eine Übung und trage deine Wiederholungen ein.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withOpacity(0.04),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                _buildStatPill(
                  icon: Icons.today,
                  label: 'Heute',
                  value: '$_todayReps Reps',
                  accent: const Color(0xFF60A5FA),
                ),
                const SizedBox(width: 10),
                _buildStatPill(
                  icon: Icons.stacked_bar_chart,
                  label: 'Gesamt',
                  value: '$_totalReps Reps',
                  accent: const Color(0xFFA855F7),
                ),
                const SizedBox(width: 10),
                _buildStatPill(
                  icon: Icons.bolt,
                  label: 'XP Heute',
                  value: '+${_formatCompactNumber(_todayXp)} XP',
                  accent: const Color(0xFFFBBF24),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildHealthMetricCard(
                iconColor: const Color(0xFFFF6B1A),
                label: 'Schritte heute',
                value: '${_toInt(_todayActivity['steps'])}',
              ),
              const SizedBox(width: 10),
              _buildHealthMetricCard(
                iconColor: const Color(0xFFFF6B1A),
                label: 'Kilometer heute',
                value:
                    '${_toDouble(_todayActivity['kilometers']).toStringAsFixed(1)} km',
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters
                  .map((String filter) {
                    final isActive = _activeFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => _activeFilter = filter),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: isActive
                                ? const Color(0xFFEC4899).withOpacity(0.26)
                                : Colors.white.withOpacity(0.05),
                            border: Border.all(
                              color: isActive
                                  ? const Color(0xFFEC4899).withOpacity(0.55)
                                  : Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: 16),
          ..._filteredExercises.map((dynamic e) {
            final m = _map(e);
            final exerciseId = _toInt(m['id']);
            final category = _categoryLabel(m['category']);
            final difficulty = _difficultyLabel(m['difficulty']);
            final xpPerRep = _toInt(m['xpPerRep'], fallback: 1);
            final remaining = _remainingFor(m);
            final repsDraft = _draftFor(m);
            final editorOpen = _isRepEditorOpen(exerciseId);
            final desc = _string(
              m['description'],
              fallback: 'Führe die Übung sauber und kontrolliert aus.',
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white.withOpacity(0.06),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: _categoryBg(category),
                            border: Border.all(
                              color: _categoryBorder(category),
                            ),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: _categoryText(category),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (editorOpen) ...[
                          const Spacer(),
                          IconButton(
                            onPressed: () => _closeRepEditor(exerciseId),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white70,
                              size: 20,
                            ),
                            tooltip: 'Zurück',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.06),
                              minimumSize: const Size(36, 36),
                              fixedSize: const Size(36, 36),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _string(m['name'], fallback: 'Exercise'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      desc,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.62),
                        height: 1.4,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          difficulty,
                          style: TextStyle(
                            color: _difficultyColor(difficulty),
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            shadows: [
                              Shadow(
                                color: _difficultyColor(
                                  difficulty,
                                ).withOpacity(0.55),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Icon(
                          Icons.bolt,
                          size: 14,
                          color: Color(0xFFFBBF24),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+${_formatCompactNumber(xpPerRep)} XP',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (remaining <= 0)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white.withOpacity(0.05),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: const Text(
                          'Tageslimit erreicht',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else if (!editorOpen)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _openRepEditor(exerciseId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
                              ),
                            ),
                            child: const SizedBox(
                              height: 46,
                              child: Center(
                                child: Text(
                                  'Training eintragen',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 46,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.white.withOpacity(0.05),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.12),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        onPressed: () => _changeDraft(e, -1),
                                        icon: const Icon(
                                          Icons.remove,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '$repsDraft Reps',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => _changeDraft(e, 1),
                                        icon: const Icon(
                                          Icons.add,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 132,
                                child: ElevatedButton(
                                  onPressed: () =>
                                      _logExerciseWithReps(e, repsDraft),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFEC4899),
                                          Color(0xFFF43F5E),
                                        ],
                                      ),
                                    ),
                                    child: const SizedBox(
                                      height: 46,
                                      child: Center(
                                        child: Text(
                                          'Eintragen',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Noch $remaining Wiederholungen möglich heute',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withOpacity(0.06),
              border: Border.all(
                color: const Color(0xFFEC4899).withOpacity(0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Erstelle dein eigenes Workout',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kombiniere Übungen und verdiene Bonus-XP',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                if (!_showCreateWorkoutForm)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _openCreateWorkoutForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
                          ),
                        ),
                        child: const SizedBox(
                          height: 46,
                          child: Center(
                            child: Text(
                              'Workout erstellen',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else ...[
                  TextField(
                    controller: _newWorkoutNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Name',
                      hintText: 'z.B. Oberkörper Power',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                      ),
                      labelStyle: TextStyle(
                        color: Colors.white.withOpacity(0.78),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.16),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.16),
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: Color(0xFFEC4899)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _newWorkoutDescriptionController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Beschreibung',
                      hintText: 'Optional',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                      ),
                      labelStyle: TextStyle(
                        color: Colors.white.withOpacity(0.78),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.16),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.16),
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: Color(0xFFEC4899)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: _newWorkoutCategory,
                    dropdownColor: const Color(0xFF1F1B2E),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Kategorie',
                      labelStyle: TextStyle(
                        color: Colors.white.withOpacity(0.78),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.16),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.16),
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: Color(0xFFEC4899)),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem<int>(value: 0, child: Text('Strength')),
                      DropdownMenuItem<int>(value: 1, child: Text('Core')),
                      DropdownMenuItem<int>(value: 2, child: Text('Cardio')),
                      DropdownMenuItem<int>(
                        value: 3,
                        child: Text('Flexibility'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _newWorkoutCategory = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Übungen',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._newWorkoutExercises.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final row = entry.value;
                    final selectedExerciseId = row['exerciseId'];
                    final dailyLimit = row['dailyLimit'] ?? 50;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white.withOpacity(0.04),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<int>(
                              value: selectedExerciseId == 0
                                  ? null
                                  : selectedExerciseId,
                              dropdownColor: const Color(0xFF1F1B2E),
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Übung wählen',
                                labelStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.72),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.04),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.14),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.14),
                                  ),
                                ),
                              ),
                              items: _exerciseOptions
                                  .map(
                                    (option) => DropdownMenuItem<int>(
                                      value: option['id'] as int,
                                      child: Text(option['name'] as String),
                                    ),
                                  )
                                  .toList(growable: false),
                              onChanged: (value) =>
                                  _setWorkoutExerciseId(idx, value),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Limit: $dailyLimit',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      _changeWorkoutDailyLimit(idx, -1),
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.white,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      _changeWorkoutDailyLimit(idx, 1),
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.white,
                                  ),
                                ),
                                if (_newWorkoutExercises.length > 1)
                                  IconButton(
                                    onPressed: () =>
                                        _removeWorkoutExerciseRow(idx),
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white70,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _addWorkoutExerciseRow,
                      icon: const Icon(Icons.add, color: Color(0xFFF9A8D4)),
                      label: const Text(
                        'Übung hinzufügen',
                        style: TextStyle(color: Color(0xFFF9A8D4)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _creatingWorkout
                              ? null
                              : _closeCreateWorkoutForm,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.24),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Abbrechen',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _creatingWorkout ? null : _createWorkout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEC4899),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            _creatingWorkout ? 'Erstelle...' : 'Erstellen',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (_filteredWorkouts.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              'Deine Workouts',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            ..._filteredWorkouts.map((dynamic w) {
              final m = _map(w);
              final category = _categoryLabel(m['category']);
              final exCount = (m['exercises'] as List<dynamic>?)?.length ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: _categoryBg(category),
                          border: Border.all(color: _categoryBorder(category)),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: _categoryText(category),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _string(
                                m['name'],
                                fallback: _string(
                                  m['title'],
                                  fallback: 'Workout',
                                ),
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$exCount Übungen',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class QuestsTab extends StatefulWidget {
  const QuestsTab({
    required this.onRefreshHeader,
    required this.showSnack,
    super.key,
  });

  final Future<void> Function() onRefreshHeader;
  final void Function(String) showSnack;

  @override
  State<QuestsTab> createState() => _QuestsTabState();
}

class _QuestsTabState extends State<QuestsTab> {
  bool _loading = true;
  List<dynamic> _quests = <dynamic>[];
  Map<String, dynamic> _stats = <String, dynamic>{};

  List<dynamic> get _dailyQuests => _quests
      .where((dynamic q) => _questType(_map(q)) == 'daily')
      .toList(growable: false);

  List<dynamic> get _weeklyQuests => _quests
      .where((dynamic q) => _questType(_map(q)) == 'weekly')
      .toList(growable: false);

  List<dynamic> get _monthlyQuests => _quests
      .where((dynamic q) => _questType(_map(q)) == 'monthly')
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load({bool showLoader = true}) async {
    if (showLoader) {
      setState(() => _loading = true);
    }
    try {
      try {
        final healthResult = await HealthSyncService.syncIfEnabled();
        if (healthResult?.hasRewards == true) {
          await widget.onRefreshHeader();
        }
      } catch (_) {
        // Keep the quests screen usable even if Health sync is temporarily unavailable.
      }

      final results = await Future.wait<dynamic>([
        ApiService.getMyQuests(),
        ApiService.getQuestStats(),
      ]);
      if (!mounted) return;
      setState(() {
        _quests = results[0] as List<dynamic>;
        _stats = _map(results[1]);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (showLoader) {
        setState(() => _loading = false);
      }
      widget.showSnack('Quest-Daten konnten nicht geladen werden.');
    }
  }

  Future<void> _claim(int userQuestId) async {
    try {
      await ApiService.claimQuestReward(userQuestId);
      widget.showSnack('Belohnung eingesammelt.');
      await _load(showLoader: false);
      await widget.onRefreshHeader();
    } catch (_) {
      widget.showSnack('Belohnung konnte nicht eingesammelt werden.');
    }
  }

  String _questType(Map<String, dynamic> quest) {
    return _string(quest['type']).toLowerCase();
  }

  String _questRarity(Map<String, dynamic> quest) {
    final rarity = _string(quest['rarity'], fallback: 'Common');
    return rarity.isEmpty ? 'Common' : rarity;
  }

  String _questName(Map<String, dynamic> quest) {
    return _string(
      quest['name'],
      fallback: _string(quest['title'], fallback: 'Quest'),
    );
  }

  int _questProgress(Map<String, dynamic> quest) {
    return _toInt(quest['progress']);
  }

  int _questTarget(Map<String, dynamic> quest) {
    return _toInt(quest['targetValue'], fallback: 1);
  }

  int _questPercent(Map<String, dynamic> quest) {
    final target = _questTarget(quest);
    if (target <= 0) return 0;
    final pct = ((_questProgress(quest) / target) * 100).round();
    return pct.clamp(0, 100);
  }

  Color _rarityAccent(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'rare':
        return const Color(0xFF60A5FA);
      case 'epic':
        return const Color(0xFFA855F7);
      case 'legendary':
        return const Color(0xFFFBBF24);
      case 'common':
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  Color _sectionAccent(String type) {
    switch (type) {
      case 'weekly':
        return const Color(0xFF60A5FA);
      case 'monthly':
        return const Color(0xFFFBBF24);
      case 'daily':
      default:
        return const Color(0xFFEC4899);
    }
  }

  Widget _buildQuestStatPill({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 17, color: accent),
            const SizedBox(height: 7),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.64),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestSection({
    required String title,
    required String icon,
    required String type,
    required List<dynamic> quests,
  }) {
    if (quests.isEmpty) return const SizedBox.shrink();

    final accent = _sectionAccent(type);
    final first = _map(quests.first);
    final timeLeft = _string(first['timeLeft']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Row(
          children: [
            Text(
              '$icon $title',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            const Spacer(),
            if (timeLeft.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: accent.withOpacity(0.16),
                  border: Border.all(color: accent.withOpacity(0.42)),
                ),
                child: Text(
                  timeLeft,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        ...quests.map((dynamic q) {
          final m = _map(q);
          final id = _toInt(m['id']);
          final rarity = _questRarity(m);
          final rarityAccent = _rarityAccent(rarity);
          final progress = _questProgress(m);
          final target = _questTarget(m);
          final percent = _questPercent(m);
          final isCompleted = (m['isCompleted'] as bool?) == true;
          final rewardClaimed = (m['isRewardClaimed'] as bool?) == true;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withOpacity(0.06),
                border: Border.all(
                  color: isCompleted
                      ? const Color(0xFF22C55E).withOpacity(0.44)
                      : rarityAccent.withOpacity(0.34),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: rarityAccent.withOpacity(0.16),
                          border: Border.all(
                            color: rarityAccent.withOpacity(0.44),
                          ),
                        ),
                        child: Text(
                          rarity,
                          style: TextStyle(
                            color: rarityAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _string(m['timeLeft']),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.58),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _questName(m),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _string(m['description'], fallback: 'Quest Beschreibung'),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.64),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '$progress / $target',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$percent%',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.62),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: percent / 100,
                      minHeight: 8,
                      backgroundColor: Colors.black.withOpacity(0.24),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFEC4899),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '+${_formatCompactNumber(_toInt(m['xpReward']))} XP',
                        style: const TextStyle(
                          color: Color(0xFFFBBF24),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_toInt(m['coinReward']) > 0)
                        Text(
                          '+${_formatCompactNumber(_toInt(m['coinReward']))} Coins',
                          style: const TextStyle(
                            color: Color(0xFFF59E0B),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      const Spacer(),
                      if (isCompleted && !rewardClaimed)
                        ElevatedButton(
                          onPressed: id == 0 ? null : () => _claim(id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                              ),
                            ),
                            child: const SizedBox(
                              height: 36,
                              width: 102,
                              child: Center(
                                child: Text(
                                  'Einfordern',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      else if (rewardClaimed)
                        const Text(
                          'Erhalten',
                          style: TextStyle(
                            color: Color(0xFF22C55E),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          const Text(
            'Quest Log',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Schließe Quests ab und sammle epische Belohnungen.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withOpacity(0.04),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                _buildQuestStatPill(
                  icon: Icons.emoji_events,
                  label: 'Abgeschl.',
                  value: '${_toInt(_stats['completed'])}',
                  accent: const Color(0xFFFBBF24),
                ),
                const SizedBox(width: 10),
                _buildQuestStatPill(
                  icon: Icons.flash_on,
                  label: 'Aktiv',
                  value: '${_toInt(_stats['active'])}',
                  accent: const Color(0xFF60A5FA),
                ),
                const SizedBox(width: 10),
                _buildQuestStatPill(
                  icon: Icons.auto_awesome,
                  label: 'Verdient',
                  value:
                      '${_formatCompactNumber(_toInt(_stats['totalXpEarned']))} XP',
                  accent: const Color(0xFFEC4899),
                ),
              ],
            ),
          ),
          _buildQuestSection(
            title: 'Tägliche Quests',
            icon: '🔥',
            type: 'daily',
            quests: _dailyQuests,
          ),
          _buildQuestSection(
            title: 'Wöchentliche Quests',
            icon: '🎯',
            type: 'weekly',
            quests: _weeklyQuests,
          ),
          _buildQuestSection(
            title: 'Monatliche Quests',
            icon: '🏆',
            type: 'monthly',
            quests: _monthlyQuests,
          ),
          if (_quests.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                'Keine Quests verfügbar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.68)),
              ),
            ),
        ],
      ),
    );
  }
}

class AvatarTab extends StatefulWidget {
  const AvatarTab({
    required this.onRefreshHeader,
    required this.showSnack,
    super.key,
  });

  final Future<void> Function() onRefreshHeader;
  final void Function(String) showSnack;

  @override
  State<AvatarTab> createState() => _AvatarTabState();
}

class _AvatarTabState extends State<AvatarTab> {
  bool _loading = true;
  Map<String, dynamic> _profile = <String, dynamic>{};
  List<Booster> _inventory = <Booster>[];
  final List<Booster?> _slots = <Booster?>[null, null, null, null];
  Booster? _selectingSlotFor;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait<dynamic>([
        ApiService.getProfile(),
        ApiService.getUserBoosters(),
      ]);
      if (!mounted) return;

      final profile = _map(results[0]);
      final boostersRaw = (results[1] as List<dynamic>?) ?? <dynamic>[];
      final boosters = boostersRaw
          .map((dynamic b) => Booster.fromJson(_map(b)))
          .where((Booster b) => b.id != null)
          .toList(growable: false);

      final avatar = _map(profile['avatar']);
      final slotNames = <String?>[
        _slotName(avatar['boost1']),
        _slotName(avatar['boost2']),
        _slotName(avatar['boost3']),
        _slotName(avatar['boost4']),
      ];

      final nextSlots = List<Booster?>.filled(4, null, growable: false);
      for (int i = 0; i < 4; i++) {
        final name = i < slotNames.length ? slotNames[i] : null;
        if (name == null) continue;
        nextSlots[i] =
            _findBoosterByName(boosters, name) ?? Booster.placeholder(name);
      }

      setState(() {
        _profile = profile;
        _inventory = boosters;
        for (int i = 0; i < 4; i++) {
          _slots[i] = nextSlots[i];
        }
        _selectingSlotFor = null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      widget.showSnack('Avatar-Daten konnten nicht geladen werden.');
    }
  }

  String? _slotName(dynamic raw) {
    final s = _string(raw);
    return s.isEmpty ? null : s;
  }

  Booster? _findBoosterByName(List<Booster> list, String name) {
    for (final booster in list) {
      if (booster.name == name) return booster;
    }
    return null;
  }

  String _rarityOf(Booster booster) {
    final total = booster.xpBoostPercentage + booster.coinBoostPercentage;
    if (total >= 60) return 'legendary';
    if (total >= 40) return 'epic';
    if (total >= 20) return 'rare';
    return 'common';
  }

  String _boosterIcon(Booster booster) {
    final xp = booster.xpBoostPercentage;
    final coin = booster.coinBoostPercentage;
    if (xp > 0 && coin > 0) return '🔥';
    if (coin > 0) return '🪙';
    return '⚡';
  }

  int _equippedCount(int? boosterId) {
    if (boosterId == null) return 0;
    return _slots.where((Booster? b) => b?.id == boosterId).length;
  }

  bool _isEquipped(int? boosterId) => _equippedCount(boosterId) > 0;

  bool _canEquipMore(Booster booster) {
    return _equippedCount(booster.id) < booster.quantity;
  }

  int _availableQuantityForSlot(int slotIndex, Booster booster) {
    final equippedElsewhere = _slots
        .asMap()
        .entries
        .where(
          (entry) => entry.key != slotIndex && entry.value?.id == booster.id,
        )
        .length;
    return booster.quantity - equippedElsewhere;
  }

  int get _totalXpBoost =>
      _slots.fold<int>(0, (sum, slot) => sum + (slot?.xpBoostPercentage ?? 0));

  int get _totalCoinBoost => _slots.fold<int>(
    0,
    (sum, slot) => sum + (slot?.coinBoostPercentage ?? 0),
  );

  Future<void> _persistSlots(List<Booster?> oldSlots) async {
    final ids = _slots.map((Booster? b) => b?.id).toList(growable: false);
    try {
      await ApiService.updateBoostSlots(ids);
      await widget.onRefreshHeader();
      widget.showSnack('Booster-Slots gespeichert.');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        for (int i = 0; i < 4; i++) {
          _slots[i] = oldSlots[i];
        }
      });
      widget.showSnack('Booster-Slots konnten nicht gespeichert werden.');
    }
  }

  Future<void> _handleSlotTap(int index) async {
    if (index < 0 || index >= _slots.length) return;

    await _openBoosterModal(index);
  }

  Future<void> _openBoosterModal(int slotIndex) async {
    if (_inventory.isEmpty) {
      widget.showSnack('Keine Booster vorhanden. Kaufe Booster im Shop.');
      return;
    }

    final previous = List<Booster?>.from(_slots);
    final current = _slots[slotIndex];

    final selected = await showModalBottomSheet<_BoosterSelection?>(
      context: context,
      backgroundColor: const Color(0xFF0B1220),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (BuildContext modalContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Booster auswaehlen',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Text(
                      'Slot ${slotIndex + 1}',
                      style: const TextStyle(
                        color: Color(0xFFC084FC),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  current == null
                      ? 'Wähle einen Booster aus deinem Inventar.'
                      : 'Aktuell ausgerüstet: ${current.name}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.68),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 420),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _inventory.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final canClear = current != null;
                        return InkWell(
                          onTap: canClear
                              ? () => Navigator.pop(
                                  modalContext,
                                  const _BoosterSelection.clear(),
                                )
                              : null,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: canClear
                                  ? Colors.white.withOpacity(0.04)
                                  : Colors.white.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: canClear
                                    ? Colors.white.withOpacity(0.08)
                                    : Colors.white.withOpacity(0.05),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.white.withOpacity(0.05),
                                  ),
                                  child: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.white54,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Slot leeren',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final booster = _inventory[index - 1];
                      final available = _availableQuantityForSlot(
                        slotIndex,
                        booster,
                      );
                      final isCurrent = current?.id == booster.id;

                      return InkWell(
                        onTap: available > 0 || isCurrent
                            ? () => Navigator.pop(
                                modalContext,
                                _BoosterSelection.booster(booster),
                              )
                            : null,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: available > 0 || isCurrent
                                ? const Color(0xFFA855F7).withOpacity(0.12)
                                : Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: available > 0 || isCurrent
                                  ? const Color(0xFFA855F7).withOpacity(0.3)
                                  : Colors.white.withOpacity(0.06),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white.withOpacity(0.05),
                                ),
                                child: Text(
                                  _boosterIcon(booster),
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      booster.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'XP +${booster.xpBoostPercentage}% • Coins +${booster.coinBoostPercentage}%',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.62),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                isCurrent
                                    ? 'Aktiv'
                                    : '$available/${booster.quantity}',
                                style: TextStyle(
                                  color: available > 0 || isCurrent
                                      ? const Color(0xFFC084FC)
                                      : const Color(0xFFFCA5A5),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) return;

    setState(() {
      _slots[slotIndex] = selected.clear ? null : selected.booster;
      _selectingSlotFor = null;
    });
    await _persistSlots(previous);
  }

  Future<void> _unequipBoosterById(int? boosterId) async {
    if (boosterId == null) return;
    final previous = List<Booster?>.from(_slots);
    final index = _slots.indexWhere((Booster? b) => b?.id == boosterId);
    if (index < 0) return;
    setState(() {
      _slots[index] = null;
    });
    await _persistSlots(previous);
  }

  Widget _buildBoostCard({
    required IconData icon,
    required String label,
    required int value,
    required List<Color> barGradient,
    required Color iconColor,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 165;
        final iconBoxSize = compact ? 28.0 : 32.0;
        final horizontalPadding = compact ? 9.0 : 12.0;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: Colors.white.withOpacity(0.09)),
          ),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            compact ? 10 : 12,
            horizontalPadding,
            10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: iconBoxSize,
                    height: iconBoxSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: iconColor.withOpacity(0.14),
                      border: Border.all(color: iconColor.withOpacity(0.35)),
                    ),
                    child: label == 'XP Boost'
                        ? Padding(
                            padding: EdgeInsets.all(compact ? 6 : 7),
                            child: Image.asset(
                              'assets/XP_Pixel.png',
                              fit: BoxFit.contain,
                            ),
                          )
                        : label == 'Coin Boost'
                        ? Padding(
                            padding: EdgeInsets.all(compact ? 5 : 6),
                            child: Image.asset(
                              'assets/SYBAU_Coin.png',
                              fit: BoxFit.contain,
                            ),
                          )
                        : Icon(icon, color: iconColor, size: compact ? 15 : 17),
                  ),
                  SizedBox(width: compact ? 6 : 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            label,
                            maxLines: 1,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '+$value%',
                            maxLines: 1,
                            style: TextStyle(
                              color: value > 0
                                  ? const Color(0xFF34D399)
                                  : Colors.white.withOpacity(0.32),
                              fontSize: compact ? 17 : 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 4,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(color: Colors.white.withOpacity(0.06)),
                      FractionallySizedBox(
                        widthFactor: (value / 100).clamp(0.0, 1.0),
                        alignment: Alignment.centerLeft,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: barGradient),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEquipSlot(int index, {double size = 82}) {
    final item = _slots[index];
    final isFilled = item != null;
    final iconSize = size * 0.24;
    final titleSize = size * 0.12;
    final valueSize = size * 0.11;

    return GestureDetector(
      onTap: () => _handleSlotTap(index),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isFilled
              ? const Color(0xFFA855F7).withOpacity(0.14)
              : const Color(0xFF0F172A).withOpacity(0.52),
          border: Border.all(
            color: isFilled
                ? const Color(0xFFA855F7).withOpacity(0.45)
                : const Color(0xFFA855F7).withOpacity(0.28),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isFilled ? _boosterIcon(item) : '⚡',
              style: TextStyle(fontSize: iconSize),
            ),
            SizedBox(height: size * 0.05),
            Text(
              isFilled ? item.name : 'Booster',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(isFilled ? 0.95 : 0.58),
                fontSize: titleSize,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              isFilled ? '+${item.bestBoostPercent}%' : 'Leer',
              style: TextStyle(
                color: isFilled ? const Color(0xFFC084FC) : Colors.white24,
                fontSize: valueSize,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final avatar = _map(_profile['avatar']);
    final userName = _string(
      _profile['userName'],
      fallback: _string(_profile['UserName'], fallback: 'Champion'),
    );
    final bodyStage = _normalizeBodyStage(
      _string(avatar['bodyStage'], fallback: 'Skinny'),
    );

    return RefreshIndicator(
      onRefresh: () async {
        await _load();
        await widget.onRefreshHeader();
      },
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Row(
            children: [
              Expanded(
                child: _buildBoostCard(
                  icon: Icons.trending_up,
                  label: 'XP Boost',
                  value: _totalXpBoost,
                  barGradient: const [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                  iconColor: const Color(0xFF60A5FA),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildBoostCard(
                  icon: Icons.monetization_on,
                  label: 'Coin Boost',
                  value: _totalCoinBoost,
                  barGradient: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                  iconColor: const Color(0xFFFBBF24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Avatar & Ausrüstung',
            child: Column(
              children: [
                Text(
                  userName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.76),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3.2,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const leftRightSlots = 2;
                    const gap = 10.0;
                    final availableWidth = constraints.maxWidth;
                    final isSmall = availableWidth < 410;
                    final isTablet = availableWidth >= 720;

                    final targetAvatarWidth = isTablet
                        ? 294.0
                        : (isSmall ? 176.0 : 242.0);
                    final targetAvatarHeight = isTablet
                        ? 322.0
                        : (isSmall ? 220.0 : 278.0);
                    final targetSlotSize = isTablet ? 104.0 : 90.0;
                    final targetSideWidth = targetSlotSize;
                    final targetSpacing = gap;
                    final targetTotalWidth =
                        targetSideWidth * leftRightSlots +
                        targetAvatarWidth +
                        targetSpacing * 2;
                    final scale = targetTotalWidth > availableWidth
                        ? availableWidth / targetTotalWidth
                        : 1.0;

                    final slotSize = (targetSlotSize * scale).clamp(
                      66.0,
                      targetSlotSize,
                    );
                    final avatarWidth = (targetAvatarWidth * scale).clamp(
                      160.0,
                      targetAvatarWidth,
                    );
                    final avatarHeight = (targetAvatarHeight * scale).clamp(
                      196.0,
                      targetAvatarHeight,
                    );
                    final horizontalGap = (targetSpacing * scale).clamp(
                      6.0,
                      10.0,
                    );
                    final baseScale = isTablet ? 3.72 : (isSmall ? 2.52 : 3.34);

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: slotSize,
                          child: Column(
                            children: [
                              _buildEquipSlot(0, size: slotSize),
                              SizedBox(height: horizontalGap),
                              _buildEquipSlot(1, size: slotSize),
                            ],
                          ),
                        ),
                        SizedBox(width: horizontalGap),
                        SizedBox(
                          width: avatarWidth,
                          height: avatarHeight + (isTablet ? 54 : 48),
                          child: Column(
                            children: [
                              SizedBox(
                                width: avatarWidth,
                                height: avatarHeight + (isTablet ? 26 : 20),
                                child: OverflowBox(
                                  alignment: Alignment(
                                    0,
                                    isTablet ? -0.34 : -0.4,
                                  ),
                                  minWidth: 0,
                                  minHeight: 0,
                                  maxWidth: double.infinity,
                                  maxHeight: double.infinity,
                                  child: _SpriteAnimator(
                                    stage: bodyStage,
                                    frameWidth: 128,
                                    frameHeight: 128,
                                    columns: 2,
                                    frameCount: 4,
                                    speed: const Duration(milliseconds: 1000),
                                    scale: baseScale * scale,
                                  ),
                                ),
                              ),
                              SizedBox(height: isTablet ? 6 : 4),
                              Container(
                                width: avatarWidth * 0.62,
                                height: isTablet ? 16 : 14,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(0xFF2563EB).withOpacity(0.62),
                                      const Color(0xFF2563EB).withOpacity(0.16),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: horizontalGap),
                        SizedBox(
                          width: slotSize,
                          child: Column(
                            children: [
                              _buildEquipSlot(2, size: slotSize),
                              SizedBox(height: horizontalGap),
                              _buildEquipSlot(3, size: slotSize),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (_selectingSlotFor != null)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFA855F7).withOpacity(0.16),
                      border: Border.all(
                        color: const Color(0xFFA855F7).withOpacity(0.38),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.bolt,
                          size: 15,
                          color: Color(0xFFC084FC),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Wähle einen Slot für ${_selectingSlotFor!.name}',
                            style: const TextStyle(
                              color: Color(0xFFE9D5FF),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _selectingSlotFor = null);
                          },
                          child: const Text(
                            'Abbrechen',
                            style: TextStyle(color: Color(0xFFFCA5A5)),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SectionCard(
            title: 'Inventar',
            child: Column(
              children: _inventory.isEmpty
                  ? [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          'Keine Booster vorhanden. Kaufe Booster im Shop.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.68),
                          ),
                        ),
                      ),
                    ]
                  : _inventory
                        .map((Booster booster) {
                          final total =
                              booster.xpBoostPercentage +
                              booster.coinBoostPercentage;
                          final accent = total >= 60
                              ? const Color(0xFFFBBF24)
                              : total >= 40
                              ? const Color(0xFFC084FC)
                              : total >= 20
                              ? const Color(0xFF60A5FA)
                              : const Color(0xFF94A3B8);
                          final isEquipped = _equippedCount(booster.id) > 0;
                          final canEquip = _canEquipMore(booster);
                          final count = _equippedCount(booster.id);

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 3,
                            ),
                            leading: Container(
                              width: 42,
                              height: 42,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: accent.withOpacity(0.14),
                                border: Border.all(
                                  color: accent.withOpacity(0.34),
                                ),
                              ),
                              child: Text(
                                _boosterIcon(booster),
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                            title: Text(
                              booster.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              'XP +${booster.xpBoostPercentage}% • Coins +${booster.coinBoostPercentage}% • $count/${booster.quantity} ausgerüstet',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                            trailing: isEquipped
                                ? TextButton(
                                    onPressed: () =>
                                        _unequipBoosterById(booster.id),
                                    child: const Text(
                                      'Ablegen',
                                      style: TextStyle(
                                        color: Color(0xFFFCA5A5),
                                      ),
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: canEquip
                                        ? () {
                                            setState(
                                              () => _selectingSlotFor = booster,
                                            );
                                          }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFEC4899),
                                            Color(0xFFF43F5E),
                                          ],
                                        ),
                                      ),
                                      child: const SizedBox(
                                        height: 34,
                                        width: 90,
                                        child: Center(
                                          child: Text(
                                            'Ausrüsten',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                          );
                        })
                        .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}

class ShopTab extends StatefulWidget {
  const ShopTab({
    required this.onRefreshHeader,
    required this.showSnack,
    super.key,
  });

  final Future<void> Function() onRefreshHeader;
  final void Function(String) showSnack;

  @override
  State<ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends State<ShopTab> {
  bool _loading = true;
  List<dynamic> _items = <dynamic>[];
  Map<String, dynamic> _profile = <String, dynamic>{};
  String _activeFilter = 'all';
  int _currentCoins = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait<dynamic>([
        ApiService.getProfile(),
        ApiService.getShopItems(),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = _map(results[0]);
        _currentCoins = _toInt(_profile['coins']);
        _items = results[1] as List<dynamic>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      widget.showSnack('Shop konnte nicht geladen werden.');
    }
  }

  Future<void> _buyItem(int itemId) async {
    try {
      await ApiService.buyItem(itemId);
      widget.showSnack('Item gekauft.');
      await widget.onRefreshHeader();
      await _load();
    } catch (_) {
      widget.showSnack('Kauf fehlgeschlagen.');
    }
  }

  String _shopCategory(Map<String, dynamic> item) {
    final searchBase =
        '${_string(item['name'])} ${_string(item['description'])}'
            .toLowerCase();
    final itemType = _string(item['type']).toLowerCase();
    if (searchBase.contains('chest') ||
        searchBase.contains('crate') ||
        searchBase.contains('box') ||
        searchBase.contains('bundle') ||
        searchBase.contains('pack')) {
      return 'chest';
    }
    if (itemType.contains('booster') ||
        _toInt(item['xpBoostPercentage']) > 0 ||
        _toInt(item['coinBoostPercentage']) > 0 ||
        searchBase.contains('boost') ||
        searchBase.contains('xp') ||
        searchBase.contains('potion') ||
        searchBase.contains('luck')) {
      return 'boost';
    }
    return 'item';
  }

  String _shopRarity(Map<String, dynamic> item) {
    final explicit = _string(item['rarity']).toLowerCase();
    if (explicit == 'common' ||
        explicit == 'rare' ||
        explicit == 'epic' ||
        explicit == 'legendary') {
      return explicit;
    }

    final price = _toInt(item['price']);
    final boost = _toInt(item['xpBoostPercentage']);
    final searchBase =
        '${_string(item['name'])} ${_string(item['description'])}'
            .toLowerCase();
    if (searchBase.contains('legend') ||
        searchBase.contains('mythic') ||
        price >= 1200 ||
        boost >= 100)
      return 'legendary';
    if (searchBase.contains('epic') ||
        searchBase.contains('premium') ||
        price >= 700 ||
        boost >= 60)
      return 'epic';
    if (searchBase.contains('rare') ||
        searchBase.contains('silver') ||
        price >= 350 ||
        boost >= 25)
      return 'rare';
    return 'common';
  }

  String _shopIcon(String category, String rarity) {
    if (category == 'chest') {
      if (rarity == 'legendary') return '👑';
      if (rarity == 'epic') return '💎';
      if (rarity == 'rare') return '🎁';
      return '📦';
    }
    if (category == 'boost') {
      if (rarity == 'legendary') return '✨';
      if (rarity == 'epic') return '⚡';
      if (rarity == 'rare') return '🧪';
      return '💫';
    }
    return '🛡️';
  }

  List<String> _shopHighlights(Map<String, dynamic> item, String category) {
    final highlights = <String>[];
    final description = _string(item['description']);
    final xp = _toInt(item['xpBoostPercentage']);
    final coin = _toInt(item['coinBoostPercentage']);

    if (description.isNotEmpty) highlights.add(description);
    if (xp > 0) highlights.add('+$xp% XP Boost');
    if (coin > 0) highlights.add('+$coin% Coins');

    if (category == 'chest') {
      highlights.add('Loot-Reward Item');
      highlights.add('Ideal für neue Drops');
    } else if (category == 'boost') {
      highlights.add('Direkter Fortschritts-Boost');
      highlights.add('Perfekt für schnelle Runs');
    } else {
      highlights.add('Kosmetisches Upgrade');
      highlights.add('Für Avatar und Sammlung');
    }

    return highlights.toSet().take(3).toList(growable: false);
  }

  List<Map<String, dynamic>> get _displayItems {
    return _items
        .map((item) {
          final m = _map(item);
          final category = _shopCategory(m);
          final rarity = _shopRarity(m);
          final quantity = _toInt(m['quantity'], fallback: 1);
          final owned = _toInt(m['ownedQuantity'], fallback: 0);
          final maxQuantity = _toInt(
            m['maxQuantity'],
            fallback: quantity <= 0 ? 5 : quantity,
          );

          return <String, dynamic>{
            'id': _toInt(m['id']),
            'name': _string(m['name'], fallback: 'Item'),
            'description': _string(m['description']),
            'price': _toInt(m['price']),
            'type': _string(m['type']),
            'xpBoostPercentage': _toInt(m['xpBoostPercentage']),
            'coinBoostPercentage': _toInt(m['coinBoostPercentage']),
            'category': category,
            'categoryLabel': category == 'chest'
                ? 'Chest'
                : category == 'boost'
                ? 'Boost'
                : 'Item',
            'rarity': rarity,
            'icon': _shopIcon(category, rarity),
            'highlights': _shopHighlights(m, category),
            'ownedQuantity': owned,
            'maxQuantity': maxQuantity,
          };
        })
        .toList(growable: false);
  }

  List<Map<String, dynamic>> get _filteredItems {
    if (_activeFilter == 'all') return _displayItems;
    return _displayItems
        .where((item) => item['category'] == _activeFilter)
        .toList(growable: false);
  }

  List<Map<String, dynamic>> get _featuredItems {
    final rarityScore = <String, int>{
      'common': 1,
      'rare': 2,
      'epic': 3,
      'legendary': 4,
    };
    final items = [..._displayItems];
    items.sort((a, b) {
      final rarityDifference =
          (rarityScore[b['rarity']] ?? 1) - (rarityScore[a['rarity']] ?? 1);
      if (rarityDifference != 0) return rarityDifference;
      return (b['price'] as int) - (a['price'] as int);
    });
    return items.take(3).toList(growable: false);
  }

  String get _activeFilterLabel {
    switch (_activeFilter) {
      case 'chest':
        return 'Chests';
      case 'boost':
        return 'Boosts';
      case 'item':
        return 'Items';
      default:
        return 'Shop-Items';
    }
  }

  Color _rarityAccent(String rarity) {
    switch (rarity) {
      case 'rare':
        return const Color(0xFF60A5FA);
      case 'epic':
        return const Color(0xFFC084FC);
      case 'legendary':
        return const Color(0xFFFBBF24);
      case 'common':
      default:
        return const Color(0xFF94A3B8);
    }
  }

  Color _shopGradientStart(String category) {
    switch (category) {
      case 'chest':
        return const Color(0xFF8B5CF6);
      case 'boost':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF0EA5E9);
    }
  }

  Widget _buildHeroCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Item Shop',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Kompakter Shop für Booster, Chests und Items.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.68),
            fontSize: 14,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final active = _activeFilter == value;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => setState(() => _activeFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: active ? const Color(0xFFEC4899) : const Color(0xFF111827),
          border: Border.all(
            color: active
                ? const Color(0xFFF472B6).withOpacity(0.45)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white70,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(Map<String, dynamic> item, String badgeText) {
    final rarity = _string(item['rarity']);
    final accent = _rarityAccent(rarity);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: accent.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: accent.withOpacity(0.14),
            ),
            child: Center(
              child: Text(
                item['icon'] as String,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: accent.withOpacity(0.12),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          color: accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item['name'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item['description'] as String,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.66),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/SYBAU_Coin.png',
                width: 14,
                height: 14,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 5),
              Text(
                _formatCompactNumber(_toInt(item['price'])),
                style: const TextStyle(
                  color: Color(0xFFFFA94D),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileShopCard(Map<String, dynamic> item) {
    final category = item['category'] as String;
    final rarity = item['rarity'] as String;
    final accent = _rarityAccent(rarity);
    final price = item['price'] as int;
    final owned = item['ownedQuantity'] as int;
    final maxQuantity = item['maxQuantity'] as int;
    final canBuy = _currentCoins >= price && owned < maxQuantity;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFF0F172A).withOpacity(0.78),
        border: Border.all(color: accent.withOpacity(0.14)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 118,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withOpacity(0.24),
                  _shopGradientStart(category).withOpacity(0.16),
                ],
              ),
              border: Border.all(color: accent.withOpacity(0.22)),
            ),
            child: Center(
              child: Text(
                item['icon'] as String,
                style: const TextStyle(fontSize: 56),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  item['name'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: accent.withOpacity(0.14),
                  border: Border.all(color: accent.withOpacity(0.28)),
                ),
                child: Text(
                  rarity,
                  style: TextStyle(
                    color: accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$category • ${item['type']}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item['description'] as String,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: (item['highlights'] as List<String>)
                .map(
                  (highlight) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.white.withOpacity(0.05),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Text(
                      highlight,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                owned > 0
                    ? '$owned/$maxQuantity owned'
                    : '0/$maxQuantity owned',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.62),
                  fontSize: 10,
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 38,
                child: ElevatedButton(
                  onPressed: canBuy ? () => _buyItem(item['id'] as int) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15803D),
                    disabledBackgroundColor: const Color(
                      0xFF166534,
                    ).withOpacity(0.58),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white.withOpacity(0.62),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: owned >= maxQuantity
                      ? const Text(
                          'Max erreicht',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/SYBAU_Coin.png',
                              width: 17,
                              height: 17,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _formatCompactNumber(price),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final heroFeatured = _featuredItems;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
        children: [
          _buildHeroCard(),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Highlights',
            child: Column(
              children: heroFeatured.isEmpty
                  ? [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Keine Highlights verfügbar.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.68),
                          ),
                        ),
                      ),
                    ]
                  : heroFeatured
                        .asMap()
                        .entries
                        .map((entry) {
                          final badge = entry.key == 0
                              ? 'Top Pick'
                              : entry.key == 1
                              ? 'Beliebt'
                              : 'Neu im Fokus';
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: entry.key == heroFeatured.length - 1
                                  ? 0
                                  : 12,
                            ),
                            child: _buildFeaturedCard(entry.value, badge),
                          );
                        })
                        .toList(growable: false),
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: _activeFilterLabel,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kompakte Karten für mobile Geräte.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.68),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFilterChip('all', 'Alle'),
                    _buildFilterChip('chest', 'Chests'),
                    _buildFilterChip('boost', 'Boosts'),
                    _buildFilterChip('item', 'Items'),
                  ],
                ),
                const SizedBox(height: 14),
                _filteredItems.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'Für diesen Filter gibt es aktuell keine Items.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.68),
                          ),
                        ),
                      )
                    : Column(
                        children: _filteredItems
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildMobileShopCard(item),
                              ),
                            )
                            .toList(growable: false),
                      ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Mehr Coins verdienen',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Workouts und Quests bleiben dein schnellster Weg, um neue Shop-Items freizuschalten.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.white.withOpacity(0.04),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pro Workout',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '50–150 Coins',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.white.withOpacity(0.04),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pro Quest',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '100–500 Coins',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopPill extends StatelessWidget {
  const _ShopPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withOpacity(0.14),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class FriendsTab extends StatefulWidget {
  const FriendsTab({
    required this.onRefreshHeader,
    required this.showSnack,
    super.key,
  });

  final Future<void> Function() onRefreshHeader;
  final void Function(String) showSnack;

  @override
  State<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<FriendsTab> {
  bool _loading = true;
  String _activeSection = 'friends';
  int _currentUserId = 0;
  List<dynamic> _friends = <dynamic>[];
  List<dynamic> _requests = <dynamic>[];
  List<dynamic> _sentRequests = <dynamic>[];
  List<dynamic> _challenges = <dynamic>[];
  List<dynamic> _leaderboard = <dynamic>[];
  final TextEditingController _requestController = TextEditingController();
  final TextEditingController _challengeTitleController =
      TextEditingController();
  final TextEditingController _challengeDescriptionController =
      TextEditingController();
  final TextEditingController _challengeXpController = TextEditingController(
    text: '50',
  );
  final TextEditingController _challengeCoinsController = TextEditingController(
    text: '10',
  );
  final TextEditingController _challengeGoalController = TextEditingController(
    text: '100',
  );
  final TextEditingController _challengeDurationController =
      TextEditingController(text: '24');
  final TextEditingController _progressController = TextEditingController(
    text: '1',
  );
  List<Map<String, dynamic>> _userDirectory = <Map<String, dynamic>>[];
  Map<String, dynamic>? _challengeOpponent;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _requestController.dispose();
    _challengeTitleController.dispose();
    _challengeDescriptionController.dispose();
    _challengeXpController.dispose();
    _challengeCoinsController.dispose();
    _challengeGoalController.dispose();
    _challengeDurationController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait<dynamic>([
        ApiService.getProfile(),
        ApiService.getFriends(),
        ApiService.getPendingFriendRequests(),
        ApiService.getSentFriendRequests(),
        ApiService.getFriendChallenges(),
        ApiService.getLeaderboard(),
      ]);
      if (!mounted) return;
      final profile = _map(results[0]);
      final currentUserId = _toInt(
        profile['id'],
        fallback: _toInt(profile['Id']),
      );
      final currentUserName = _string(
        profile['userName'],
        fallback: _string(profile['UserName']),
      ).toLowerCase();
      final friends = results[1] as List<dynamic>;
      final requests = results[2] as List<dynamic>;
      final sentRequests = results[3] as List<dynamic>;
      final challenges = results[4] as List<dynamic>;
      final leaderboard = results[5] as List<dynamic>;
      final friendNames = friends
          .map((dynamic item) {
            final map = _map(item);
            return _string(
              map['friendUserName'],
              fallback: _string(
                map['userName'],
                fallback: _string(map['friendName']),
              ),
            ).toLowerCase();
          })
          .where((String name) => name.isNotEmpty)
          .toSet();
      final directory = leaderboard
          .map((dynamic item) => _map(item))
          .map((Map<String, dynamic> user) {
            final userName = _string(
              user['userName'],
              fallback: _string(
                user['UserName'],
                fallback: _string(user['username']),
              ),
            );
            return <String, dynamic>{
              'id': _toInt(user['id'], fallback: _toInt(user['Id'])),
              'userName': userName,
              'profileImageUrl': _string(
                user['profileImageUrl'],
                fallback: _string(user['ProfileImageUrl']),
              ),
              'level': _toInt(user['level'], fallback: _toInt(user['Level'])),
              'experience': _toInt(
                user['experience'],
                fallback: _toInt(user['Experience']),
              ),
            };
          })
          .where((Map<String, dynamic> user) {
            final lower = _string(user['userName']).toLowerCase();
            return lower.isNotEmpty &&
                lower != currentUserName &&
                !friendNames.contains(lower);
          })
          .toList(growable: false);
      setState(() {
        _currentUserId = currentUserId;
        _friends = friends;
        _requests = requests;
        _sentRequests = sentRequests;
        _challenges = challenges;
        _leaderboard = leaderboard;
        _userDirectory = directory;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      widget.showSnack('Friends konnten nicht geladen werden.');
    }
  }

  Set<String> get _sentRequestNames => _sentRequests
      .map((dynamic item) {
        final map = _map(item);
        return _string(map['toUserName']).toLowerCase();
      })
      .where((String name) => name.isNotEmpty)
      .toSet();

  List<Map<String, dynamic>> get _activeChallenges => _challengeMaps
      .where(
        (Map<String, dynamic> challenge) =>
            _string(challenge['status']) == 'Accepted',
      )
      .toList(growable: false);

  List<Map<String, dynamic>> get _pendingChallenges => _challengeMaps
      .where(
        (Map<String, dynamic> challenge) =>
            _string(challenge['status']) == 'Pending',
      )
      .toList(growable: false);

  List<Map<String, dynamic>> get _pastChallenges => _challengeMaps
      .where((Map<String, dynamic> challenge) {
        final status = _string(challenge['status']);
        return status == 'Completed' ||
            status == 'Expired' ||
            status == 'Declined';
      })
      .toList(growable: false);

  List<Map<String, dynamic>> get _challengeMaps =>
      _challenges.map((dynamic item) => _map(item)).toList(growable: false);

  Future<void> _sendRequest() async {
    final userName = _requestController.text.trim();
    if (userName.isEmpty) return;
    try {
      await ApiService.sendFriendRequest(userName);
      widget.showSnack('Anfrage gesendet.');
      await _load();
    } catch (_) {
      widget.showSnack('Anfrage fehlgeschlagen.');
    }
  }

  Future<void> _acceptChallenge(int id) async {
    try {
      await ApiService.acceptFriendChallenge(id);
      widget.showSnack('Challenge angenommen.');
      await _load();
    } catch (_) {
      widget.showSnack('Challenge konnte nicht angenommen werden.');
    }
  }

  Future<void> _declineChallenge(int id) async {
    try {
      await ApiService.declineFriendChallenge(id);
      widget.showSnack('Challenge abgelehnt.');
      await _load();
    } catch (_) {
      widget.showSnack('Challenge konnte nicht abgelehnt werden.');
    }
  }

  Future<void> _createChallenge() async {
    final opponent = _challengeOpponent;
    final title = _challengeTitleController.text.trim();
    if (opponent == null || title.isEmpty) {
      widget.showSnack('Bitte Titel und Gegner auswaehlen.');
      return;
    }

    try {
      await ApiService.createFriendChallenge(
        opponentId: _toInt(opponent['id']),
        title: title,
        description: _challengeDescriptionController.text.trim(),
        xpReward: int.tryParse(_challengeXpController.text.trim()) ?? 50,
        coinReward: int.tryParse(_challengeCoinsController.text.trim()) ?? 10,
        goalAmount: int.tryParse(_challengeGoalController.text.trim()) ?? 100,
        durationHours:
            int.tryParse(_challengeDurationController.text.trim()) ?? 24,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.showSnack('Challenge gesendet.');
      await _load();
    } catch (_) {
      widget.showSnack('Challenge konnte nicht erstellt werden.');
    }
  }

  Future<void> _updateProgress(Map<String, dynamic> challenge) async {
    final amount = int.tryParse(_progressController.text.trim()) ?? 0;
    if (amount <= 0) return;

    try {
      final data = await ApiService.updateFriendChallengeProgress(
        id: _toInt(challenge['id']),
        amount: amount,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.showSnack(
        _string(data['message'], fallback: 'Fortschritt gemeldet.'),
      );
      await _load();
      await widget.onRefreshHeader();
    } catch (_) {
      widget.showSnack('Fortschritt konnte nicht gemeldet werden.');
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    final query = _requestController.text.trim().toLowerCase();
    if (query.isEmpty) return <Map<String, dynamic>>[];
    return _userDirectory
        .where(
          (Map<String, dynamic> user) =>
              _string(user['userName']).toLowerCase().contains(query),
        )
        .take(8)
        .toList(growable: false);
  }

  InputDecoration _friendSearchDecoration() {
    return InputDecoration(
      hintText: 'Benutzername suchen...',
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.45)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.04),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.14)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.14)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: Color(0xFFEC4899)),
      ),
    );
  }

  Future<void> _accept(int id) async {
    try {
      await ApiService.acceptFriendRequest(id);
      widget.showSnack('Anfrage akzeptiert.');
      await _load();
    } catch (_) {
      widget.showSnack('Akzeptieren fehlgeschlagen.');
    }
  }

  Future<void> _decline(int id) async {
    try {
      await ApiService.declineFriendRequest(id);
      widget.showSnack('Anfrage abgelehnt.');
      await _load();
    } catch (_) {
      widget.showSnack('Ablehnen fehlgeschlagen.');
    }
  }

  Future<void> _remove(int id) async {
    try {
      await ApiService.removeFriend(id);
      widget.showSnack('Freund entfernt.');
      await _load();
    } catch (_) {
      widget.showSnack('Entfernen fehlgeschlagen.');
    }
  }

  Widget _buildFriendsAvatar(
    Map<String, dynamic> profile, {
    double size = 42,
    bool tappable = true,
  }) {
    final imagePath = _string(
      profile['profileImageUrl'],
      fallback: _string(
        profile['friendProfileImageUrl'],
        fallback: _string(profile['fromUserProfileImageUrl']),
      ),
    );
    final imageUrl = ApiService.mediaUrl(imagePath);

    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1E293B),
      ),
      child: ClipOval(
        child: imageUrl == null
            ? Image.asset(_noProfilePictureAsset, fit: BoxFit.cover)
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Image.asset(_noProfilePictureAsset, fit: BoxFit.cover),
              ),
      ),
    );

    if (!tappable) return avatar;

    return InkWell(
      onTap: () => _openUserProfile(profile),
      borderRadius: BorderRadius.circular(999),
      child: avatar,
    );
  }

  void _openUserProfile(Map<String, dynamic> rawProfile) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ReadOnlyUserProfileSheet(seedProfile: rawProfile),
    );
  }

  void _openChallengeModal(Map<String, dynamic> friend) {
    _challengeOpponent = friend;
    _challengeTitleController.clear();
    _challengeDescriptionController.clear();
    _challengeXpController.text = '50';
    _challengeCoinsController.text = '10';
    _challengeGoalController.text = '100';
    _challengeDurationController.text = '24';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          22,
          18,
          24 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Challenge an ${_string(friend['userName'], fallback: _string(friend['friendUserName']))}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              _settingsTextField(_challengeTitleController, 'Titel'),
              const SizedBox(height: 10),
              _settingsTextField(
                _challengeDescriptionController,
                'Beschreibung',
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _settingsTextField(_challengeGoalController, 'Ziel'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _settingsTextField(
                      _challengeDurationController,
                      'Stunden',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _settingsTextField(_challengeXpController, 'XP'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _settingsTextField(
                      _challengeCoinsController,
                      'Coins',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: _GradientActionButton(
                  onPressed: _createChallenge,
                  label: 'Challenge senden',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openProgressModal(Map<String, dynamic> challenge) {
    _progressController.text = '1';
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          22,
          18,
          24 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _string(challenge['title'], fallback: 'Challenge'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            _settingsTextField(_progressController, 'Fortschritt'),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: _GradientActionButton(
                onPressed: () => _updateProgress(challenge),
                label: 'Fortschritt melden',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: label == 'Titel' || label == 'Beschreibung'
          ? TextInputType.text
          : TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.72)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFEC4899)),
        ),
      ),
    );
  }

  Widget _buildSectionTabs() {
    final tabs = <(String, String, IconData)>[
      ('friends', 'Freunde', Icons.groups_rounded),
      ('requests', 'Anfragen', Icons.person_add_alt_1_rounded),
      ('challenges', 'Challenges', Icons.emoji_events_rounded),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs
            .map((tab) {
              final active = _activeSection == tab.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _activeSection = tab.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: active
                          ? const Color(0xFFEC4899).withOpacity(0.26)
                          : Colors.white.withOpacity(0.05),
                      border: Border.all(
                        color: active
                            ? const Color(0xFFEC4899).withOpacity(0.55)
                            : Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab.$3,
                          size: 16,
                          color: active ? Colors.white : Colors.white60,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          tab.$2,
                          style: TextStyle(
                            color: active ? Colors.white : Colors.white70,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
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
    );
  }

  Widget _buildFriendCard(Map<String, dynamic> friend) {
    final name = _string(
      friend['friendUserName'],
      fallback: _string(
        friend['userName'],
        fallback: _string(friend['friendName']),
      ),
    );
    final friendTotalXp = _toInt(
      friend['friendTotalXp'],
      fallback: _toInt(
        friend['totalXp'],
        fallback: _toInt(
          friend['friendExperience'],
          fallback: _toInt(friend['experience']),
        ),
      ),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          _buildFriendsAvatar(friend),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Lv ${_toInt(friend['friendLevel'], fallback: _toInt(friend['level']))} • ${_formatCompactNumber(friendTotalXp)} XP',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.58),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _openChallengeModal(friend),
            icon: const Icon(Icons.emoji_events_rounded),
            color: const Color(0xFFFDA4AF),
          ),
          IconButton(
            onPressed: _toInt(friend['id']) == 0
                ? null
                : () => _remove(_toInt(friend['id'])),
            icon: const Icon(Icons.delete_outline_rounded),
            color: const Color(0xFFFCA5A5),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(Map<String, dynamic> challenge) {
    final status = _string(challenge['status']);
    final id = _toInt(challenge['id']);
    final isPendingForMe =
        status == 'Pending' &&
        _toInt(challenge['opponentId']) == _currentUserId;
    final myProgress = _toInt(challenge['challengerId']) == _currentUserId
        ? _toInt(challenge['challengerProgress'])
        : _toInt(challenge['opponentProgress']);
    final otherProgress = _toInt(challenge['challengerId']) == _currentUserId
        ? _toInt(challenge['opponentProgress'])
        : _toInt(challenge['challengerProgress']);
    final goal = _toInt(challenge['goalAmount'], fallback: 1);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _string(challenge['title'], fallback: 'Challenge'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              _statusPill(status),
            ],
          ),
          if (_string(challenge['description']).isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _string(challenge['description']),
              style: TextStyle(
                color: Colors.white.withOpacity(0.64),
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            '${_string(challenge['challengerUserName'])} vs ${_string(challenge['opponentUserName'])}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: (myProgress / goal).clamp(0, 1),
            backgroundColor: Colors.white.withOpacity(0.08),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEC4899)),
          ),
          const SizedBox(height: 6),
          Text(
            'Du: $myProgress/$goal • Gegner: $otherProgress/$goal • ${_formatCompactNumber(_toInt(challenge['xpReward']))} XP • ${_formatCompactNumber(_toInt(challenge['coinReward']))} Coins',
            style: TextStyle(
              color: Colors.white.withOpacity(0.58),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          if (isPendingForMe)
            Row(
              children: [
                Expanded(
                  child: _GradientActionButton(
                    onPressed: id == 0 ? null : () => _acceptChallenge(id),
                    label: 'Annehmen',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: id == 0 ? null : () => _declineChallenge(id),
                    child: const Text('Ablehnen'),
                  ),
                ),
              ],
            )
          else if (status == 'Accepted')
            SizedBox(
              width: double.infinity,
              child: _GradientActionButton(
                onPressed: () => _openProgressModal(challenge),
                label: 'Fortschritt melden',
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusPill(String status) {
    final color = switch (status) {
      'Accepted' => const Color(0xFF22C55E),
      'Pending' => const Color(0xFFF59E0B),
      'Completed' => const Color(0xFFEC4899),
      'Declined' => const Color(0xFFEF4444),
      _ => const Color(0xFF94A3B8),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withOpacity(0.16),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _buildSectionTabs(),
          const SizedBox(height: 12),
          if (_activeSection == 'friends') ...[
            _SectionCard(
              title: 'Freunde finden',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _requestController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(color: Colors.white),
                    decoration: _friendSearchDecoration(),
                  ),
                  const SizedBox(height: 10),
                  if (_requestController.text.trim().isNotEmpty &&
                      _filteredUsers.isEmpty)
                    Text(
                      'Keine passenden Nutzer gefunden.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.62),
                        fontSize: 12,
                      ),
                    ),
                  ..._filteredUsers.map((Map<String, dynamic> user) {
                    final userName = _string(user['userName']);
                    final sent = _sentRequestNames.contains(
                      userName.toLowerCase(),
                    );
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.white.withOpacity(0.04),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildFriendsAvatar(user),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Lv ${_toInt(user['level'])} • ${_formatCompactNumber(_toInt(user['totalXp'], fallback: _toInt(user['experience'])))} XP',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.58),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (sent)
                            const _SentStatusPill()
                          else
                            SizedBox(
                              width: 86,
                              height: 38,
                              child: _GradientActionButton(
                                onPressed: () async {
                                  _requestController.text = userName;
                                  await _sendRequest();
                                },
                                label: 'Senden',
                                compact: true,
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _SectionCard(
              title: 'Friends',
              child: _friends.isEmpty
                  ? const Text(
                      'Noch keine Freunde.',
                      style: TextStyle(color: Colors.white70),
                    )
                  : Column(
                      children: _friends
                          .map((f) => _buildFriendCard(_map(f)))
                          .toList(growable: false),
                    ),
            ),
          ] else if (_activeSection == 'requests') ...[
            _SectionCard(
              title: 'Eingehende Anfragen',
              child: _requests.isEmpty
                  ? const Text(
                      'Keine offenen Anfragen.',
                      style: TextStyle(color: Colors.white70),
                    )
                  : Column(
                      children: _requests
                          .map((r) {
                            final m = _map(r);
                            final id = _toInt(m['id']);
                            final profile = <String, dynamic>{
                              ...m,
                              'userName': _string(m['fromUserName']),
                              'profileImageUrl': _string(
                                m['fromUserProfileImageUrl'],
                              ),
                              'level': _toInt(m['fromUserLevel']),
                            };
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: _buildFriendsAvatar(profile),
                              title: Text(
                                _string(m['fromUserName']),
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                'Level ${_toInt(m['fromUserLevel'])}',
                                style: const TextStyle(color: Colors.white54),
                              ),
                              trailing: Wrap(
                                spacing: 4,
                                children: [
                                  TextButton(
                                    onPressed: id == 0
                                        ? null
                                        : () => _accept(id),
                                    child: const Text('Accept'),
                                  ),
                                  TextButton(
                                    onPressed: id == 0
                                        ? null
                                        : () => _decline(id),
                                    child: const Text('Decline'),
                                  ),
                                ],
                              ),
                            );
                          })
                          .toList(growable: false),
                    ),
            ),
            const SizedBox(height: 10),
            _SectionCard(
              title: 'Gesendet',
              child: _sentRequests.isEmpty
                  ? const Text(
                      'Keine gesendeten offenen Anfragen.',
                      style: TextStyle(color: Colors.white70),
                    )
                  : Column(
                      children: _sentRequests
                          .map((r) {
                            final m = _map(r);
                            final profile = <String, dynamic>{
                              ...m,
                              'userName': _string(m['toUserName']),
                              'profileImageUrl': _string(
                                m['toUserProfileImageUrl'],
                              ),
                              'level': _toInt(m['toUserLevel']),
                            };
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: _buildFriendsAvatar(profile),
                              title: Text(
                                _string(m['toUserName']),
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: const Text(
                                'Sent',
                                style: TextStyle(color: Colors.white54),
                              ),
                            );
                          })
                          .toList(growable: false),
                    ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            _SectionCard(
              title: 'Challenge-Einladungen',
              child: _pendingChallenges.isEmpty
                  ? const Text(
                      'Keine Einladungen.',
                      style: TextStyle(color: Colors.white70),
                    )
                  : Column(
                      children: _pendingChallenges
                          .map(_buildChallengeCard)
                          .toList(growable: false),
                    ),
            ),
            const SizedBox(height: 10),
            _SectionCard(
              title: 'Aktive Challenges',
              child: _activeChallenges.isEmpty
                  ? const Text(
                      'Keine aktiven Challenges.',
                      style: TextStyle(color: Colors.white70),
                    )
                  : Column(
                      children: _activeChallenges
                          .map(_buildChallengeCard)
                          .toList(growable: false),
                    ),
            ),
            const SizedBox(height: 10),
            _SectionCard(
              title: 'Vergangene Challenges',
              child: _pastChallenges.isEmpty
                  ? const Text(
                      'Keine vergangenen Challenges.',
                      style: TextStyle(color: Colors.white70),
                    )
                  : Column(
                      children: _pastChallenges
                          .map(_buildChallengeCard)
                          .toList(growable: false),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class LeaderboardTab extends StatefulWidget {
  const LeaderboardTab({required this.showSnack, super.key});

  final void Function(String) showSnack;

  @override
  State<LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<LeaderboardTab> {
  bool _loading = true;
  List<dynamic> _leaderboard = <dynamic>[];
  Map<String, dynamic> _profile = <String, dynamic>{};
  String _currentUserName = '';

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  String _initials(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList(growable: false);
    if (parts.isEmpty) return 'SB';
    return parts.map((part) => part.characters.first.toUpperCase()).join();
  }

  void _syncCurrentUser() {
    _currentUserName = _string(
      _profile['userName'],
      fallback: _string(_profile['UserName']),
    );
  }

  bool _isCurrentUser(String name) {
    if (_currentUserName.isEmpty) return false;
    return name.trim().toLowerCase() == _currentUserName.trim().toLowerCase();
  }

  List<Map<String, dynamic>> get _entries {
    return _leaderboard
        .map((row) {
          final m = _map(row);
          final userName = _string(
            m['userName'],
            fallback: _string(m['UserName'], fallback: 'User'),
          );
          return <String, dynamic>{
            'id': _toInt(m['id'], fallback: _toInt(m['Id'])),
            'rank': _toInt(m['rank'], fallback: _toInt(m['Rank'])),
            'userName': userName,
            'profileImageUrl': _string(
              m['profileImageUrl'],
              fallback: _string(m['ProfileImageUrl']),
            ),
            'experience': _toInt(
              m['experience'],
              fallback: _toInt(m['Experience']),
            ),
            'totalXp': _toInt(m['totalXp'], fallback: _toInt(m['TotalXp'])),
            'level': _toInt(m['level'], fallback: _toInt(m['Level'])),
            'initials': _initials(userName),
            'isCurrentUser': _isCurrentUser(userName),
          };
        })
        .toList(growable: false)
      ..sort((a, b) => (a['rank'] as int).compareTo(b['rank'] as int));
  }

  List<Map<String, dynamic>> get _podiumPlayers =>
      _entries.take(3).toList(growable: false);

  Map<String, dynamic>? get _currentUserEntry {
    for (final entry in _entries) {
      if (entry['isCurrentUser'] == true) return entry;
    }
    return null;
  }

  int get _topFiveBorderXp =>
      _entries.length >= 5 ? (_entries[4]['totalXp'] as int) : 0;

  int get _xpToTopFive {
    final currentUserEntry = _currentUserEntry;
    if (currentUserEntry == null) return 0;
    final rank = currentUserEntry['rank'] as int;
    if (rank <= 5) return 0;
    return math.max(0, _topFiveBorderXp - (currentUserEntry['totalXp'] as int));
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait<dynamic>([
        ApiService.getProfile(),
        ApiService.getLeaderboard(),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = _map(results[0]);
        _syncCurrentUser();
        _leaderboard = results[1] as List<dynamic>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      widget.showSnack('Leaderboard konnte nicht geladen werden.');
    }
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFBBF24);
      case 2:
        return const Color(0xFFC0C4D4);
      case 3:
        return const Color(0xFFFB923C);
      default:
        return const Color(0xFF334155);
    }
  }

  Widget _buildLeaderboardAvatar(
    Map<String, dynamic> player, {
    required double size,
    bool tappable = true,
  }) {
    final imageUrl = ApiService.mediaUrl(_string(player['profileImageUrl']));

    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: imageUrl == null ? const Color(0xFF1E293B) : null,
      ),
      child: ClipOval(
        child: imageUrl == null
            ? Image.asset(_noProfilePictureAsset, fit: BoxFit.cover)
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Image.asset(_noProfilePictureAsset, fit: BoxFit.cover),
              ),
      ),
    );

    if (!tappable) return avatar;

    return InkWell(
      onTap: () => _openUserProfile(player),
      borderRadius: BorderRadius.circular(999),
      child: avatar,
    );
  }

  void _openUserProfile(Map<String, dynamic> player) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ReadOnlyUserProfileSheet(seedProfile: player),
    );
  }

  Widget _buildHeroCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Globales Ranking',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Kämpfe dich durch Workouts und Quests nach oben.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildPodium() {
    if (_podiumPlayers.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      title: 'Top Champions',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 360;
          final isTablet = constraints.maxWidth >= 720;
          final gap = isTablet ? 12.0 : 8.0;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_podiumPlayers.length == 1) ...[
                Expanded(
                  flex: 11,
                  child: _buildPodiumCard(
                    _podiumPlayers[0],
                    _toInt(_podiumPlayers[0]['rank'], fallback: 1),
                    isCompact: isCompact,
                    isTablet: isTablet,
                  ),
                ),
              ] else if (_podiumPlayers.length == 2) ...[
                Expanded(
                  flex: 10,
                  child: _buildPodiumCard(
                    _podiumPlayers[1],
                    _toInt(_podiumPlayers[1]['rank'], fallback: 2),
                    isCompact: isCompact,
                    isTablet: isTablet,
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  flex: 12,
                  child: _buildPodiumCard(
                    _podiumPlayers[0],
                    _toInt(_podiumPlayers[0]['rank'], fallback: 1),
                    isCompact: isCompact,
                    isTablet: isTablet,
                  ),
                ),
              ] else ...[
                Expanded(
                  flex: 10,
                  child: _buildPodiumCard(
                    _podiumPlayers[1],
                    _toInt(_podiumPlayers[1]['rank'], fallback: 2),
                    isCompact: isCompact,
                    isTablet: isTablet,
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  flex: 12,
                  child: _buildPodiumCard(
                    _podiumPlayers[0],
                    _toInt(_podiumPlayers[0]['rank'], fallback: 1),
                    isCompact: isCompact,
                    isTablet: isTablet,
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  flex: 10,
                  child: _buildPodiumCard(
                    _podiumPlayers[2],
                    _toInt(_podiumPlayers[2]['rank'], fallback: 3),
                    isCompact: isCompact,
                    isTablet: isTablet,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildPodiumCard(
    Map<String, dynamic> player,
    int place, {
    required bool isCompact,
    required bool isTablet,
  }) {
    final isFirst = place == 1;
    final rankColor = _rankColor(place);
    final avatarSize = isTablet
        ? (isFirst ? 72.0 : (place == 2 ? 58.0 : 48.0))
        : isCompact
        ? (isFirst ? 52.0 : (place == 2 ? 42.0 : 34.0))
        : (isFirst ? 60.0 : (place == 2 ? 48.0 : 36.0));
    final cardHeight = isTablet
        ? (isFirst ? 220.0 : (place == 2 ? 194.0 : 184.0))
        : isCompact
        ? (isFirst ? 186.0 : (place == 2 ? 166.0 : 156.0))
        : (isFirst ? 198.0 : (place == 2 ? 176.0 : 166.0));
    final nameFontSize = isTablet ? 14.0 : 13.0;
    final metaFontSize = isTablet ? 12.0 : 11.0;
    final xpFontSize = isTablet ? 13.0 : 12.0;

    return Container(
      height: cardHeight,
      padding: EdgeInsets.all(isTablet ? 8 : 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            rankColor.withOpacity(isFirst ? 0.24 : 0.16),
            const Color(0xFF0F172A).withOpacity(0.96),
          ],
        ),
        border: Border.all(color: rankColor.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: rankColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildLeaderboardAvatar(player, size: avatarSize),
          SizedBox(height: isTablet ? 6 : 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: Colors.white.withOpacity(0.08),
            ),
            child: Text(
              '#$place',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(height: isTablet ? 6 : 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  player['userName'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: nameFontSize,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (player['isCurrentUser'] == true) ...[
                const SizedBox(width: 6),
                const Icon(Icons.star, color: Color(0xFFFBBF24), size: 14),
              ],
            ],
          ),
          const SizedBox(height: 1),
          Text(
            'Level ${player['level']}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.66),
              fontSize: metaFontSize,
            ),
          ),
          SizedBox(height: isTablet ? 6 : 4),
          Text(
            '${_formatCompactNumber(_toInt(player['totalXp']))} XP',
            style: TextStyle(
              color: const Color(0xFFFDE047),
              fontWeight: FontWeight.w800,
              fontSize: xpFontSize,
            ),
          ),
          // current-user indicator replaced by a small star next to the name
        ],
      ),
    );
  }

  Widget _buildLeaderboardRow(Map<String, dynamic> player) {
    final rank = player['rank'] as int;
    final rankColor = _rankColor(rank);
    final isCurrentUser = player['isCurrentUser'] == true;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isCurrentUser
            ? const Color(0xFFA855F7).withOpacity(0.14)
            : Colors.white.withOpacity(0.04),
        border: Border.all(
          color: isCurrentUser
              ? const Color(0xFFA855F7).withOpacity(0.28)
              : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: rankColor.withOpacity(0.18),
            ),
            child: Center(
              child: rank <= 3
                  ? Icon(
                      rank == 1 ? Icons.emoji_events : Icons.workspace_premium,
                      color: rankColor,
                      size: 18,
                    )
                  : Text(
                      '#$rank',
                      style: TextStyle(
                        color: rankColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          _buildLeaderboardAvatar(player, size: 42),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              player['userName'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (isCurrentUser) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.star,
                              color: Color(0xFFFBBF24),
                              size: 14,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Level ${player['level']}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.62),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_formatCompactNumber(_toInt(player['totalXp']))} XP',
                style: const TextStyle(
                  color: Color(0xFFFDE047),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Gesamtfortschritt',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.48),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
        children: [
          _buildHeroCard(),
          const SizedBox(height: 14),
          _buildPodium(),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Globale Rangliste',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _entries.isEmpty
                  ? [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Noch keine Leaderboard-Daten vorhanden.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.68),
                          ),
                        ),
                      ),
                    ]
                  : _entries
                        .map(
                          (player) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildLeaderboardRow(player),
                          ),
                        )
                        .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileTab extends StatefulWidget {
  const ProfileTab({
    required this.onRefreshHeader,
    required this.showSnack,
    super.key,
  });

  final Future<void> Function() onRefreshHeader;
  final void Function(String) showSnack;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  static const Duration _usernameChangeCooldown = Duration(days: 14);

  bool _loading = true;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _serverUrlController = TextEditingController();

  Map<String, dynamic> _profile = <String, dynamic>{};
  List<dynamic> _achievements = <dynamic>[];
  Map<String, dynamic> _profileStats = <String, dynamic>{};
  List<dynamic> _recentActivities = <dynamic>[];
  List<dynamic> _weeklyActivity = <dynamic>[];
  String? _profileImageUrl;
  Uint8List? _pickedProfileImageBytes;
  int _profileImageVersion = 0;
  int _currentAchievementIndex = 0;
  int _currentWeekOffset = 0;
  bool _notificationsEnabled = false;
  bool _healthSyncEnabled = false;
  bool _settingsBusy = false;
  DateTime? _usernameChangedAt;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _serverUrlController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final week = _weekBounds(_currentWeekOffset);
      final results = await Future.wait<dynamic>([
        ApiService.getProfile(),
        ApiService.getAchievements(),
        ApiService.getProfileStats(),
        ApiService.getRecentActivities(limit: 10),
        ApiService.getWeeklyActivity(from: week.$1, to: week.$2),
        NotificationService.isEnabled(),
        HealthSyncService.isEnabled(),
      ]);

      final profile = results[0] as Map<String, dynamic>;
      final achievements = results[1] as List<dynamic>;
      final stats = results[2] as Map<String, dynamic>;
      final recent = results[3] as List<dynamic>;
      final weeklyRaw = (results[4] as List<dynamic>?) ?? <dynamic>[];
      final weekDays = _normalizeWeeklyActivity(weeklyRaw, week.$1);
      final profileImageUrl = _string(
        profile['profileImageUrl'],
        fallback: _string(profile['ProfileImageUrl']),
      );
      final usernameChangedAt = await _loadUsernameChangedAt(profile);

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _usernameController.text = _string(
          profile['userName'],
          fallback: _string(profile['UserName']),
        );
        _achievements = achievements;
        _profileStats = stats;
        _recentActivities = recent;
        _weeklyActivity = weekDays;
        _profileImageUrl = profileImageUrl;
        _pickedProfileImageBytes = null;
        _currentAchievementIndex = 0;
        _notificationsEnabled = results[5] as bool;
        _healthSyncEnabled = results[6] as bool;
        _usernameChangedAt = usernameChangedAt;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      widget.showSnack('Profil konnte nicht geladen werden.');
    }
  }

  Future<void> _setNotificationsEnabled(
    bool enabled,
    StateSetter modalSetState,
  ) async {
    modalSetState(() => _settingsBusy = true);
    try {
      await NotificationService.setEnabled(enabled);
      if (!mounted) return;
      setState(() => _notificationsEnabled = enabled);
      modalSetState(() => _notificationsEnabled = enabled);
      widget.showSnack(
        enabled
            ? 'In-App Benachrichtigungen aktiviert.'
            : 'In-App Benachrichtigungen deaktiviert.',
      );
    } catch (_) {
      widget.showSnack('Benachrichtigungen konnten nicht aktiviert werden.');
    } finally {
      if (mounted) {
        modalSetState(() => _settingsBusy = false);
      }
    }
  }

  Future<void> _setHealthSyncEnabled(
    bool enabled,
    StateSetter modalSetState,
  ) async {
    modalSetState(() => _settingsBusy = true);
    try {
      if (!enabled) {
        await HealthSyncService.setEnabled(false);
        if (!mounted) return;
        setState(() => _healthSyncEnabled = false);
        modalSetState(() => _healthSyncEnabled = false);
        widget.showSnack('Health Sync deaktiviert.');
        return;
      }

      final granted = await HealthSyncService.requestAuthorization();
      if (!granted) {
        if (!mounted) return;
        setState(() => _healthSyncEnabled = false);
        modalSetState(() => _healthSyncEnabled = false);
        widget.showSnack(
          'Health Zugriff wurde nicht freigegeben. Bitte Berechtigung erlauben, um automatisch zu synchronisieren.',
        );
        return;
      }

      await HealthSyncService.setEnabled(enabled);
      if (!mounted) return;
      setState(() => _healthSyncEnabled = enabled);
      modalSetState(() => _healthSyncEnabled = enabled);
      final result = await HealthSyncService.syncToday(
        requestPermissions: false,
      );
      if (!mounted) return;
      await _load();
      await widget.onRefreshHeader();
      final rewardText = result.hasRewards
          ? ' +${_formatCompactNumber(result.xpEarned)} XP, +${_formatCompactNumber(result.coinsEarned)} Coins.'
          : '';
      widget.showSnack(
        result.hasNewData
            ? 'Health Sync aktiviert und synchronisiert.$rewardText'
            : 'Health Sync aktiviert. Keine neuen Daten gefunden.',
      );
    } catch (_) {
      widget.showSnack('Health Sync konnte nicht aktiviert werden.');
    } finally {
      if (mounted) {
        modalSetState(() => _settingsBusy = false);
      }
    }
  }

  Future<bool> _saveProfile() async {
    final userName = _usernameController.text.trim();
    if (userName.isEmpty) return false;
    final currentUserName = _currentProfileUserName;
    final usernameChanged =
        userName.toLowerCase() != currentUserName.toLowerCase();
    if (usernameChanged && _isUsernameChangeLocked) {
      widget.showSnack('Benutzername kann nur alle 14 Tage geändert werden.');
      _usernameController.text = currentUserName;
      return false;
    }

    try {
      await ApiService.updateProfile(userName: userName);
      _profile['userName'] = userName;
      if (usernameChanged) {
        final now = DateTime.now();
        await _storeUsernameChangedAt(now);
        _usernameChangedAt = now;
      }
      widget.showSnack('Profil gespeichert.');
      await widget.onRefreshHeader();
      if (!mounted) return true;
      setState(() {});
      return true;
    } catch (_) {
      widget.showSnack('Speichern fehlgeschlagen.');
      return false;
    }
  }

  String get _currentProfileUserName {
    return _string(
      _profile['userName'],
      fallback: _string(_profile['UserName']),
    );
  }

  bool get _isUsernameChangeLocked {
    final changedAt = _usernameChangedAt;
    if (changedAt == null) return false;
    return DateTime.now().difference(changedAt) < _usernameChangeCooldown;
  }

  String get _usernameChangeHint {
    final changedAt = _usernameChangedAt;
    if (changedAt == null || !_isUsernameChangeLocked) {
      return 'Kann alle 14 Tage geändert werden.';
    }
    final nextDate = changedAt.add(_usernameChangeCooldown);
    return 'Wieder möglich ab ${_formatShortDate(nextDate)}.';
  }

  String get _usernameChangePreferenceKey {
    final userId = _toInt(_profile['id'], fallback: _toInt(_profile['Id']));
    return 'username_changed_at_${userId > 0 ? userId : _currentProfileUserName.toLowerCase()}';
  }

  Future<DateTime?> _loadUsernameChangedAt(Map<String, dynamic> profile) async {
    final userId = _toInt(profile['id'], fallback: _toInt(profile['Id']));
    final userName = _string(
      profile['userName'],
      fallback: _string(profile['UserName']),
    ).toLowerCase();
    final key = 'username_changed_at_${userId > 0 ? userId : userName}';
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> _storeUsernameChangedAt(DateTime value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _usernameChangePreferenceKey,
      value.toIso8601String(),
    );
  }

  String _formatShortDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  Future<void> _changePassword() async {
    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;
    if (oldPassword.isEmpty || newPassword.isEmpty) {
      widget.showSnack('Bitte beide Passwortfelder ausfuellen.');
      return;
    }
    if (oldPassword == newPassword) {
      widget.showSnack('Das neue Passwort muss anders sein.');
      return;
    }
    try {
      await ApiService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      _oldPasswordController.clear();
      _newPasswordController.clear();
      widget.showSnack('Passwort geaendert.');
    } catch (_) {
      widget.showSnack('Passwortwechsel fehlgeschlagen.');
    }
  }

  Future<void> _deleteAccount() async {
    try {
      await ApiService.deleteAccount();
      await ApiService.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (_) {
      widget.showSnack('Account konnte nicht geloescht werden.');
    }
  }

  ({DateTime $1, DateTime $2}) _weekBounds(int offset) {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final monday = normalizedToday
        .subtract(Duration(days: normalizedToday.weekday - 1))
        .add(Duration(days: offset * 7));
    final sunday = monday.add(const Duration(days: 6));
    return ($1: monday, $2: sunday);
  }

  String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  List<Map<String, dynamic>> _normalizeWeeklyActivity(
    List<dynamic> raw,
    DateTime monday,
  ) {
    final repsByDate = <String, int>{};
    for (final item in raw) {
      final map = _map(item);
      final rawDate = _string(
        map['date'],
        fallback: _string(map['Date'], fallback: _string(map['day'])),
      );
      if (rawDate.isEmpty) continue;
      final dateKey = rawDate.contains('T')
          ? rawDate.split('T').first
          : rawDate;
      final reps = _toInt(
        map['reps'],
        fallback: _toInt(
          map['Reps'],
          fallback: _toInt(map['count'], fallback: _toInt(map['totalReps'])),
        ),
      );
      repsByDate[dateKey] = reps;
    }

    const weekdayNames = <String>['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    final today = DateTime.now();
    final todayKey = _dateKey(today);
    return List<Map<String, dynamic>>.generate(7, (int index) {
      final day = monday.add(Duration(days: index));
      final key = _dateKey(day);
      final reps = repsByDate[key] ?? 0;
      return <String, dynamic>{
        'name': weekdayNames[index],
        'date': key,
        'dateDisplay':
            '${day.day.toString().padLeft(2, '0')}.${day.month.toString().padLeft(2, '0')}',
        'reps': reps,
        'workoutDone': reps > 0,
        'isToday': key == todayKey,
      };
    });
  }

  String get _weekLabel {
    if (_weeklyActivity.isEmpty) return '';
    final first = _map(_weeklyActivity.first);
    final last = _map(_weeklyActivity.last);
    return '${_string(first['dateDisplay'])} - ${_string(last['dateDisplay'])}';
  }

  List<dynamic> get _visibleAchievements {
    if (_achievements.isEmpty) return <dynamic>[];
    final start = math.min(
      _currentAchievementIndex,
      _lastAchievementPageStart(_achievements.length),
    );
    final end = math.min(start + _achievementPageSize, _achievements.length);
    return _achievements.sublist(start, end);
  }

  Future<void> _changeWeek(int delta) async {
    if (delta > 0 && _currentWeekOffset == 0) return;
    final nextOffset = _currentWeekOffset + delta;
    final bounds = _weekBounds(nextOffset);
    setState(() {
      _currentWeekOffset = nextOffset;
    });
    try {
      final weeklyRaw = await ApiService.getWeeklyActivity(
        from: bounds.$1,
        to: bounds.$2,
      );
      if (!mounted) return;
      setState(() {
        _weeklyActivity = _normalizeWeeklyActivity(
          (weeklyRaw as List<dynamic>?) ?? <dynamic>[],
          bounds.$1,
        );
      });
    } catch (_) {
      if (!mounted) return;
      widget.showSnack('Wöchentliche Aktivität konnte nicht geladen werden.');
    }
  }

  String _profileInitials(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList(growable: false);
    if (parts.isEmpty) return 'SB';
    return parts.map((part) => part.characters.first.toUpperCase()).join();
  }

  Future<void> _pickProfileImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedFile == null) return;

      final pickedBytes = await pickedFile.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pickedProfileImageBytes = pickedBytes;
      });

      final updatedProfile = await ApiService.uploadProfileImage(
        pickedFile.path,
      );
      if (!mounted) return;
      setState(() {
        final nextUrl = _string(
          updatedProfile['profileImageUrl'],
          fallback: _string(updatedProfile['ProfileImageUrl']),
        );
        _profile['profileImageUrl'] = nextUrl;
        _profileImageUrl = nextUrl;
        _profileImageVersion = DateTime.now().millisecondsSinceEpoch;
      });
      await widget.onRefreshHeader();
      widget.showSnack('Profilbild aktualisiert.');
    } catch (e) {
      if (mounted) {
        setState(() => _pickedProfileImageBytes = null);
      }
      widget.showSnack('Profilbild konnte nicht gespeichert werden.');
    }
  }

  Future<void> _openProfileImageActions() async {
    final imageUrl = ApiService.mediaUrl(_profileImageUrl);
    final hasPhoto =
        (imageUrl != null && imageUrl.isNotEmpty) ||
        _pickedProfileImageBytes != null;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withOpacity(0.16),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: Colors.white,
                ),
                title: const Text(
                  'Foto auswählen',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _pickProfileImage();
                },
              ),
              if (hasPhoto)
                ListTile(
                  leading: const Icon(
                    Icons.delete_rounded,
                    color: Color(0xFFF87171),
                  ),
                  title: const Text(
                    'Aktuelles Foto entfernen',
                    style: TextStyle(
                      color: Color(0xFFFCA5A5),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await _removeProfileImage();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _removeProfileImage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text(
          'Profilbild entfernen?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Danach wird wieder das Standardbild angezeigt.',
          style: TextStyle(color: Colors.white.withOpacity(0.72)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final profile = await ApiService.removeProfileImage();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _profileImageUrl = null;
        _pickedProfileImageBytes = null;
        _profileImageVersion = DateTime.now().millisecondsSinceEpoch;
      });
      await widget.onRefreshHeader();
      widget.showSnack('Profilbild entfernt.');
    } catch (_) {
      widget.showSnack('Profilbild konnte nicht entfernt werden.');
    }
  }

  Widget _buildProfileAvatar(String userName) {
    final imageUrl = ApiService.mediaUrl(_profileImageUrl);
    final versionedImageUrl = imageUrl == null
        ? null
        : '$imageUrl${imageUrl.contains('?') ? '&' : '?'}v=$_profileImageVersion';
    final hasPhoto = imageUrl != null && imageUrl.isNotEmpty;
    final pickedProfileImageBytes = _pickedProfileImageBytes;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasPhoto ? null : const Color(0xFF1E293B),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEC4899).withOpacity(0.24),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipOval(
            child: pickedProfileImageBytes != null
                ? Image.memory(
                    pickedProfileImageBytes,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  )
                : hasPhoto
                ? Image.network(
                    versionedImageUrl!,
                    key: ValueKey(versionedImageUrl),
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) => _buildNoProfilePicture(),
                  )
                : _buildNoProfilePicture(),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openProfileImageActions,
              borderRadius: BorderRadius.circular(999),
              child: Ink(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEC4899),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoProfilePicture() {
    return Image.asset(_noProfilePictureAsset, fit: BoxFit.cover);
  }

  void _openSettings() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final topInset = MediaQuery.of(ctx).padding.top;
        final email = _string(
          _profile['email'],
          fallback: _string(_profile['Email']),
        );
        final canEditUsername = !_isUsernameChangeLocked;
        return StatefulBuilder(
          builder: (ctx, modalSetState) {
            return Padding(
              padding: EdgeInsets.only(
                top: topInset + 56,
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Einstellungen',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white70,
                            ),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Profil',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _usernameController,
                        readOnly: !canEditUsername,
                        style: TextStyle(
                          color: canEditUsername
                              ? Colors.white
                              : Colors.white54,
                        ),
                        decoration: _settingsInputDecoration(
                          'Benutzername',
                        ).copyWith(helperText: _usernameChangeHint),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        enabled: false,
                        initialValue: email,
                        style: const TextStyle(color: Colors.white38),
                        decoration: _disabledSettingsInputDecoration('E-Mail'),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: _GradientActionButton(
                          onPressed: () async {
                            final saved = await _saveProfile();
                            if (saved && mounted) Navigator.of(ctx).pop();
                          },
                          label: 'Speichern',
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Fortschritt',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.white.withOpacity(0.04),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildProgressRow(
                              'Level',
                              '${_toInt(_map(_profile['avatar'])['level'], fallback: 1)}',
                            ),
                            _buildProgressRow(
                              'XP',
                              _formatCompactNumber(
                                _toInt(
                                  _profile['totalXp'],
                                  fallback: _toInt(
                                    _map(_profile['avatar'])['experience'],
                                  ),
                                ),
                              ),
                            ),
                            _buildProgressRow(
                              'Challenges',
                              '${_toInt(_profileStats['completedChallenges'])}',
                            ),
                            _buildProgressRow(
                              'Streak',
                              '${_toInt(_profileStats['currentStreak'])} Tage',
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Benachrichtigungen',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildSettingsTile(
                        icon: Icons.notifications_active_rounded,
                        iconColor: const Color(0xFFFDA4AF),
                        title: 'Notifications',
                        subtitle: 'Neue Anfragen und Challenges in der App.',
                        trailing: Switch.adaptive(
                          value: _notificationsEnabled,
                          activeThumbColor: const Color(0xFFEC4899),
                          onChanged: _settingsBusy
                              ? null
                              : (value) => _setNotificationsEnabled(
                                  value,
                                  modalSetState,
                                ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Health Sync',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white.withOpacity(0.04),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 0,
                              ),
                              leading: _buildSettingsImageIcon(
                                _appleHealthLogoAsset,
                              ),
                              title: const Text(
                                'Apple Health',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                'Holt deine freigegebenen Health-Daten automatisch.',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 11,
                                ),
                              ),
                              trailing: Switch.adaptive(
                                value: _healthSyncEnabled,
                                activeThumbColor: const Color(0xFFEC4899),
                                onChanged: _settingsBusy
                                    ? null
                                    : (value) => _setHealthSyncEnabled(
                                        value,
                                        modalSetState,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Sicherheit',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _oldPasswordController,
                        style: const TextStyle(color: Colors.white),
                        obscureText: true,
                        decoration: _settingsInputDecoration('Altes Passwort'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _newPasswordController,
                        style: const TextStyle(color: Colors.white),
                        obscureText: true,
                        decoration: _settingsInputDecoration('Neues Passwort'),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () async {
                            await _changePassword();
                            if (mounted) Navigator.of(ctx).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.18),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Passwort ändern'),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Account',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white.withOpacity(0.04),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 2,
                              ),
                              leading: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: const Color(
                                    0xFFEC4899,
                                  ).withOpacity(0.14),
                                ),
                                child: const Icon(
                                  Icons.logout_rounded,
                                  color: Color(0xFFFDA4AF),
                                  size: 20,
                                ),
                              ),
                              title: const Text(
                                'Abmelden',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                'Du wirst auf diesem Gerät ausgeloggt.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white38,
                              ),
                              onTap: () async {
                                await ApiService.logout();
                                if (!mounted) return;
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                  (_) => false,
                                );
                              },
                            ),
                            Divider(
                              height: 1,
                              color: Colors.white.withOpacity(0.08),
                            ),
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 2,
                              ),
                              leading: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.red.withOpacity(0.12),
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Color(0xFFFCA5A5),
                                  size: 20,
                                ),
                              ),
                              title: const Text(
                                'Account löschen',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                email.isEmpty
                                    ? 'Dieser Schritt kann nicht rückgängig gemacht werden.'
                                    : 'Entfernt $email dauerhaft aus der App.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white38,
                              ),
                              onTap: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (dctx) => AlertDialog(
                                    title: const Text('Account löschen'),
                                    content: const Text(
                                      'Möchtest du deinen Account wirklich löschen? Diese Aktion ist endgültig.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(dctx).pop(false),
                                        child: const Text('Abbrechen'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(dctx).pop(true),
                                        child: const Text('Löschen'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await _deleteAccount();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        leading: _buildSettingsIcon(icon, iconColor),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
        ),
        trailing: trailing,
      ),
    );
  }

  Widget _buildSettingsIcon(IconData icon, Color color) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.14),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildSettingsImageIcon(String asset) {
    return SizedBox(
      width: 42,
      height: 42,
      child: Center(
        child: Image.asset(asset, width: 34, height: 34, fit: BoxFit.contain),
      ),
    );
  }

  InputDecoration _settingsInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.72)),
      helperStyle: TextStyle(
        color: Colors.white.withOpacity(0.46),
        fontSize: 11,
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.04),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFFEC4899)),
      ),
    );
  }

  InputDecoration _disabledSettingsInputDecoration(String label) {
    return _settingsInputDecoration(label).copyWith(
      filled: true,
      fillColor: Colors.white.withOpacity(0.025),
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.38)),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.07)),
      ),
    );
  }

  Widget _buildProgressRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Widget icon,
    Color? accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon,
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.66),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final userName = _usernameController.text.isNotEmpty
        ? _usernameController.text
        : 'Benutzer';
    final email = _string(
      _profile['email'],
      fallback: _string(_profile['Email'], fallback: 'Keine E-Mail'),
    );
    final unlockedCount = _achievements
        .where((dynamic item) => _map(item)['unlocked'] == true)
        .length;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _SectionCard(
            title: 'Mein Profil',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildProfileAvatar(userName),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.settings_rounded,
                    color: Colors.white70,
                  ),
                  onPressed: _openSettings,
                  tooltip: 'Einstellungen',
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Stats overview (mobile-friendly)
          _SectionCard(
            title: 'Statistiken',
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = constraints.maxWidth >= 720;
                final crossAxisCount = isTablet ? 4 : 2;
                final spacing = 8.0;
                final itemWidth =
                    (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                    crossAxisCount;

                final cards = [
                  _buildStatCard(
                    label: 'Workouts gesamt',
                    value: '${_profileStats['totalWorkouts'] ?? 0}',
                    icon: const Icon(
                      Icons.fitness_center,
                      color: Color(0xFFA855F7),
                    ),
                  ),
                  _buildStatCard(
                    label: 'Trainingszeit',
                    value: '${_profileStats['trainingHours'] ?? 0}h',
                    icon: const Icon(Icons.timer, color: Color(0xFF60A5FA)),
                  ),
                  _buildStatCard(
                    label: 'Kalorien',
                    value: '${_profileStats['caloriesBurned'] ?? 0}',
                    icon: const Icon(
                      Icons.local_fire_department,
                      color: Color(0xFFF97316),
                    ),
                  ),
                  _buildStatCard(
                    label: 'Längster Streak',
                    value: '${_profileStats['longestStreak'] ?? 0} Tage',
                    icon: const Icon(
                      Icons.emoji_events,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                ];

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: cards
                      .map((card) => SizedBox(width: itemWidth, child: card))
                      .toList(growable: false),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // Achievements carousel
          _SectionCard(
            title: 'Achievements',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$unlockedCount / ${_achievements.length} freigeschaltet',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.68),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _currentAchievementIndex == 0
                          ? null
                          : () {
                              setState(() {
                                _currentAchievementIndex = math.max(
                                  0,
                                  _currentAchievementIndex -
                                      _achievementPageSize,
                                );
                              });
                            },
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                      ),
                      color: Colors.white70,
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      onPressed:
                          _currentAchievementIndex >=
                              _lastAchievementPageStart(_achievements.length)
                          ? null
                          : () {
                              setState(() {
                                _currentAchievementIndex = math.min(
                                  _lastAchievementPageStart(
                                    _achievements.length,
                                  ),
                                  _currentAchievementIndex +
                                      _achievementPageSize,
                                );
                              });
                            },
                      icon: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 18,
                      ),
                      color: Colors.white70,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 8.0;
                    const columns = 2;
                    final cardHeight = constraints.maxWidth < 380
                        ? 158.0
                        : 148.0;
                    final itemCount = _visibleAchievements.length;
                    final itemWidth = itemCount == 0
                        ? constraints.maxWidth
                        : (constraints.maxWidth - spacing) / columns;

                    if (itemCount == 0) {
                      return const Text(
                        'Noch keine Achievements vorhanden.',
                        style: TextStyle(color: Colors.white70),
                      );
                    }

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: _visibleAchievements
                          .map((dynamic item) {
                            return SizedBox(
                              width: itemWidth,
                              height: cardHeight,
                              child: _AchievementCard(achievement: _map(item)),
                            );
                          })
                          .toList(growable: false),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Weekly activity (simple horizontal week view)
          _SectionCard(
            title: 'Wöchentliche Aktivität',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _weekLabel,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.68),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _changeWeek(-1),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                      ),
                      color: Colors.white70,
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      onPressed: _currentWeekOffset == 0
                          ? null
                          : () => _changeWeek(1),
                      icon: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 18,
                      ),
                      color: Colors.white70,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 8.0;
                    final cardWidth =
                        (constraints.maxWidth - spacing * 2).clamp(
                          0.0,
                          9999.0,
                        ) /
                        3;

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _weeklyActivity
                            .asMap()
                            .entries
                            .map((entry) {
                              final isLast =
                                  entry.key == _weeklyActivity.length - 1;
                              final day = _map(entry.value);
                              final reps = _toInt(day['reps']);
                              final done = day['workoutDone'] == true;
                              final isToday = day['isToday'] == true;
                              return Container(
                                width: cardWidth,
                                margin: EdgeInsets.only(
                                  right: isLast ? 0 : spacing,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: done
                                      ? const Color(0xFF14532D)
                                      : Colors.white.withOpacity(0.04),
                                  border: Border.all(
                                    color: isToday
                                        ? const Color(0xFFFBBF24)
                                        : done
                                        ? const Color(
                                            0xFF22C55E,
                                          ).withOpacity(0.6)
                                        : Colors.white.withOpacity(0.08),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      _string(day['name']),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.84),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _string(day['dateDisplay']),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.62),
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    done
                                        ? Image.asset(
                                            'assets/Star_Pixel.png',
                                            width: 20,
                                            height: 20,
                                            fit: BoxFit.contain,
                                          )
                                        : const Icon(
                                            Icons.remove,
                                            color: Colors.white24,
                                          ),
                                    const SizedBox(height: 8),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        done ? '$reps Reps' : '-',
                                        maxLines: 1,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            })
                            .toList(growable: false),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Recent activities
          _SectionCard(
            title: 'Letzte Aktivitäten',
            child: Column(
              children: _recentActivities
                  .map((act) {
                    final a = _map(act);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.white.withOpacity(0.04),
                            ),
                            child: Center(child: Text(a['icon'] ?? '⚡')),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a['title'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  a['time'] ?? '',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 44,
                            child: Center(
                              child: Text(
                                '${_formatCompactNumber(_toInt(a['xp']))} XP',
                                style: const TextStyle(
                                  color: Color(0xFFFDE047),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyUserProfileSheet extends StatefulWidget {
  const _ReadOnlyUserProfileSheet({required this.seedProfile});

  final Map<String, dynamic> seedProfile;

  @override
  State<_ReadOnlyUserProfileSheet> createState() =>
      _ReadOnlyUserProfileSheetState();
}

class _ReadOnlyUserProfileSheetState extends State<_ReadOnlyUserProfileSheet> {
  late Map<String, dynamic> _profile;
  bool _loading = true;
  bool _failed = false;
  int _currentAchievementIndex = 0;

  @override
  void initState() {
    super.initState();
    _profile = widget.seedProfile;
    unawaited(_load());
  }

  Future<void> _load() async {
    final userId = _resolveUserId(widget.seedProfile);
    if (userId <= 0) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    try {
      final detailed = await ApiService.getUserProfile(userId);
      if (!mounted) return;
      setState(() {
        _profile = detailed;
        _loading = false;
        _currentAchievementIndex = 0;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  int _resolveUserId(Map<String, dynamic> profile) {
    return _toInt(
      profile['friendId'],
      fallback: _toInt(
        profile['fromUserId'],
        fallback: _toInt(profile['toUserId'], fallback: _toInt(profile['id'])),
      ),
    );
  }

  String get _userName => _string(
    _profile['userName'],
    fallback: _string(
      _profile['friendUserName'],
      fallback: _string(
        _profile['fromUserName'],
        fallback: _string(_profile['toUserName'], fallback: 'User'),
      ),
    ),
  );

  String? get _profileImageUrl =>
      _string(
        _profile['profileImageUrl'],
        fallback: _string(
          _profile['friendProfileImageUrl'],
          fallback: _string(
            _profile['fromUserProfileImageUrl'],
            fallback: _string(_profile['toUserProfileImageUrl']),
          ),
        ),
      ).isEmpty
      ? null
      : _string(
          _profile['profileImageUrl'],
          fallback: _string(
            _profile['friendProfileImageUrl'],
            fallback: _string(
              _profile['fromUserProfileImageUrl'],
              fallback: _string(_profile['toUserProfileImageUrl']),
            ),
          ),
        );

  int get _level => _toInt(
    _map(_profile['avatar'])['level'],
    fallback: _toInt(
      _profile['level'],
      fallback: _toInt(
        _profile['friendLevel'],
        fallback: _toInt(_profile['fromUserLevel']),
      ),
    ),
  );

  int get _totalXp => _toInt(
    _profile['totalXp'],
    fallback: _toInt(
      _map(_profile['avatar'])['experience'],
      fallback: _toInt(
        _profile['experience'],
        fallback: _toInt(_profile['friendExperience']),
      ),
    ),
  );

  String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  List<Map<String, dynamic>> _normalizedWeeklyActivity(List<dynamic> raw) {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final monday = normalizedToday.subtract(
      Duration(days: normalizedToday.weekday - 1),
    );
    final repsByDate = <String, int>{};

    for (final item in raw) {
      final map = _map(item);
      final rawDate = _string(map['date'], fallback: _string(map['Date']));
      if (rawDate.isEmpty) continue;
      final dateKey = rawDate.contains('T')
          ? rawDate.split('T').first
          : rawDate;
      repsByDate[dateKey] = _toInt(map['reps'], fallback: _toInt(map['Reps']));
    }

    const weekdayNames = <String>['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    final todayKey = _dateKey(today);
    return List<Map<String, dynamic>>.generate(7, (int index) {
      final day = monday.add(Duration(days: index));
      final key = _dateKey(day);
      final reps = repsByDate[key] ?? 0;
      return <String, dynamic>{
        'name': weekdayNames[index],
        'dateDisplay':
            '${day.day.toString().padLeft(2, '0')}.${day.month.toString().padLeft(2, '0')}',
        'reps': reps,
        'workoutDone': reps > 0,
        'isToday': key == todayKey,
      };
    });
  }

  String _weekLabel(List<Map<String, dynamic>> weeklyActivity) {
    if (weeklyActivity.isEmpty) return '';
    final first = weeklyActivity.first;
    final last = weeklyActivity.last;
    return '${_string(first['dateDisplay'])} - ${_string(last['dateDisplay'])}';
  }

  @override
  Widget build(BuildContext context) {
    final stats = _map(_profile['stats']);
    final achievements =
        (_profile['achievements'] as List<dynamic>?) ?? <dynamic>[];
    final unlockedCount = achievements
        .where((dynamic item) => _map(item)['unlocked'] == true)
        .length;
    final achievementStart = math.min(
      _currentAchievementIndex,
      _lastAchievementPageStart(achievements.length),
    );
    final visibleAchievements = achievements.sublist(
      achievementStart,
      math.min(achievementStart + _achievementPageSize, achievements.length),
    );
    final weeklyActivity = _normalizedWeeklyActivity(
      (_profile['weeklyActivity'] as List<dynamic>?) ?? <dynamic>[],
    );
    final recentActivities =
        (_profile['recentActivities'] as List<dynamic>?) ?? <dynamic>[];
    final bodyStage = _normalizeBodyStage(
      _string(
        _map(_profile['avatar'])['bodyStage'],
        fallback: _string(_profile['friendBodyStage']),
      ),
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.56,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.white.withOpacity(0.16),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _ReadOnlyProfileAvatar(
                      imageUrl: _profileImageUrl,
                      size: 74,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Level $_level • ${_formatCompactNumber(_totalXp)} XP',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.66),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (bodyStage.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: Colors.white.withOpacity(0.05),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                ),
                              ),
                              child: Text(
                                bodyStage,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  _SectionCard(
                    title: 'Statistiken',
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const spacing = 8.0;
                        final itemWidth = (constraints.maxWidth - spacing) / 2;
                        final cards = [
                          _ReadOnlyStatCard(
                            label: 'Workouts gesamt',
                            value: '${_toInt(stats['totalWorkouts'])}',
                            icon: Icons.fitness_center,
                            color: const Color(0xFFA855F7),
                          ),
                          _ReadOnlyStatCard(
                            label: 'Trainingszeit',
                            value:
                                '${_toDouble(stats['trainingHours']).toStringAsFixed(1)}h',
                            icon: Icons.timer,
                            color: const Color(0xFF60A5FA),
                          ),
                          _ReadOnlyStatCard(
                            label: 'Kalorien',
                            value: '${_toInt(stats['caloriesBurned'])}',
                            icon: Icons.local_fire_department,
                            color: const Color(0xFFF97316),
                          ),
                          _ReadOnlyStatCard(
                            label: 'Längster Streak',
                            value: '${_toInt(stats['longestStreak'])} Tage',
                            icon: Icons.emoji_events,
                            color: const Color(0xFF22C55E),
                          ),
                        ];

                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: cards
                              .map(
                                (card) =>
                                    SizedBox(width: itemWidth, child: card),
                              )
                              .toList(growable: false),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SectionCard(
                    title: 'Achievements',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '$unlockedCount / ${achievements.length} freigeschaltet',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.68),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: achievementStart == 0
                                  ? null
                                  : () {
                                      setState(() {
                                        _currentAchievementIndex = math.max(
                                          0,
                                          achievementStart -
                                              _achievementPageSize,
                                        );
                                      });
                                    },
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 18,
                              ),
                              color: Colors.white70,
                              visualDensity: VisualDensity.compact,
                            ),
                            IconButton(
                              onPressed:
                                  achievementStart >=
                                      _lastAchievementPageStart(
                                        achievements.length,
                                      )
                                  ? null
                                  : () {
                                      setState(() {
                                        _currentAchievementIndex = math.min(
                                          _lastAchievementPageStart(
                                            achievements.length,
                                          ),
                                          achievementStart +
                                              _achievementPageSize,
                                        );
                                      });
                                    },
                              icon: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 18,
                              ),
                              color: Colors.white70,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (visibleAchievements.isEmpty) {
                              return const Text(
                                'Noch keine Achievements vorhanden.',
                                style: TextStyle(color: Colors.white70),
                              );
                            }

                            const spacing = 8.0;
                            final cardHeight = constraints.maxWidth < 380
                                ? 158.0
                                : 148.0;
                            final itemWidth =
                                (constraints.maxWidth - spacing) / 2;

                            return Wrap(
                              spacing: spacing,
                              runSpacing: spacing,
                              children: visibleAchievements
                                  .map((dynamic item) {
                                    return SizedBox(
                                      width: itemWidth,
                                      height: cardHeight,
                                      child: _AchievementCard(
                                        achievement: _map(item),
                                      ),
                                    );
                                  })
                                  .toList(growable: false),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SectionCard(
                    title: 'Wöchentliche Aktivität',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _weekLabel(weeklyActivity),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.68),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: weeklyActivity
                                .map((day) {
                                  final reps = _toInt(day['reps']);
                                  final done = day['workoutDone'] == true;
                                  final isToday = day['isToday'] == true;
                                  return Container(
                                    width: 104,
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: done
                                          ? const Color(0xFF14532D)
                                          : Colors.white.withOpacity(0.04),
                                      border: Border.all(
                                        color: isToday
                                            ? const Color(0xFFFBBF24)
                                            : done
                                            ? const Color(
                                                0xFF22C55E,
                                              ).withOpacity(0.6)
                                            : Colors.white.withOpacity(0.08),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          _string(day['name']),
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.84,
                                            ),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _string(day['dateDisplay']),
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.62,
                                            ),
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        done
                                            ? Image.asset(
                                                'assets/Star_Pixel.png',
                                                width: 20,
                                                height: 20,
                                                fit: BoxFit.contain,
                                              )
                                            : const Icon(
                                                Icons.remove,
                                                color: Colors.white24,
                                              ),
                                        const SizedBox(height: 8),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            done ? '$reps Reps' : '-',
                                            maxLines: 1,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                })
                                .toList(growable: false),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SectionCard(
                    title: 'Letzte Aktivitäten',
                    child: recentActivities.isEmpty
                        ? Text(
                            _failed
                                ? 'Profil-Grunddaten geladen, Aktivität gerade nicht verfügbar.'
                                : 'Noch keine letzten Aktivitäten vorhanden.',
                            style: const TextStyle(color: Colors.white70),
                          )
                        : Column(
                            children: recentActivities
                                .map((dynamic item) {
                                  final activity = _map(item);
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            color: Colors.white.withOpacity(
                                              0.05,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.08,
                                              ),
                                            ),
                                          ),
                                          child: Icon(
                                            _activityIcon(
                                              _string(activity['type']),
                                            ),
                                            color: const Color(0xFFFDA4AF),
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _string(activity['title']),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                _formatActivityTimestamp(
                                                  _string(
                                                    activity['timestamp'],
                                                  ),
                                                ),
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.56),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '${_formatCompactNumber(_toInt(activity['xp']))} XP',
                                          style: const TextStyle(
                                            color: Color(0xFFFDE047),
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                })
                                .toList(growable: false),
                          ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement});

  final Map<String, dynamic> achievement;

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement['unlocked'] == true;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: unlocked
            ? const Color(0xFFFBBF24).withOpacity(0.14)
            : Colors.white.withOpacity(0.03),
        border: Border.all(
          color: unlocked
              ? const Color(0xFFFBBF24).withOpacity(0.42)
              : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _string(achievement['title'], fallback: 'Achievement'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                unlocked ? Icons.check_circle : Icons.lock,
                color: unlocked ? const Color(0xFFFBBF24) : Colors.white54,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 7),
          Expanded(
            child: Text(
              _string(achievement['description']),
              maxLines: 4,
              overflow: TextOverflow.fade,
              style: TextStyle(
                color: Colors.white.withOpacity(0.72),
                height: 1.28,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyProfileAvatar extends StatelessWidget {
  const _ReadOnlyProfileAvatar({required this.imageUrl, required this.size});

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final resolved = ApiService.mediaUrl(imageUrl);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: resolved == null ? const Color(0xFF1E293B) : null,
      ),
      child: ClipOval(
        child: resolved == null
            ? Image.asset(_noProfilePictureAsset, fit: BoxFit.cover)
            : Image.network(
                resolved,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Image.asset(_noProfilePictureAsset, fit: BoxFit.cover),
              ),
      ),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.onPressed,
    required this.label,
    this.compact = false,
    this.enabled = true,
  });

  final VoidCallback? onPressed;
  final String label;
  final bool compact;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final interactive = enabled && onPressed != null;
    return ElevatedButton(
      onPressed: interactive ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        disabledBackgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: interactive
              ? const LinearGradient(
                  colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
                )
              : null,
          color: interactive ? null : Colors.white.withOpacity(0.08),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: SizedBox(
          height: compact ? 38 : 46,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SentStatusPill extends StatelessWidget {
  const _SentStatusPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: const Text(
        'Sent',
        style: TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _ReadOnlyStatCard extends StatelessWidget {
  const _ReadOnlyStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.66),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, fontSize: 9),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

IconData _activityIcon(String type) {
  return switch (type.toLowerCase()) {
    'workout' => Icons.fitness_center_rounded,
    'quest' => Icons.flag_rounded,
    'achievement' => Icons.workspace_premium_rounded,
    'level' => Icons.auto_awesome_rounded,
    _ => Icons.bolt_rounded,
  };
}

String _formatActivityTimestamp(String raw) {
  if (raw.isEmpty) return '';
  final timestamp = DateTime.tryParse(raw)?.toLocal();
  if (timestamp == null) return raw;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(timestamp.year, timestamp.month, timestamp.day);
  final difference = today.difference(day).inDays;
  final hh = timestamp.hour.toString().padLeft(2, '0');
  final mm = timestamp.minute.toString().padLeft(2, '0');

  if (difference == 0) return 'Heute, $hh:$mm';
  if (difference == 1) return 'Gestern, $hh:$mm';
  return '${timestamp.day.toString().padLeft(2, '0')}.${timestamp.month.toString().padLeft(2, '0')}.${timestamp.year}';
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return <String, dynamic>{};
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double _toDouble(dynamic value, {double fallback = 0}) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

String _string(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final v = value.toString();
  return v.isEmpty ? fallback : v;
}
