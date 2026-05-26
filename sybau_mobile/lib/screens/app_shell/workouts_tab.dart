part of '../app_shell_screen.dart';

class WorkoutsTab extends StatefulWidget {
  const WorkoutsTab({
    required this.onRefreshHeader,
    required this.onRewardEarned,
    required this.onQuestStatusChanged,
    required this.showSnack,
    super.key,
  });

  final Future<void> Function() onRefreshHeader;
  final void Function({int xp, int coins}) onRewardEarned;
  final Future<void> Function() onQuestStatusChanged;
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
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Map<int, int> _repsDraft = <int, int>{};
  final Map<int, String> _timeDraft = <int, String>{};
  final Map<int, double> _distanceDraft = <int, double>{};
  final Map<int, String> _distanceUnit = <int, String>{};
  final Set<int> _expandedRepEditors = <int>{};

  // Timer-based exercise flow state
  bool _timerOverlayOpen = false;
  String _timerPhase = 'setup'; // setup | ready | running | result
  dynamic _timerExercise;
  int _timerTargetReps = 1;
  int _timerElapsed = 0;
  bool _timerTimeValid = false;
  int _timerMinSeconds = 0;
  int _timerReadyCountdown = 0;
  Stopwatch _timerStopwatch = Stopwatch();

  static const List<String> _filters = <String>[
    'Alle',
    'Cardio',
    'Strength',
    'Core',
    'Flexibility',
  ];

  List<dynamic> get _filteredExercises {
    return _exercises
        .where((dynamic item) {
          final m = _map(item);
          final matchesCategory =
              _activeFilter == 'Alle' ||
              _categoryLabel(m['category'] ?? m['Category']) == _activeFilter;
          return matchesCategory && _matchesExerciseSearch(m);
        })
        .toList(growable: false);
  }

  List<dynamic> get _filteredWorkouts {
    return _workouts
        .where((dynamic item) {
          final m = _map(item);
          final matchesCategory =
              _activeFilter == 'Alle' ||
              _categoryLabel(m['category'] ?? m['Category']) == _activeFilter;
          return matchesCategory && _matchesWorkoutSearch(m);
        })
        .toList(growable: false);
  }

  String get _normalizedSearchQuery => _searchQuery.trim().toLowerCase();

  bool _matchesAnySearch(List<String> values) {
    final query = _normalizedSearchQuery;
    if (query.isEmpty) return true;
    return values.any((String value) => value.toLowerCase().contains(query));
  }

  bool _matchesExerciseSearch(Map<String, dynamic> exercise) {
    final category = _categoryLabel(
      exercise['category'] ?? exercise['Category'],
    );
    final difficulty = _difficultyLabel(
      exercise['difficulty'] ?? exercise['Difficulty'],
    );
    return _matchesAnySearch(<String>[
      _string(exercise['name'], fallback: _string(exercise['Name'])),
      _string(
        exercise['description'],
        fallback: _string(exercise['Description']),
      ),
      category,
      difficulty,
      _normalizeUnit(exercise['unit'] ?? exercise['Unit']),
    ]);
  }

