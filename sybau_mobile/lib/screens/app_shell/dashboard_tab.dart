part of '../app_shell_screen.dart';

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

  int get _progressPercent {
    final denom = _xpForNextLevel <= 0 ? 1 : _xpForNextLevel;
    final ratio = (_currentXp / denom).clamp(0, 1);
    return (ratio * 100).floor();
  }

  double get _arcProgress => _progressPercent / 100;

  String _rarityOf(Booster booster) {
    final explicit = booster.rarity.toLowerCase();
    if (explicit == 'common' ||
        explicit == 'rare' ||
        explicit == 'epic' ||
        explicit == 'legendary' ||
        explicit == 'mythic') {
      return explicit;
    }

    final total = booster.xpBoostPercentage + booster.coinBoostPercentage;
    if (total >= 100) return 'mythic';
    if (total >= 60) return 'legendary';
    if (total >= 40) return 'epic';
    if (total >= 20) return 'rare';
    return 'common';
  }

  Color _boosterAccent(Booster booster) {
    switch (_rarityOf(booster)) {
      case 'mythic':
        return const Color(0xFFF472B6);
      case 'legendary':
        return const Color(0xFFFBBF24);
      case 'epic':
        return const Color(0xFFC084FC);
      case 'rare':
        return const Color(0xFF60A5FA);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  double _slotTintOpacity(String rarity) {
    switch (rarity) {
      case 'mythic':
        return 0.18;
      case 'legendary':
        return 0.17;
      case 'epic':
        return 0.16;
      case 'rare':
        return 0.15;
      default:
        return 0.12;
    }
  }

  double _slotBorderOpacity(String rarity) {
    switch (rarity) {
      case 'mythic':
        return 0.44;
      case 'legendary':
        return 0.48;
      case 'epic':
        return 0.38;
      case 'rare':
        return 0.36;
      default:
        return 0.28;
    }
  }

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

  Widget _buildEquipmentSlot(int index) {
    final booster = _boostSlots[index];
    final isEquipped = booster != null;
    final rarity = booster == null ? 'empty' : _rarityOf(booster);
    final accent = booster == null
        ? const Color(0xFF94A3B8)
        : _boosterAccent(booster);

    return GestureDetector(
      onTap: widget.onOpenAvatar,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: isEquipped
              ? RadialGradient(
                  center: const Alignment(0, -0.35),
                  radius: 0.9,
                  colors: [
                    accent.withValues(alpha: _slotTintOpacity(rarity) + 0.08),
                    accent.withValues(alpha: _slotTintOpacity(rarity)),
                    const Color(0xFF0F172A).withValues(alpha: 0.48),
                  ],
                )
              : null,
          color: isEquipped
              ? null
              : const Color(0xFF0F172A).withValues(alpha: 0.55),
          border: Border.all(
            color: isEquipped
                ? accent.withValues(alpha: _slotBorderOpacity(rarity))
                : const Color(0xFF94A3B8).withValues(alpha: 0.25),
          ),
          boxShadow: isEquipped
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.16),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: isEquipped
              ? SizedBox(
                  width: 90,
                  height: 90,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -6),
                        child: booster.imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: _buildMediaImageFromUrl(
                                  booster.imageUrl,
                                  width: 46,
                                  height: 46,
                                  fit: BoxFit.contain,
                                  fallback: () => Text(
                                    '⚡',
                                    style: TextStyle(
                                      fontSize: 32,
                                      color: accent,
                                    ),
                                  ),
                                ),
                              )
                            : Text(
                                '⚡',
                                style: TextStyle(fontSize: 32, color: accent),
                              ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 11,
                        child: Center(
                          child: _buildBoosterPercentBadges(
                            booster,
                            fontSize: 10,
                            horizontalPadding: 4,
                            verticalPadding: 0,
                            gap: 5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Text(
                  _lt(de: 'Leer', en: 'Empty'),
                  style: const TextStyle(
                    color: Colors.white24,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
                        Color(0xFF2563EB).withOpacity(0.10),
                        Color(0xFF0EA5E9).withOpacity(0.05),
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
                                  Color(0xFF2563EB).withOpacity(0.62),
                                  Color(0xFF2563EB).withOpacity(0.16),
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
                                '${(_xpForNextLevel - _currentXp).clamp(0, 1 << 30)} ${_lt(de: 'bis', en: 'to')} Lv${_level + 1}',
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
                            _lt(de: 'Gesamt XP', en: 'Total XP'),
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
                          color: Color(0xFFF97316),
                          value: _lt(
                            de: '$_currentStreak Tage',
                            en: '$_currentStreak days',
                          ),
                          label: 'Streak',
                        ),
                      ),
                      Expanded(
                        child: _DashBarItem(
                          icon: Icons.emoji_events,
                          color: Color(0xFFFBBF24),
                          value: '$_unlockedAchievements/$_totalAchievements',
                          label: 'Badges',
                        ),
                      ),
                      Expanded(
                        child: _DashBarItem(
                          icon: Icons.track_changes,
                          color: Color(0xFFA855F7),
                          value: '$_completedQuests/$_totalQuests',
                          label: 'Quests',
                        ),
                      ),
                      Expanded(
                        child: _DashBarItem(
                          icon: Icons.military_tech,
                          color: Color(0xFFEC4899),
                          value: _leaderboardRank,
                          label: _lt(de: 'Rang', en: 'Rank'),
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
                value: _lt(
                  de: '$_currentStreak Tage',
                  en: '$_currentStreak days',
                ),
                accent: Color(0xFFF97316),
              ),
              _DashStatCard(
                icon: Icons.emoji_events,
                label: 'Achievements',
                value: '$_unlockedAchievements/$_totalAchievements',
                accent: Color(0xFFFBBF24),
              ),
              _DashStatCard(
                icon: Icons.track_changes,
                label: 'Quests',
                value: '$_completedQuests/$_totalQuests',
                trend: _lt(
                  de: '$_activeQuests aktiv',
                  en: '$_activeQuests active',
                ),
                accent: Color(0xFFA855F7),
              ),
              _DashStatCard(
                icon: Icons.trending_up,
                label: _lt(de: 'Gesamt XP', en: 'Total XP'),
                value: _formatCompactNumber(_totalXp),
                trend: _lt(
                  de: '+${_formatCompactNumber(_todayXp)} XP heute',
                  en: '+${_formatCompactNumber(_todayXp)} XP today',
                ),
                accent: Color(0xFF22D3EE),
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
      ..color = Color(0xFF3B82F6).withOpacity(0.18);

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
