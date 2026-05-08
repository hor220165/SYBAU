import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'login_screen.dart';

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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;

  String _userName = 'Champion';
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
    _loadDashboardData();
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  int _intFrom(
    Map<String, dynamic> map,
    List<String> keys, {
    int fallback = 0,
  }) {
    for (final key in keys) {
      final value = map[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return fallback;
  }

  String _stringFrom(
    Map<String, dynamic> map,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return fallback;
  }

  Map<String, dynamic> _mapFrom(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return <String, dynamic>{};
  }

  Future<void> _loadDashboardData() async {
    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        ApiService.getProfile(),
        ApiService.getAchievements(),
        ApiService.getMyQuests(),
        ApiService.getProfileStats(),
        ApiService.getTodayXp(),
        ApiService.getLeaderboard(),
        ApiService.getUserBoosters(),
      ]);

      final profile = _mapFrom(results[0]);
      final achievements = (results[1] as List<dynamic>?) ?? <dynamic>[];
      final quests = (results[2] as List<dynamic>?) ?? <dynamic>[];
      final stats = _mapFrom(results[3]);
      final todayXpData = _mapFrom(results[4]);
      final leaderboard = (results[5] as List<dynamic>?) ?? <dynamic>[];
      final boostersRaw = (results[6] as List<dynamic>?) ?? <dynamic>[];

      final avatar = _mapFrom(profile['avatar']);
      final userName = _stringFrom(profile, <String>[
        'userName',
        'UserName',
      ], fallback: 'Champion');
      final level = _intFrom(avatar, <String>['level', 'Level'], fallback: 1);
      final currentXp = _intFrom(avatar, <String>['experience', 'Experience']);
      final xpForNextLevel = _intFrom(avatar, <String>[
        'xpForNextLevel',
        'XpForNextLevel',
      ], fallback: 1000);

      final boosters = boostersRaw
          .map((dynamic b) => Booster.fromJson(_mapFrom(b)))
          .where((Booster b) => b.id != null)
          .toList(growable: false);

      final slotNames = <String?>[
        avatar['boost1'] as String?,
        avatar['boost2'] as String?,
        avatar['boost3'] as String?,
        avatar['boost4'] as String?,
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

      int unlockedAchievements = 0;
      for (final item in achievements) {
        final map = _mapFrom(item);
        if (map['unlocked'] == true) unlockedAchievements++;
      }

      int completedQuests = 0;
      for (final item in quests) {
        final map = _mapFrom(item);
        if (map['isCompleted'] == true) completedQuests++;
      }

      String leaderboardRank = '-';
      final loweredUserName = userName.toLowerCase();
      for (int i = 0; i < leaderboard.length; i++) {
        final entry = _mapFrom(leaderboard[i]);
        final candidate = _stringFrom(entry, <String>[
          'userName',
          'UserName',
        ]).toLowerCase();
        if (candidate == loweredUserName) {
          final rank = _intFrom(entry, <String>[
            'rank',
            'Rank',
          ], fallback: i + 1);
          leaderboardRank = '#$rank';
          break;
        }
      }

      if (!mounted) return;
      setState(() {
        _userName = userName;
        _level = level;
        _currentXp = currentXp;
        _xpForNextLevel = xpForNextLevel;
        _totalXp = _intFrom(todayXpData, <String>['totalXp']);
        _todayXp = _intFrom(todayXpData, <String>['todayXp']);

        _currentStreak = _intFrom(stats, <String>['currentStreak']);
        _unlockedAchievements = unlockedAchievements;
        _totalAchievements = achievements.length;
        _completedQuests = completedQuests;
        _totalQuests = quests.length;
        _activeQuests = quests.length - completedQuests;
        _leaderboardRank = leaderboardRank;

        _ownedBoosters = boosters;
        for (int i = 0; i < 4; i++) {
          _boostSlots[i] = i < slots.length ? slots[i] : null;
        }

        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dashboard konnte nicht geladen werden.')),
      );
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
      onTap: () => _openBoosterModal(index),
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isEquipped
              ? const Color(0xFFA855F7).withOpacity(0.14)
              : const Color(0xFF0F172A).withOpacity(0.55),
          border: Border.all(
            color: isEquipped
                ? const Color(0xFFA855F7).withOpacity(0.45)
                : const Color(0xFFA855F7).withOpacity(0.25),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isEquipped ? '⚡' : '◈',
              style: TextStyle(
                fontSize: isEquipped ? 28 : 16,
                color: const Color(0xFFC084FC),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isEquipped ? '+${booster.bestBoostPercent}%' : 'Leer',
              style: TextStyle(
                color: isEquipped ? const Color(0xFFC084FC) : Colors.white24,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBarItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return SizedBox(
      width: 80,
      child: Column(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(height: 3),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    String? trend,
    required Color accent,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 18),
          const Spacer(),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (trend != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                trend,
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.sizeOf(context).width < 390;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Log out',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
            colors: [Color(0xFF0F0C29), Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  isSmall ? 12 : 16,
                  8,
                  isSmall ? 12 : 16,
                  20,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 6),
                    Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        Positioned(
                          top: 26,
                          child: Container(
                            width: isSmall ? 240 : 300,
                            height: isSmall ? 270 : 340,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF3B82F6).withOpacity(0.18),
                                  const Color(0xFF06B6D4).withOpacity(0.08),
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
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: isSmall ? 13 : 16,
                                letterSpacing: 3.4,
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
                                    const SizedBox(height: 8),
                                    _buildEquipmentSlot(1),
                                  ],
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  children: [
                                    Container(
                                      width: isSmall ? 120 : 150,
                                      height: isSmall ? 150 : 185,
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.sports_martial_arts,
                                        size: isSmall ? 94 : 118,
                                        color: const Color(0xFF93C5FD),
                                      ),
                                    ),
                                    Container(
                                      width: isSmall ? 95 : 120,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        gradient: RadialGradient(
                                          colors: [
                                            const Color(
                                              0xFF3B82F6,
                                            ).withOpacity(0.7),
                                            const Color(
                                              0xFF3B82F6,
                                            ).withOpacity(0.2),
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
                                    const SizedBox(height: 8),
                                    _buildEquipmentSlot(3),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 220,
                              height: 120,
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  CustomPaint(
                                    size: const Size(220, 120),
                                    painter: _XpArcPainter(
                                      progress: _arcProgress,
                                    ),
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
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          '${(_xpForNextLevel - _currentXp).clamp(0, 1 << 30)} bis Lv${_level + 1}',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.35,
                                            ),
                                            fontSize: 10,
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
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$_level',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 1,
                                  height: 18,
                                  color: Colors.white.withOpacity(0.08),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'Gesamt XP',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.3),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatCompactNumber(_totalXp),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12,
                              runSpacing: 10,
                              children: [
                                _buildStatsBarItem(
                                  icon: Icons.local_fire_department,
                                  iconColor: const Color(0xFFF97316),
                                  value: '$_currentStreak Tage',
                                  label: 'STREAK',
                                ),
                                _buildStatsBarItem(
                                  icon: Icons.emoji_events,
                                  iconColor: const Color(0xFFFBBF24),
                                  value:
                                      '$_unlockedAchievements/$_totalAchievements',
                                  label: 'BADGES',
                                ),
                                _buildStatsBarItem(
                                  icon: Icons.track_changes,
                                  iconColor: const Color(0xFFA855F7),
                                  value: '$_completedQuests/$_totalQuests',
                                  label: 'QUESTS',
                                ),
                                _buildStatsBarItem(
                                  icon: Icons.military_tech,
                                  iconColor: const Color(0xFFEC4899),
                                  value: _leaderboardRank,
                                  label: 'RANG',
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
                      childAspectRatio: 1.22,
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      children: [
                        _buildStatCard(
                          icon: Icons.local_fire_department,
                          label: 'Streak',
                          value: '$_currentStreak Tage',
                          accent: const Color(0xFFF97316),
                        ),
                        _buildStatCard(
                          icon: Icons.emoji_events,
                          label: 'Achievements',
                          value: '$_unlockedAchievements/$_totalAchievements',
                          accent: const Color(0xFFFBBF24),
                        ),
                        _buildStatCard(
                          icon: Icons.track_changes,
                          label: 'Quests',
                          value: '$_completedQuests/$_totalQuests',
                          trend: '$_activeQuests aktiv',
                          accent: const Color(0xFFA855F7),
                        ),
                        _buildStatCard(
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
              ),
      ),
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