  bool _matchesWorkoutSearch(Map<String, dynamic> workout) {
    final rawExercises = workout['exercises'] ?? workout['Exercises'];
    final exerciseValues = rawExercises is List
        ? rawExercises
              .expand<String>((dynamic item) {
                final exercise = _map(item);
                return <String>[
                  _string(
                    exercise['exerciseName'],
                    fallback: _string(
                      exercise['ExerciseName'],
                      fallback: _string(
                        exercise['name'],
                        fallback: _string(exercise['Name']),
                      ),
                    ),
                  ),
                  _difficultyLabel(
                    exercise['difficulty'] ?? exercise['Difficulty'],
                  ),
                ];
              })
              .toList(growable: false)
        : <String>[];

    final category = _categoryLabel(workout['category'] ?? workout['Category']);
    return _matchesAnySearch(<String>[
      _string(workout['name'], fallback: _string(workout['Name'])),
      _string(
        workout['description'],
        fallback: _string(workout['Description']),
      ),
      category,
      ...exerciseValues,
    ]);
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

  String _formatWorkoutStatNumber(int value) {
    if (value.abs() < 1000) return value.toString();

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

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _searchController.dispose();
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
      widget.showSnack(
        _lt(
          de: 'Workouts konnten nicht geladen werden.',
          en: 'Workouts could not be loaded.',
        ),
      );
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

  String _normalizeUnit(dynamic raw) {
    if (raw is int) {
      if (raw == 1) return 'Time';
      if (raw == 2) return 'Distance';
      return 'Reps';
    }
    final s = raw.toString().toLowerCase();
    if (s == 'time') return 'Time';
    if (s == 'distance') return 'Distance';
    return 'Reps';
  }

  String _secondsToTime(int value) {
    final seconds = value.clamp(0, 999999);
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  int _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 3) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final s = int.tryParse(parts[2]) ?? 0;
    return h * 3600 + m * 60 + s;
  }

  String _formatTimeInput(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    final d = digits.length > 6 ? digits.substring(digits.length - 6) : digits;
    if (d.isEmpty) return '00:00:00';
    final padded = d.padLeft(6, '0');
    final h = int.tryParse(padded.substring(0, 2)) ?? 0;
    final m = int.tryParse(padded.substring(2, 4)) ?? 0;
    final s = int.tryParse(padded.substring(4, 6)) ?? 0;
    return _secondsToTime(h * 3600 + m * 60 + s);
  }

  String _timeDraftFor(Map<String, dynamic> exercise) {
    final id = _toInt(exercise['id']);
    return _timeDraft[id] ??
        _secondsToTime(
          _remainingFor(exercise) < 60 ? _remainingFor(exercise) : 60,
        );
  }

  Future<void> _openIosTimePicker(Map<String, dynamic> exercise) async {
    final id = _toInt(exercise['id']);
    var selected = Duration(seconds: _parseTime(_timeDraftFor(exercise)));

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext modalContext) {
        return CupertinoTheme(
          data: const CupertinoThemeData(brightness: Brightness.dark),
          child: Container(
            height: 320,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.of(modalContext).pop(),
                          child: Text(
                            _lt(de: 'Abbrechen', en: 'Cancel'),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            setState(() {
                              _timeDraft[id] = _secondsToTime(
                                selected.inSeconds,
                              );
                            });
                            Navigator.of(modalContext).pop();
                          },
                          child: const Text(
                            'Fertig',
                            style: TextStyle(
                              color: Color(0xFFEC4899),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: CupertinoTimerPicker(
                      mode: CupertinoTimerPickerMode.hms,
                      initialTimerDuration: selected,
                      onTimerDurationChanged: (Duration next) {
                        selected = next;
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  double _distanceDraftFor(Map<String, dynamic> exercise) {
    final id = _toInt(exercise['id']);
    final unit = _distanceUnitFor(exercise);
    final raw =
        _distanceDraft[id] ??
        (_remainingFor(exercise) < 100
            ? _remainingFor(exercise).toDouble()
            : 100.0);
    return unit == 'km' ? double.parse((raw / 1000).toStringAsFixed(2)) : raw;
  }

  String _distanceUnitFor(Map<String, dynamic> exercise) {
    final id = _toInt(exercise['id']);
    return _distanceUnit[id] ?? 'm';
  }

  int _logAmountFor(Map<String, dynamic> exercise) {
    final unit = _normalizeUnit(exercise['unit'] ?? exercise['Unit']);
    if (unit == 'Time') return _parseTime(_timeDraftFor(exercise));
    if (unit == 'Distance') {
      final raw = _distanceDraftFor(exercise);
      return (raw * (_distanceUnitFor(exercise) == 'km' ? 1000 : 1)).round();
    }
    return _draftFor(exercise);
  }

  String _remainingLabel(Map<String, dynamic> exercise) {
    final unit = _normalizeUnit(exercise['unit'] ?? exercise['Unit']);
    final remaining = _remainingFor(exercise);
    if (unit == 'Time') return _secondsToTime(remaining);
    if (unit == 'Distance') {
      if (remaining >= 1000)
        return '${(remaining / 1000).toStringAsFixed(2)} km';
      return '$remaining m';
    }
    return '$remaining Wiederholungen';
  }

  // ──────────────────────────────────────────────
  // Timer-based exercise flow
  // ──────────────────────────────────────────────

  void _startExerciseTimer(dynamic exercise, int reps) {
    setState(() {
      _timerOverlayOpen = true;
      _timerPhase = 'setup';
      _timerExercise = exercise;
      _timerTargetReps = reps;
      _timerElapsed = 0;
      _timerStopwatch.reset();
    });
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Exercise Timer',
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return _buildExerciseTimerDialog(ctx, setDialogState);
          },
        );
      },
    );
  }

  void _timerAdjustReps(int delta) {
    final map = _map(_timerExercise);
    final maxReps = math.max(1, _remainingFor(map));
    _timerTargetReps = (_timerTargetReps + delta).clamp(1, maxReps).toInt();
  }

  void _timerGoReady() {
    setState(() {
      _timerPhase = 'ready';
      _timerReadyCountdown = 3;
    });
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_timerOverlayOpen) return false;
      setState(() {
        _timerReadyCountdown--;
      });
      if (_timerReadyCountdown <= 0) {
        _timerStartRunning();
        return false;
      }
      return true;
    });
  }

  void _timerStartRunning() {
    setState(() {
      _timerPhase = 'running';
      _timerStopwatch.reset();
      _timerStopwatch.start();
    });
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted || !_timerOverlayOpen) return false;
      if (_timerStopwatch.isRunning) {
        setState(() {
          _timerElapsed = _timerStopwatch.elapsed.inSeconds;
        });
      }
      return _timerStopwatch.isRunning;
    });
  }

  void _timerFinish() {
    _timerStopwatch.stop();
    final map = _map(_timerExercise);
    final unit = _normalizeUnit(map['unit'] ?? map['Unit']);
    final elapsed = _timerStopwatch.elapsed.inSeconds;
    setState(() {
      _timerElapsed = elapsed;
      _timerPhase = unit == 'Time' ? 'result' : 'enter-reps';
    });
  }

  void _timerRetry() {
    setState(() {
      _timerPhase = 'enter-reps';
      // Keep the same elapsed time so user can just adjust their rep count
      _timerReadyCountdown = 0;
      final map = _map(_timerExercise);
      final remaining = _remainingFor(map);
      _timerTargetReps = remaining <= 0 ? 1 : math.min(10, remaining);
    });
  }

  void _timerConfirmResult() {
    final map = _map(_timerExercise);
    final unit = _normalizeUnit(map['unit'] ?? map['Unit']);
    final reps = unit == 'Time' ? _timerElapsed : _timerTargetReps;
    _logExerciseWithTimer(map, reps, _timerElapsed);
    _timerClose();
  }

  void _timerClose() {
    _timerStopwatch.stop();
    setState(() {
      _timerOverlayOpen = false;
      _timerPhase = 'setup';
      _timerElapsed = 0;
      _timerReadyCountdown = 0;
    });
  }

  void _timerConfirmRepsEntry() {
    final minSeconds = (_timerTargetReps * 0.75).ceil();
    final valid = _timerElapsed >= minSeconds;
    setState(() {
      _timerMinSeconds = minSeconds;
      _timerTimeValid = valid;
      _timerPhase = 'result';
    });
  }

  Future<void> _logExerciseWithTimer(
    Map<String, dynamic> map,
    int amount,
    int elapsedSeconds,
  ) async {
    final id = _toInt(map['id']);
    if (id == 0 || amount <= 0) return;
    try {
      final result = await ApiService.logExercise(
        exerciseId: id,
        reps: amount,
        elapsedSeconds: elapsedSeconds,
      );
      if (!mounted) return;
      final xpEarned = _toInt(result['xpEarned'] ?? result['XpEarned'] ?? 0);
      final bonusXp = _toInt(result['bonusXp'] ?? result['BonusXp'] ?? 0);
      final coinsEarned = _toInt(
        result['coinsEarned'] ?? result['CoinsEarned'] ?? 0,
      );
      final bonusCoins = _toInt(
        result['bonusCoins'] ?? result['BonusCoins'] ?? 0,
      );
      setState(() {
        map['todayCount'] = _toInt(map['todayCount']) + amount;
        final remaining = _remainingFor(map);
        _repsDraft[id] = remaining <= 0
            ? 0
            : (remaining < amount ? remaining : amount);
        _expandedRepEditors.remove(id);
      });
      await widget.onRefreshHeader();
      widget.onRewardEarned(
        xp: xpEarned + bonusXp,
        coins: coinsEarned + bonusCoins,
      );
      await widget.onQuestStatusChanged();
    } catch (_) {
      widget.showSnack(
        _lt(de: 'Exercise-Log fehlgeschlagen.', en: 'Exercise log failed.'),
      );
    }
  }

  Widget _buildExerciseTimerDialog(BuildContext ctx, StateSetter setDs) {
    final map = _map(_timerExercise);
    final name = _string(map['name'], fallback: 'Exercise');
    final unit = _normalizeUnit(map['unit'] ?? map['Unit']);
    final remaining = _remainingFor(map);
    final elapsedM = _timerElapsed ~/ 60;
    final elapsedS = _timerElapsed % 60;
    final elapsedFmt =
        '${elapsedM.toString().padLeft(2, '0')}:${elapsedS.toString().padLeft(2, '0')}';

    Widget timerRing({required Widget child, double size = 320}) {
      return Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEC4899).withOpacity(0.24),
              blurRadius: 32,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF040A18),
          ),
          child: Center(child: child),
        ),
      );
    }

    // Gradient button matching the workout card style
    Widget pinkButton({
      required String label,
      required VoidCallback onPressed,
      bool enabled = true,
    }) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
              ),
            ),
            child: SizedBox(
              height: 52,
              width: double.infinity,
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Plain text cancel button
    Widget cancelButton() {
      return GestureDetector(
        onTap: () {
          _timerClose();
          Navigator.of(ctx).pop();
        },
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              'Abbrechen',
              style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    Widget buildSetupPhase() {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            unit == 'Time'
                ? 'Drücke Start und beginne deine Zeit.'
                : 'Drücke Start, mache deine Wiederholungen und trage sie danach ein.',
            style: TextStyle(color: Colors.white54, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          timerRing(
            size: 296,
            child: const Text(
              '00:00',
              style: TextStyle(
                color: Colors.white,
                fontSize: 66,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          const SizedBox(height: 20),
          pinkButton(
            label: 'Start',
            onPressed: () {
              _timerGoReady();
              setDs(() {});
              Future.doWhile(() async {
                await Future.delayed(const Duration(seconds: 1));
                if (!mounted || !_timerOverlayOpen) return false;
                setDs(() {});
                if (_timerPhase == 'running' && _timerStopwatch.isRunning) {
                  _timerElapsed = _timerStopwatch.elapsed.inSeconds;
                }
                return _timerOverlayOpen &&
                    (_timerPhase == 'ready' ||
                        (_timerPhase == 'running' &&
                            _timerStopwatch.isRunning));
              });
            },
          ),
        ],
      );
    }

    Widget buildReadyPhase() {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Mache dich bereit!',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 14),
          timerRing(
            size: 280,
            child: Text(
              _timerReadyCountdown > 0 ? '$_timerReadyCountdown' : 'GO!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 58,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      );
    }

    Widget buildRunningPhase() {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          timerRing(
            size: 324,
            child: Text(
              elapsedFmt,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 78,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          if (unit == 'Reps')
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Danach trägst du deine Reps ein',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
          const SizedBox(height: 28),
          pinkButton(
            label: 'Fertig',
            onPressed: () {
              _timerFinish();
              setDs(() {});
            },
          ),
        ],
      );
    }

    Widget buildEnterRepsPhase() {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          timerRing(
            size: 220,
            child: Text(
              elapsedFmt,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 44,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Wiederholungen',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 60,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: const Color(0xFF040A18).withOpacity(0.72),
                    border: Border.all(color: Colors.white.withOpacity(0.11)),
                  ),
                  child: Row(
                    children: [
                      _timerRepSegment(-5, setDs, width: 50),
                      _timerStepperDivider(),
                      _timerRepSegment(-1, setDs, width: 46),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.035),
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFFEC4899).withOpacity(0.17),
                                const Color(0xFFEC4899).withOpacity(0.04),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.62, 1.0],
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$_timerTargetReps',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _timerStepperDivider(),
                      _timerRepSegment(1, setDs, width: 46),
                      _timerStepperDivider(),
                      _timerRepSegment(5, setDs, width: 50),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Noch $remaining möglich heute',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          pinkButton(
            label: 'Prüfen',
            enabled: _timerTargetReps > 0,
            onPressed: () {
              _timerConfirmRepsEntry();
              setDs(() {});
            },
          ),
        ],
      );
    }

    Widget buildResultPhase() {
      final valid = unit == 'Time' || _timerTimeValid;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (valid) ...[
            const SizedBox(height: 12),
            // Success: pink ring with checkmark inside
            timerRing(
              size: 304,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF22C55E),
                    size: 58,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    unit == 'Time'
                        ? '$elapsedFmt eingetragen'
                        : '$_timerTargetReps Reps in $elapsedFmt',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            pinkButton(
              label: 'Eintragen',
              onPressed: () {
                _timerConfirmResult();
                Navigator.of(ctx).pop();
              },
            ),
          ] else ...[
            const SizedBox(height: 12),
            // Failure: still PINK ring with X inside
            timerRing(
              size: 304,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cancel_rounded,
                      color: Color(0xFFFDA4AF),
                      size: 58,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Zu schnell!',
                      style: TextStyle(
                        color: Color(0xFFFDA4AF),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Mindestens ${_timerMinSeconds}s für $_timerTargetReps Reps. Du hast ${_timerElapsed}s gebraucht.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            pinkButton(
              label: 'Erneut versuchen',
              onPressed: () {
                _timerRetry();
                setDs(() {});
              },
            ),
            cancelButton(),
          ],
        ],
      );
    }

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: MediaQuery.of(ctx).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 430),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_timerPhase != 'ready' && _timerPhase != 'running')
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () {
                      _timerClose();
                      Navigator.of(ctx).pop();
                    },
                    child: Icon(Icons.close, color: Colors.white38, size: 28),
                  ),
                ),
              if (_timerPhase == 'setup') buildSetupPhase(),
              if (_timerPhase == 'ready') buildReadyPhase(),
              if (_timerPhase == 'running') buildRunningPhase(),
              if (_timerPhase == 'enter-reps') buildEnterRepsPhase(),
              if (_timerPhase == 'result') buildResultPhase(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timerStepperDivider() {
    return Container(width: 1, color: Colors.white.withOpacity(0.08));
  }

  Widget _timerRepSegment(
    int delta,
    StateSetter setDs, {
    required double width,
  }) {
    final label = delta.abs() > 1
        ? '${delta > 0 ? '+' : ''}$delta'
        : (delta > 0 ? '+' : '-');
    final isWideStep = delta.abs() > 1;
    return SizedBox(
      width: width,
      height: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          splashColor: const Color(0xFFEC4899).withOpacity(0.18),
          highlightColor: const Color(0xFFEC4899).withOpacity(0.12),
          onTap: () {
            setDs(() {
              _timerAdjustReps(delta);
            });
          },
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              strutStyle: const StrutStyle(forceStrutHeight: true, height: 1),
              style: TextStyle(
                color: isWideStep ? Colors.white70 : Colors.white,
                fontSize: isWideStep ? 14 : 20,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logExerciseWithAmount(dynamic exercise, int amount) async {
    final map = _map(exercise);
    final id = _toInt(map['id']);
    if (id == 0 || amount <= 0) return;
    try {
      final result = await ApiService.logExercise(exerciseId: id, reps: amount);
      if (!mounted) return;
      final xpEarned = _toInt(result['xpEarned'] ?? result['XpEarned'] ?? 0);
      final bonusXp = _toInt(result['bonusXp'] ?? result['BonusXp'] ?? 0);
      final coinsEarned = _toInt(
        result['coinsEarned'] ?? result['CoinsEarned'] ?? 0,
      );
      final bonusCoins = _toInt(
        result['bonusCoins'] ?? result['BonusCoins'] ?? 0,
      );
      setState(() {
        map['todayCount'] = _toInt(map['todayCount']) + amount;
        final remaining = _remainingFor(map);
        _repsDraft[id] = remaining <= 0
            ? 0
            : (remaining < amount ? remaining : amount);
        _expandedRepEditors.remove(id);
      });
      await widget.onRefreshHeader();
      widget.onRewardEarned(
        xp: xpEarned + bonusXp,
        coins: coinsEarned + bonusCoins,
      );
      await widget.onQuestStatusChanged();
    } catch (_) {
      widget.showSnack(
        _lt(de: 'Exercise-Log fehlgeschlagen.', en: 'Exercise log failed.'),
      );
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
        return Color(0xFFEF4444).withOpacity(0.16);
      case 'Core':
        return Color(0xFFEC4899).withOpacity(0.16);
      case 'Flexibility':
        return Color(0xFF22C55E).withOpacity(0.16);
      case 'Strength':
      default:
        return Color(0xFFA855F7).withOpacity(0.16);
    }
  }

  Color _categoryBorder(String category) {
    switch (category) {
      case 'Cardio':
        return Color(0xFFEF4444).withOpacity(0.45);
      case 'Core':
        return Color(0xFFEC4899).withOpacity(0.45);
      case 'Flexibility':
        return Color(0xFF22C55E).withOpacity(0.45);
      case 'Strength':
      default:
        return Color(0xFFA855F7).withOpacity(0.45);
    }
  }

  Color _categoryText(String category) {
    switch (category) {
      case 'Cardio':
        return Color(0xFFFCA5A5);
      case 'Core':
        return Color(0xFFF9A8D4);
      case 'Flexibility':
        return Color(0xFF86EFAC);
      case 'Strength':
      default:
        return Color(0xFFC4B5FD);
    }
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return Color(0xFF86EFAC);
      case 'Hard':
        return Color(0xFFFCA5A5);
      case 'Medium':
      default:
        return Color(0xFFFDE047);
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

  Widget _buildFilterChips() {
    return SingleChildScrollView(
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
                          ? Color(0xFFEC4899).withOpacity(0.26)
                          : Colors.white.withOpacity(0.05),
                      border: Border.all(
                        color: isActive
                            ? Color(0xFFEC4899).withOpacity(0.55)
                            : Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Text(
                      _td(filter),
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
    );
  }

  Widget _buildExerciseSearchField() {
    return SizedBox(
      height: 46,
      child: TextField(
        controller: _searchController,
        onChanged: (String value) => setState(() => _searchQuery = value),
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: _lt(de: 'Übung suchen...', en: 'Search exercise...'),
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.52),
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.white.withOpacity(0.68),
            size: 20,
          ),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  tooltip: _lt(de: 'Suche löschen', en: 'Clear search'),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.white.withOpacity(0.7),
                    size: 18,
                  ),
                ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEC4899)),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterControls() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth >= 560) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildFilterChips()),
              const SizedBox(width: 12),
              SizedBox(width: 230, child: _buildExerciseSearchField()),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFilterChips(),
            const SizedBox(height: 10),
            _buildExerciseSearchField(),
          ],
        );
      },
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
            _lt(de: 'Deine Übungen', en: 'Your Exercises'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _lt(
              de: 'Wähle eine Übung und trage deine Wiederholungen ein.',
              en: 'Choose an exercise and log your progress.',
            ),
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
                  label: _lt(de: 'Heute', en: 'Today'),
                  value: _lt(
                    de: '${_formatWorkoutStatNumber(_todayReps)} Einheiten',
                    en: '${_formatWorkoutStatNumber(_todayReps)} units',
                  ),
                  accent: Color(0xFF60A5FA),
                ),
                const SizedBox(width: 10),
                _buildStatPill(
                  icon: Icons.stacked_bar_chart,
                  label: _lt(de: 'Gesamt', en: 'Total'),
                  value: _lt(
                    de: '${_formatWorkoutStatNumber(_totalReps)} Einheiten',
                    en: '${_formatWorkoutStatNumber(_totalReps)} units',
                  ),
                  accent: Color(0xFFA855F7),
                ),
                const SizedBox(width: 10),
                _buildStatPill(
                  icon: Icons.bolt,
                  label: _lt(de: 'XP Heute', en: 'XP Today'),
                  value: '+${_formatWorkoutStatNumber(_todayXp)} XP',
                  accent: Color(0xFFFBBF24),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildHealthMetricCard(
                iconColor: Color(0xFFFF6B1A),
                label: _lt(de: 'Schritte heute', en: 'Steps today'),
                value: _formatWorkoutStatNumber(
                  _toInt(_todayActivity['steps']),
                ),
              ),
              const SizedBox(width: 10),
              _buildHealthMetricCard(
                iconColor: Color(0xFFFF6B1A),
                label: _lt(de: 'Kilometer heute', en: 'Kilometers today'),
                value:
                    '${_toDouble(_todayActivity['kilometers']).toStringAsFixed(1)} km',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFilterControls(),
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
                            _td(category),
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
                      _td(_string(m['name'], fallback: 'Exercise')),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _td(desc),
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
                          _td(difficulty),
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color:
                                _normalizeUnit(m['unit'] ?? m['Unit']) == 'Time'
                                ? Color(0xFFFBBF24).withOpacity(0.18)
                                : _normalizeUnit(m['unit'] ?? m['Unit']) ==
                                      'Distance'
                                ? Color(0xFF22C55E).withOpacity(0.18)
                                : Color(0xFF3B82F6).withOpacity(0.18),
                            border: Border.all(
                              color:
                                  _normalizeUnit(m['unit'] ?? m['Unit']) ==
                                      'Time'
                                  ? Color(0xFFFBBF24).withOpacity(0.35)
                                  : _normalizeUnit(m['unit'] ?? m['Unit']) ==
                                        'Distance'
                                  ? Color(0xFF22C55E).withOpacity(0.35)
                                  : Color(0xFF3B82F6).withOpacity(0.35),
                            ),
                          ),
                          child: Text(
                            _normalizeUnit(m['unit'] ?? m['Unit']),
                            style: TextStyle(
                              color:
                                  _normalizeUnit(m['unit'] ?? m['Unit']) ==
                                      'Time'
                                  ? Color(0xFFFDE047)
                                  : _normalizeUnit(m['unit'] ?? m['Unit']) ==
                                        'Distance'
                                  ? Color(0xFF86EFAC)
                                  : Color(0xFF93C5FD),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
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
                          '+$xpPerRep XP/${_normalizeUnit(m['unit'] ?? m['Unit']) == 'Time'
                              ? 'Sek'
                              : _normalizeUnit(m['unit'] ?? m['Unit']) == 'Distance'
                              ? 'm'
                              : 'Rep'}',
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
                        child: Text(
                          _lt(
                            de: 'Tageslimit erreicht',
                            en: 'Daily limit reached',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else if (_normalizeUnit(m['unit'] ?? m['Unit']) !=
                        'Distance')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _startExerciseTimer(
                            e,
                            _normalizeUnit(m['unit'] ?? m['Unit']) == 'Time'
                                ? _parseTime(_timeDraftFor(m))
                                : _draftFor(m),
                          ),
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
                              gradient: LinearGradient(
                                colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
                              ),
                            ),
                            child: SizedBox(
                              height: 46,
                              child: Center(
                                child: Text(
                                  _lt(de: 'Eintragen', en: 'Log'),
                                  style: const TextStyle(
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
                              gradient: LinearGradient(
                                colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
                              ),
                            ),
                            child: SizedBox(
                              height: 46,
                              child: Center(
                                child: Text(
                                  _lt(
                                    de: 'Training eintragen',
                                    en: 'Log training',
                                  ),
                                  style: const TextStyle(
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
                          if (_normalizeUnit(m['unit'] ?? m['Unit']) == 'Reps')
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
                                        _logExerciseWithAmount(e, repsDraft),
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
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFFEC4899),
                                            Color(0xFFF43F5E),
                                          ],
                                        ),
                                      ),
                                      child: SizedBox(
                                        height: 46,
                                        child: Center(
                                          child: Text(
                                            _lt(de: 'Eintragen', en: 'Log'),
                                            style: const TextStyle(
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
                            )
                          else if (_normalizeUnit(m['unit'] ?? m['Unit']) ==
                              'Time')
                            Row(
                              children: [
                                Expanded(
                                  child:
                                      Theme.of(context).platform ==
                                          TargetPlatform.iOS
                                      ? GestureDetector(
                                          onTap: () => _openIosTimePicker(m),
                                          child: Container(
                                            height: 46,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              color: Colors.white.withOpacity(
                                                0.05,
                                              ),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(
                                                  0.12,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  CupertinoIcons.time,
                                                  color: Color(0xFF60A5FA),
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _timeDraftFor(m),
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      : Container(
                                          height: 46,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            color: Colors.white.withOpacity(
                                              0.05,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.12,
                                              ),
                                            ),
                                          ),
                                          child: TextField(
                                            controller: TextEditingController(
                                              text: _timeDraftFor(m),
                                            ),
                                            textAlign: TextAlign.center,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                            ],
                                            keyboardType: TextInputType.number,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                            ),
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              hintText: '00:00:00',
                                              hintStyle: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.3,
                                                ),
                                              ),
                                            ),
                                            onChanged: (val) {
                                              final formatted =
                                                  _formatTimeInput(val);
                                              final id = _toInt(m['id']);
                                              _timeDraft[id] = formatted;
                                            },
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 132,
                                  child: ElevatedButton(
                                    onPressed: _parseTime(_timeDraftFor(m)) > 0
                                        ? () => _startExerciseTimer(
                                            e,
                                            _parseTime(_timeDraftFor(m)),
                                          )
                                        : null,
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
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFFEC4899),
                                            Color(0xFFF43F5E),
                                          ],
                                        ),
                                      ),
                                      child: SizedBox(
                                        height: 46,
                                        child: Center(
                                          child: Text(
                                            _lt(de: 'Eintragen', en: 'Log'),
                                            style: const TextStyle(
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
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 46,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            color: Colors.white.withOpacity(
                                              0.05,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.12,
                                              ),
                                            ),
                                          ),
                                          child: TextField(
                                            controller: TextEditingController(
                                              text: _distanceDraftFor(
                                                m,
                                              ).toString(),
                                            ),
                                            textAlign: TextAlign.center,
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                            ),
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              hintText: _lt(
                                                de: 'Distanz',
                                                en: 'Distance',
                                              ),
                                              hintStyle: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.3,
                                                ),
                                              ),
                                            ),
                                            onChanged: (val) {
                                              final id = _toInt(m['id']);
                                              final parsed =
                                                  double.tryParse(val) ?? 0;
                                              final multiplier =
                                                  _distanceUnitFor(m) == 'km'
                                                  ? 1000
                                                  : 1;
                                              _distanceDraft[id] =
                                                  parsed * multiplier;
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        height: 46,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          color: Colors.white.withOpacity(0.05),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.12,
                                            ),
                                          ),
                                        ),
                                        child: DropdownButton<String>(
                                          value: _distanceUnitFor(m),
                                          underline: const SizedBox(),
                                          icon: const Icon(
                                            Icons.arrow_drop_down,
                                            color: Colors.white70,
                                            size: 18,
                                          ),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'm',
                                              child: Text('m'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'km',
                                              child: Text('km'),
                                            ),
                                          ],
                                          onChanged: (val) {
                                            if (val == null) return;
                                            final id = _toInt(m['id']);
                                            setState(() {
                                              _distanceUnit[id] = val;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 132,
                                  child: ElevatedButton(
                                    onPressed: _distanceDraftFor(m) > 0
                                        ? () => _startExerciseTimer(
                                            e,
                                            _logAmountFor(m),
                                          )
                                        : null,
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
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFFEC4899),
                                            Color(0xFFF43F5E),
                                          ],
                                        ),
                                      ),
                                      child: SizedBox(
                                        height: 46,
                                        child: Center(
                                          child: Text(
                                            _lt(de: 'Eintragen', en: 'Log'),
                                            style: const TextStyle(
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
                          const SizedBox(width: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _lt(
                                de: 'Noch ${_remainingLabel(m)} möglich heute',
                                en: '${_remainingLabel(m)} still possible today',
                              ),
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
          if (_filteredWorkouts.isNotEmpty) ...[
            const SizedBox(height: 18),
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
                          _td(category),
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
                              _td(
                                _string(
                                  m['name'],
                                  fallback: _string(
                                    m['title'],
                                    fallback: 'Workout',
                                  ),
                                ),
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _lt(
                                de: '$exCount Übungen',
                                en: '$exCount exercises',
                              ),
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
