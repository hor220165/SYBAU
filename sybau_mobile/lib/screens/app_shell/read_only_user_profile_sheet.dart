part of '../app_shell_screen.dart';

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
  String _activityMode = 'workouts';
  final ScrollController _activityHeatmapScrollController = ScrollController();

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
      _queueActivityScrollToCurrent();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  void dispose() {
    _activityHeatmapScrollController.dispose();
    super.dispose();
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

  bool get _isStepsActivityMode => _activityMode == 'steps';

  int get _selectedActivityYear {
    final rawYears =
        (_profile['activityYears'] as List<dynamic>?) ??
        (_profile['ActivityYears'] as List<dynamic>?) ??
        <dynamic>[];
    final years =
        rawYears
            .map((dynamic value) => _toInt(value))
            .where((year) => year > 2000)
            .toList()
          ..sort((a, b) => b.compareTo(a));
    return years.isEmpty ? DateTime.now().year : years.first;
  }

  ({DateTime $1, DateTime $2}) _activityHeatmapBounds(int year) {
    final now = DateTime.now();
    final firstDay = DateTime(year, 1, 1);
    final lastDay = year == now.year
        ? DateTime(now.year, now.month, now.day)
        : DateTime(year, 12, 31);
    final start = firstDay.subtract(Duration(days: firstDay.weekday - 1));
    return ($1: start, $2: lastDay);
  }

  List<Map<String, dynamic>> _normalizeActivityHeatmap(
    List<dynamic> raw,
    DateTime start,
    DateTime end,
  ) {
    final repsByDate = <String, int>{};
    final stepsByDate = <String, int>{};
    for (final item in raw) {
      final map = _map(item);
      final rawDate = _string(map['date'], fallback: _string(map['Date']));
      if (rawDate.isEmpty) continue;
      final dateKey = rawDate.contains('T')
          ? rawDate.split('T').first
          : rawDate;
      repsByDate[dateKey] = _toInt(map['reps'], fallback: _toInt(map['Reps']));
      stepsByDate[dateKey] = _toInt(
        map['steps'],
        fallback: _toInt(map['Steps']),
      );
    }

    final today = DateTime.now();
    final todayKey = _dateKey(DateTime(today.year, today.month, today.day));
    final dayCount = end.difference(start).inDays + 1;
    return List<Map<String, dynamic>>.generate(dayCount, (index) {
      final day = start.add(Duration(days: index));
      final key = _dateKey(day);
      return <String, dynamic>{
        'date': key,
        'day': day.day,
        'month': day.month,
        'reps': repsByDate[key] ?? 0,
        'steps': stepsByDate[key] ?? 0,
        'isToday': key == todayKey,
      };
    });
  }

  List<List<Map<String, dynamic>>> _activityHeatmapWeeks(
    List<Map<String, dynamic>> days,
  ) {
    final weeks = <List<Map<String, dynamic>>>[];
    for (var index = 0; index < days.length; index += 7) {
      weeks.add(days.skip(index).take(7).toList(growable: false));
    }
    return weeks;
  }

  int _activityValue(Map<String, dynamic> day) =>
      _isStepsActivityMode ? _toInt(day['steps']) : _toInt(day['reps']);

  int _activityLevel(int value) {
    if (value <= 0) return 0;
    if (_isStepsActivityMode) {
      if (value < 2500) return 1;
      if (value < 6000) return 2;
      if (value < 10000) return 3;
      return 4;
    }
    if (value < 30) return 1;
    if (value < 60) return 2;
    if (value < 100) return 3;
    return 4;
  }

  Color _activityColor(int value) {
    final colors = _isStepsActivityMode
        ? const <int, Color>{
            1: Color(0xFF9A3412),
            2: Color(0xFFEA580C),
            3: Color(0xFFF97316),
            4: Color(0xFFFB923C),
          }
        : const <int, Color>{
            1: Color(0xFF9D174D),
            2: Color(0xFFDB2777),
            3: Color(0xFFEC4899),
            4: Color(0xFFFF4FB3),
          };
    switch (_activityLevel(value)) {
      case 1:
        return colors[1]!.withOpacity(0.56);
      case 2:
        return colors[2]!.withOpacity(0.72);
      case 3:
        return colors[3]!.withOpacity(0.88);
      case 4:
        return colors[4]!;
      default:
        return Colors.white.withOpacity(0.06);
    }
  }

  String _activityMonthLabel(List<Map<String, dynamic>> week) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mär',
      'Apr',
      'Mai',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Okt',
      'Nov',
      'Dez',
    ];
    for (final day in week) {
      final dayOfMonth = _toInt(day['day']);
      final month = _toInt(day['month']);
      if (dayOfMonth == 1 && month >= 1 && month <= 12) {
        return months[month - 1];
      }
    }
    return '';
  }

  int _activityTotal(List<Map<String, dynamic>> days) =>
      days.fold<int>(0, (sum, day) => sum + _activityValue(day));

  void _queueActivityScrollToCurrent() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_activityHeatmapScrollController.hasClients) return;
      final maxOffset =
          _activityHeatmapScrollController.position.maxScrollExtent;
      if (maxOffset <= 0) return;
      _activityHeatmapScrollController.jumpTo(maxOffset);
    });
  }

  Widget _buildActivityHeatmap(List<dynamic> rawActivity) {
    final year = _selectedActivityYear;
    final bounds = _activityHeatmapBounds(year);
    final days = _normalizeActivityHeatmap(rawActivity, bounds.$1, bounds.$2);
    final weeks = _activityHeatmapWeeks(days);
    final accent = _isStepsActivityMode
        ? const Color(0xFFFB923C)
        : const Color(0xFFFF4FB3);
    const cellSize = 14.0;
    const cellGap = 5.0;
    const weekdayWidth = 26.0;
    final weekHeight = cellSize * 7 + cellGap * 6;
    const weekdayLabels = <String>['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

    Widget buildCell(Map<String, dynamic> day) {
      final value = _activityValue(day);
      final isToday = day['isToday'] == true;
      return Container(
        width: cellSize,
        height: cellSize,
        margin: const EdgeInsets.only(bottom: cellGap),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: _activityColor(value),
          border: Border.all(
            color: isToday
                ? Colors.white.withOpacity(0.76)
                : Colors.white.withOpacity(0.06),
            width: isToday ? 1.5 : 1,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isStepsActivityMode
              ? '${_formatCompactNumber(_activityTotal(days))} Schritte in $year'
              : '${_formatCompactNumber(_activityTotal(days))} Reps in $year',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withOpacity(0.68),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: CupertinoSlidingSegmentedControl<String>(
            groupValue: _activityMode,
            backgroundColor: Colors.white.withOpacity(0.06),
            thumbColor: accent.withOpacity(0.32),
            padding: const EdgeInsets.all(3),
            children: const {
              'workouts': Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  'Workouts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              'steps': Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  'Schritte',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            },
            onValueChanged: (value) {
              if (value == null) return;
              setState(() => _activityMode = value);
            },
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const SizedBox(height: 19),
                  SizedBox(
                    width: weekdayWidth,
                    height: weekHeight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: weekdayLabels
                          .map(
                            (label) => SizedBox(
                              height: cellSize,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.62),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _activityHeatmapScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: weeks
                              .map(
                                (week) => Container(
                                  width: cellSize,
                                  margin: const EdgeInsets.only(right: cellGap),
                                  child: Text(
                                    _activityMonthLabel(week),
                                    overflow: TextOverflow.visible,
                                    softWrap: false,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.66),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: weeks
                              .map(
                                (week) => Padding(
                                  padding: const EdgeInsets.only(
                                    right: cellGap,
                                  ),
                                  child: Column(
                                    children: week
                                        .map((day) => buildCell(day))
                                        .toList(growable: false),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
    final activityRaw =
        (_profile['weeklyActivity'] as List<dynamic>?) ??
        (_profile['WeeklyActivity'] as List<dynamic>?) ??
        <dynamic>[];
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
                    title: _lt(de: 'Statistiken', en: 'Statistics'),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const spacing = 8.0;
                        final itemWidth = (constraints.maxWidth - spacing) / 2;
                        final cards = [
                          _ReadOnlyStatCard(
                            label: _lt(
                              de: 'Workouts gesamt',
                              en: 'Total workouts',
                            ),
                            value: '${_toInt(stats['totalWorkouts'])}',
                            icon: Icons.fitness_center,
                            color: Color(0xFFA855F7),
                          ),
                          _ReadOnlyStatCard(
                            label: _lt(
                              de: 'Trainingszeit',
                              en: 'Training time',
                            ),
                            value:
                                '${_toDouble(stats['trainingHours']).toStringAsFixed(1)}h',
                            icon: Icons.timer,
                            color: Color(0xFF60A5FA),
                          ),
                          _ReadOnlyStatCard(
                            label: _lt(de: 'Kalorien', en: 'Calories'),
                            value: '${_toInt(stats['caloriesBurned'])}',
                            icon: Icons.local_fire_department,
                            color: Color(0xFFF97316),
                          ),
                          _ReadOnlyStatCard(
                            label: _lt(
                              de: 'Längster Streak',
                              en: 'Longest streak',
                            ),
                            value: _lt(
                              de: '${_toInt(stats['longestStreak'])} Tage',
                              en: '${_toInt(stats['longestStreak'])} days',
                            ),
                            icon: Icons.emoji_events,
                            color: Color(0xFF22C55E),
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
                    child: _buildActivityHeatmap(activityRaw),
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
                                            color: Color(0xFFFDA4AF),
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
