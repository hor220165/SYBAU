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
                                          ? Color(0xFF14532D)
                                          : Colors.white.withOpacity(0.04),
                                      border: Border.all(
                                        color: isToday
                                            ? Color(0xFFFBBF24)
                                            : done
                                            ? Color(0xFF22C55E).withOpacity(0.6)
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
                                            done ? '$reps Einheiten' : '-',
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
