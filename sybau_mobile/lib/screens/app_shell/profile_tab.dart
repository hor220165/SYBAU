part of '../app_shell_screen.dart';

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

class _ActivityYearGlassMenu extends StatelessWidget {
  const _ActivityYearGlassMenu({
    required this.years,
    required this.selectedYear,
    required this.onSelected,
  });

  final List<int> years;
  final int selectedYear;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: const Color(0xE61A1A1D),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.36),
                blurRadius: 40,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.calendar,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Jahr',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.92),
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: Colors.white.withOpacity(0.14)),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 236),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final year in years)
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 48),
                              onPressed: () => onSelected(year),
                              child: Row(
                                children: [
                                  Icon(
                                    year == selectedYear
                                        ? CupertinoIcons.check_mark
                                        : CupertinoIcons.circle,
                                    color: year == selectedYear
                                        ? const Color(0xFFFF4FB3)
                                        : Colors.white.withOpacity(0.56),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    '$year',
                                    style: TextStyle(
                                      color: year == selectedYear
                                          ? const Color(0xFFFFB3DD)
                                          : Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileTabState extends State<ProfileTab> {
  static const Duration _usernameChangeCooldown = Duration(days: 14);

  bool _loading = true;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _serverUrlController = TextEditingController();
  final ScrollController _activityHeatmapScrollController = ScrollController();

  Map<String, dynamic> _profile = <String, dynamic>{};
  List<dynamic> _achievements = <dynamic>[];
  Map<String, dynamic> _profileStats = <String, dynamic>{};
  List<dynamic> _recentActivities = <dynamic>[];
  List<dynamic> _weeklyActivity = <dynamic>[];
  List<int> _activityYears = <int>[DateTime.now().year];
  int _selectedActivityYear = DateTime.now().year;
  String _activityMode = 'workouts';
  Offset? _activityYearTapPosition;
  String? _profileImageUrl;
  Uint8List? _pickedProfileImageBytes;
  int _profileImageVersion = 0;
  int _currentAchievementIndex = 0;
  bool _notificationsEnabled = false;
  bool _healthSyncEnabled = false;
  bool _settingsBusy = false;
  NotificationReminderTime _notificationReminderTime =
      const NotificationReminderTime(hour: 20, minute: 0);
  DateTime? _usernameChangedAt;

  String _tr({required String de, required String en}) {
    return de;
  }

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
    _activityHeatmapScrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      try {
        final healthResult = await HealthSyncService.syncIfEnabled();
        if (healthResult?.hasNewData == true ||
            healthResult?.hasRewards == true) {
          unawaited(widget.onRefreshHeader());
        }
      } catch (_) {
        // Das Profil soll auch ohne Health-Zugriff sofort nutzbar bleiben.
      }

      final activityYears = await _loadActivityYearsSafe();
      var selectedYear = _selectedActivityYear;
      if (!activityYears.contains(selectedYear)) {
        selectedYear = activityYears.first;
      }
      final activityRange = _activityHeatmapBounds(selectedYear);
      final results = await Future.wait<dynamic>([
        ApiService.getProfile(),
        ApiService.getAchievements(),
        ApiService.getProfileStats(),
        ApiService.getRecentActivities(limit: 10),
        ApiService.getWeeklyActivity(
          from: activityRange.$1,
          to: activityRange.$2,
        ),
        NotificationService.isEnabled(),
        NotificationService.reminderTime(),
        HealthSyncService.isEnabled(),
      ]);

      final profile = results[0] as Map<String, dynamic>;
      final achievements = results[1] as List<dynamic>;
      final stats = results[2] as Map<String, dynamic>;
      final recent = results[3] as List<dynamic>;
      final weeklyRaw = (results[4] as List<dynamic>?) ?? <dynamic>[];
      _selectedActivityYear = selectedYear;
      final activityDays = _normalizeActivityHeatmap(
        weeklyRaw,
        activityRange.$1,
        activityRange.$2,
      );
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
        _weeklyActivity = activityDays;
        _activityYears = activityYears;
        _selectedActivityYear = selectedYear;
        _profileImageUrl = profileImageUrl;
        _pickedProfileImageBytes = null;
        _currentAchievementIndex = 0;
        _notificationsEnabled = results[5] as bool;
        _notificationReminderTime = results[6] as NotificationReminderTime;
        _healthSyncEnabled = results[7] as bool;
        _usernameChangedAt = usernameChangedAt;
        _loading = false;
      });
      _queueActivityScrollToCurrent();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      widget.showSnack(
        _tr(
          de: 'Profil konnte nicht geladen werden.',
          en: 'Profile could not be loaded.',
        ),
      );
    }
  }

  Future<void> _setNotificationsEnabled(
    bool enabled,
    StateSetter modalSetState,
  ) async {
    modalSetState(() => _settingsBusy = true);
    try {
      final applied = await NotificationService.setEnabled(enabled);
      final scheduled = applied
          ? await NotificationService.isDailyReminderScheduled()
          : false;
      if (!mounted) return;
      setState(() => _notificationsEnabled = applied);
      modalSetState(() => _notificationsEnabled = applied);
      if (enabled && !applied) {
        widget.showSnack(
          _tr(
            de: 'Bitte erlaube Notifications in iOS.',
            en: 'Please allow notifications in iOS.',
          ),
        );
      } else {
        widget.showSnack(
          applied && scheduled
              ? _tr(
                  de: 'Workout-Erinnerung geplant.',
                  en: 'Workout reminder scheduled.',
                )
              : applied
              ? _tr(
                  de: 'Notifications erlaubt, Reminder aber nicht gefunden.',
                  en: 'Notifications allowed, but reminder was not found.',
                )
              : _tr(
                  de: 'Workout-Erinnerung deaktiviert.',
                  en: 'Workout reminder disabled.',
                ),
        );
      }
    } catch (_) {
      widget.showSnack(
        _tr(
          de: 'Benachrichtigungen konnten nicht aktiviert werden.',
          en: 'Notifications could not be updated.',
        ),
      );
    } finally {
      if (mounted) {
        modalSetState(() => _settingsBusy = false);
      }
    }
  }

  String _formatReminderTime(NotificationReminderTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _openReminderTimePicker(StateSetter modalSetState) async {
    var selected = DateTime(
      2026,
      1,
      1,
      _notificationReminderTime.hour,
      _notificationReminderTime.minute,
    );

    final picked = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (pickerContext) => Container(
        height: 300,
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 10, 6),
                child: Row(
                  children: [
                    const Spacer(),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(_tr(de: 'Fertig', en: 'Done')),
                      onPressed: () =>
                          Navigator.of(pickerContext).pop(selected),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoTheme(
                  data: const CupertinoThemeData(
                    brightness: Brightness.dark,
                    primaryColor: Color(0xFFEC4899),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: true,
                    initialDateTime: selected,
                    onDateTimeChanged: (value) => selected = value,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (picked == null) return;

    final nextTime = NotificationReminderTime(
      hour: picked.hour,
      minute: picked.minute,
    );

    modalSetState(() => _settingsBusy = true);
    try {
      await NotificationService.setReminderTime(nextTime);
      final scheduled = _notificationsEnabled
          ? await NotificationService.isDailyReminderScheduled()
          : false;
      if (!mounted) return;
      setState(() => _notificationReminderTime = nextTime);
      modalSetState(() => _notificationReminderTime = nextTime);
      widget.showSnack(
        scheduled
            ? _tr(
                de: 'Erinnerung auf ${_formatReminderTime(nextTime)} geplant.',
                en: 'Reminder scheduled for ${_formatReminderTime(nextTime)}.',
              )
            : _tr(
                de: 'Erinnerungszeit auf ${_formatReminderTime(nextTime)} gesetzt.',
                en: 'Reminder time set to ${_formatReminderTime(nextTime)}.',
              ),
      );
    } catch (_) {
      widget.showSnack(
        _tr(
          de: 'Erinnerungszeit konnte nicht gespeichert werden.',
          en: 'Reminder time could not be saved.',
        ),
      );
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
        widget.showSnack(
          _tr(de: 'Health Sync deaktiviert.', en: 'Health sync disabled.'),
        );
        return;
      }

      final granted = await HealthSyncService.requestAuthorization();
      if (!granted) {
        if (!mounted) return;
        setState(() => _healthSyncEnabled = false);
        modalSetState(() => _healthSyncEnabled = false);
        widget.showSnack(
          _tr(
            de: 'Health Zugriff wurde nicht freigegeben. Bitte Berechtigung erlauben, um automatisch zu synchronisieren.',
            en: 'Health access was not granted. Please allow permission to sync automatically.',
          ),
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
            ? _tr(
                de: 'Health Sync aktiviert und synchronisiert.$rewardText',
                en: 'Health sync enabled and synced.$rewardText',
              )
            : _tr(
                de: 'Health Sync aktiviert. Keine neuen Daten gefunden.',
                en: 'Health sync enabled. No new data found.',
              ),
      );
    } catch (_) {
      widget.showSnack(
        _tr(
          de: 'Health Sync konnte nicht aktiviert werden.',
          en: 'Health sync could not be enabled.',
        ),
      );
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
      widget.showSnack(
        _tr(
          de: 'Benutzername kann nur alle 14 Tage geändert werden.',
          en: 'Username can only be changed every 14 days.',
        ),
      );
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
      widget.showSnack(_tr(de: 'Profil gespeichert.', en: 'Profile saved.'));
      await widget.onRefreshHeader();
      if (!mounted) return true;
      setState(() {});
      return true;
    } catch (_) {
      widget.showSnack(
        _tr(de: 'Speichern fehlgeschlagen.', en: 'Save failed.'),
      );
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
      return _tr(
        de: 'Kann alle 14 Tage geändert werden.',
        en: 'Can be changed every 14 days.',
      );
    }
    final nextDate = changedAt.add(_usernameChangeCooldown);
    return _tr(
      de: 'Wieder möglich ab ${_formatShortDate(nextDate)}.',
      en: 'Available again from ${_formatShortDate(nextDate)}.',
    );
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

  Future<bool> _changePassword() async {
    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;
    if (oldPassword.isEmpty || newPassword.isEmpty) {
      widget.showSnack(
        _tr(
          de: 'Bitte beide Passwortfelder ausfüllen.',
          en: 'Please fill in both password fields.',
        ),
      );
      return false;
    }
    if (oldPassword == newPassword) {
      widget.showSnack(
        _tr(
          de: 'Das neue Passwort muss anders sein.',
          en: 'The new password must be different.',
        ),
      );
      return false;
    }
    try {
      await ApiService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      _oldPasswordController.clear();
      _newPasswordController.clear();
      widget.showSnack(_tr(de: 'Passwort geändert.', en: 'Password changed.'));
      return true;
    } catch (_) {
      widget.showSnack(
        _tr(
          de: 'Passwortwechsel fehlgeschlagen.',
          en: 'Password change failed.',
        ),
      );
      return false;
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
      widget.showSnack(
        _tr(
          de: 'Account konnte nicht geloescht werden.',
          en: 'Account could not be deleted.',
        ),
      );
    }
  }

  Future<List<int>> _loadActivityYearsSafe() async {
    final currentYear = DateTime.now().year;
    try {
      final rawYears = await ApiService.getActivityYears();
      final years =
          rawYears
              .map((dynamic value) => _toInt(value))
              .where((year) => year > 2000)
              .toSet()
              .toList()
            ..sort((a, b) => b.compareTo(a));
      return years.isEmpty ? <int>[currentYear] : years;
    } catch (_) {
      return <int>[currentYear];
    }
  }

  ({DateTime $1, DateTime $2}) _activityHeatmapBounds(int year) {
    final now = DateTime.now();
    final firstDay = DateTime(year, 1, 1);
    final lastDay = year == now.year
        ? DateTime(now.year, now.month, now.day)
        : DateTime(year, 12, 31);
    final start = firstDay.subtract(Duration(days: firstDay.weekday - 1));
    final end = lastDay;
    return ($1: start, $2: end);
  }

  DateTime _selectedActivityToday() {
    final now = DateTime.now();
    if (_selectedActivityYear == now.year) {
      return DateTime(now.year, now.month, now.day);
    }
    return DateTime(_selectedActivityYear, 12, 31);
  }

  Future<void> _loadActivityForYear(int year) async {
    final bounds = _activityHeatmapBounds(year);
    try {
      final weeklyRaw = await ApiService.getWeeklyActivity(
        from: bounds.$1,
        to: bounds.$2,
      );
      if (!mounted) return;
      setState(() {
        _selectedActivityYear = year;
        _weeklyActivity = _normalizeActivityHeatmap(
          weeklyRaw,
          bounds.$1,
          bounds.$2,
        );
      });
      _queueActivityScrollToCurrent();
    } catch (_) {
      if (!mounted) return;
      widget.showSnack('Aktivität konnte nicht geladen werden.');
    }
  }

  void _queueActivityScrollToCurrent() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_activityHeatmapScrollController.hasClients) return;
      final maxOffset =
          _activityHeatmapScrollController.position.maxScrollExtent;
      if (maxOffset <= 0) return;
      _activityHeatmapScrollController.jumpTo(maxOffset);
    });
  }

  Future<void> _openActivityYearPicker() async {
    final screenSize = MediaQuery.sizeOf(context);
    final tapPosition =
        _activityYearTapPosition ?? Offset(screenSize.width - 96, 220);
    const menuWidth = 248.0;
    final menuHeight = 74.0 + math.min(_activityYears.length, 4) * 56.0 + 16.0;
    final left = (tapPosition.dx - menuWidth + 26).clamp(
      12.0,
      screenSize.width - menuWidth - 12.0,
    );
    final top = (tapPosition.dy + 10).clamp(
      64.0,
      screenSize.height - menuHeight - 18.0,
    );

    await showGeneralDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.28),
      barrierDismissible: true,
      barrierLabel: 'Jahr schließen',
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              width: menuWidth,
              child: SafeArea(
                child: FadeTransition(
                  opacity: curved,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
                    alignment: Alignment.topRight,
                    child: _ActivityYearGlassMenu(
                      years: _activityYears,
                      selectedYear: _selectedActivityYear,
                      onSelected: (year) {
                        Navigator.of(context).pop();
                        if (year != _selectedActivityYear) {
                          unawaited(_loadActivityForYear(year));
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) =>
          child,
    );
  }

  String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
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
      final steps = _toInt(map['steps'], fallback: _toInt(map['Steps']));
      repsByDate[dateKey] = reps;
      stepsByDate[dateKey] = steps;
    }

    const weekdayNames = <String>['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    final today = _selectedActivityToday();
    final todayKey = _dateKey(today);
    final dayCount = end.difference(start).inDays + 1;
    return List<Map<String, dynamic>>.generate(dayCount, (int index) {
      final day = start.add(Duration(days: index));
      final key = _dateKey(day);
      final reps = repsByDate[key] ?? 0;
      final steps = stepsByDate[key] ?? 0;
      return <String, dynamic>{
        'name': weekdayNames[(day.weekday - 1).clamp(0, 6).toInt()],
        'date': key,
        'day': day.day,
        'month': day.month,
        'dateDisplay':
            '${day.day.toString().padLeft(2, '0')}.${day.month.toString().padLeft(2, '0')}',
        'reps': reps,
        'steps': steps,
        'workoutDone': reps > 0,
        'isToday': key == todayKey,
        'isFuture': day.isAfter(DateTime(today.year, today.month, today.day)),
      };
    });
  }

  List<List<Map<String, dynamic>>> get _activityHeatmapWeeks {
    final weeks = <List<Map<String, dynamic>>>[];
    for (var index = 0; index < _weeklyActivity.length; index += 7) {
      weeks.add(
        _weeklyActivity
            .skip(index)
            .take(7)
            .map((dynamic item) => _map(item))
            .toList(growable: false),
      );
    }
    return weeks;
  }

  bool get _isStepsActivityMode => _activityMode == 'steps';

  int _activityValue(Map<String, dynamic> day) {
    return _isStepsActivityMode ? _toInt(day['steps']) : _toInt(day['reps']);
  }

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

  Color _activityColor(int value, {bool isFuture = false}) {
    if (isFuture) return Colors.white.withValues(alpha: 0.04);
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
        return colors[1]!.withValues(alpha: 0.56);
      case 2:
        return colors[2]!.withValues(alpha: 0.72);
      case 3:
        return colors[3]!.withValues(alpha: 0.88);
      case 4:
        return colors[4]!;
      default:
        return Colors.white.withValues(alpha: 0.06);
    }
  }

  Color _activityBorderColor(int value, {bool isToday = false}) {
    if (isToday) return Colors.white.withValues(alpha: 0.78);
    if (value > 0) {
      return (_isStepsActivityMode
              ? const Color(0xFFFB923C)
              : const Color(0xFFF472B6))
          .withValues(alpha: 0.22);
    }
    return Colors.white.withValues(alpha: 0.05);
  }

  int get _activityTotal {
    var total = 0;
    for (final item in _weeklyActivity) {
      total += _activityValue(_map(item));
    }
    return total;
  }

  String get _activityTotalLabel {
    final value = _formatCompactNumber(_activityTotal);
    return _isStepsActivityMode
        ? '$value Schritte in $_selectedActivityYear'
        : '$value Reps in $_selectedActivityYear';
  }

  int _activityLegendValue(int level) {
    if (level <= 0) return 0;
    if (_isStepsActivityMode) {
      return <int>[0, 1200, 4200, 8000, 12000][level];
    }
    return <int>[0, 10, 40, 75, 100][level];
  }

  String _activityMonthLabel(List<Map<String, dynamic>> week) {
    final firstActivityDate = _weeklyActivity.isEmpty
        ? ''
        : _string(_map(_weeklyActivity.first)['date']);
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
      final date = _string(day['date']);
      final isFirstVisibleWeek = date.isNotEmpty && date == firstActivityDate;
      if ((isFirstVisibleWeek || dayOfMonth == 1) &&
          month >= 1 &&
          month <= 12) {
        return months[month - 1];
      }
    }
    return '';
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
      backgroundColor: Color(0xFF0F172A),
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
        backgroundColor: Color(0xFF0F172A),
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
        : _isDataImageUrl(imageUrl)
        ? imageUrl
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
            color: hasPhoto ? null : Color(0xFF1E293B),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFEC4899).withOpacity(0.24),
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
                ? _buildProfileImageFromUrl(
                    versionedImageUrl!,
                    key: ValueKey(versionedImageUrl),
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
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
                  color: Color(0xFFEC4899),
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
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.72),
      builder: (ctx) {
        final topInset = MediaQuery.of(ctx).padding.top;
        final email = _string(
          _profile['email'],
          fallback: _string(_profile['Email']),
        );
        final canEditUsername = !_isUsernameChangeLocked;
        var settingsPage = 'main';
        return StatefulBuilder(
          builder: (ctx, modalSetState) {
            Widget sectionTitle(String title) {
              return Padding(
                padding: const EdgeInsets.only(top: 18, bottom: 10),
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            }

            Widget passwordPage() {
              return Column(
                key: const ValueKey<String>('settings-password'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionTitle(_tr(de: 'Sicherheit', en: 'Security')),
                  TextField(
                    controller: _oldPasswordController,
                    style: const TextStyle(color: Colors.white),
                    obscureText: true,
                    decoration: _settingsInputDecoration(
                      _tr(de: 'Altes Passwort', en: 'Old password'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _newPasswordController,
                    style: const TextStyle(color: Colors.white),
                    obscureText: true,
                    decoration: _settingsInputDecoration(
                      _tr(de: 'Neues Passwort', en: 'New password'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: _GradientActionButton(
                      onPressed: () async {
                        final changed = await _changePassword();
                        if (changed && mounted) {
                          modalSetState(() => settingsPage = 'main');
                        }
                      },
                      label: _tr(de: 'Passwort speichern', en: 'Save password'),
                    ),
                  ),
                ],
              );
            }

            Widget mainPage() {
              return Column(
                key: const ValueKey<String>('settings-main'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionTitle(_tr(de: 'Profil', en: 'Profile')),
                  TextField(
                    controller: _usernameController,
                    readOnly: !canEditUsername,
                    style: TextStyle(
                      color: canEditUsername ? Colors.white : Colors.white54,
                    ),
                    decoration: _settingsInputDecoration(
                      _tr(de: 'Benutzername', en: 'Username'),
                    ).copyWith(helperText: _usernameChangeHint),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    enabled: false,
                    initialValue: email,
                    style: const TextStyle(color: Colors.white38),
                    decoration: _disabledSettingsInputDecoration(
                      _tr(de: 'E-Mail', en: 'Email'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: _GradientActionButton(
                      onPressed: () async {
                        final saved = await _saveProfile();
                        if (saved && ctx.mounted) {
                          Navigator.of(ctx).pop();
                        }
                      },
                      label: _tr(de: 'Speichern', en: 'Save'),
                    ),
                  ),
                  sectionTitle(_tr(de: 'Fortschritt', en: 'Progress')),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: const Color(0xFF050914),
                      border: Border.all(color: Colors.white.withOpacity(0.07)),
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
                          _tr(de: 'Challenges', en: 'Challenges'),
                          '${_toInt(_profileStats['completedChallenges'])}',
                        ),
                        _buildProgressRow(
                          'Streak',
                          _tr(
                            de: '${_toInt(_profileStats['currentStreak'])} Tage',
                            en: '${_toInt(_profileStats['currentStreak'])} days',
                          ),
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  sectionTitle(
                    _tr(de: 'Benachrichtigungen', en: 'Notifications'),
                  ),
                  _buildSettingsTile(
                    icon: Icons.notifications_active_rounded,
                    iconColor: Color(0xFFFDA4AF),
                    title: _tr(de: 'iPhone-Reminder', en: 'iPhone reminder'),
                    subtitle: _notificationsEnabled
                        ? _tr(de: 'Aktiv', en: 'Active')
                        : null,
                    trailing: Switch.adaptive(
                      value: _notificationsEnabled,
                      activeThumbColor: Color(0xFFEC4899),
                      onChanged: _settingsBusy
                          ? null
                          : (value) =>
                                _setNotificationsEnabled(value, modalSetState),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildReminderTimeTile(modalSetState),
                  sectionTitle(_tr(de: 'Health Sync', en: 'Health sync')),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: const Color(0xFF050914),
                      border: Border.all(color: Colors.white.withOpacity(0.07)),
                    ),
                    child: ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 2,
                      ),
                      leading: _buildSettingsImageIcon(_appleHealthLogoAsset),
                      title: const Text(
                        'Apple Health',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      trailing: Switch.adaptive(
                        value: _healthSyncEnabled,
                        activeThumbColor: Color(0xFFEC4899),
                        onChanged: _settingsBusy
                            ? null
                            : (value) =>
                                  _setHealthSyncEnabled(value, modalSetState),
                      ),
                    ),
                  ),
                  sectionTitle(_tr(de: 'Sicherheit', en: 'Security')),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          modalSetState(() => settingsPage = 'password'),
                      icon: const Icon(Icons.lock_reset_rounded, size: 18),
                      label: Text(
                        _tr(de: 'Passwort ändern', en: 'Change password'),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: const Color(0xFFF472B6).withOpacity(0.32),
                        ),
                        backgroundColor: const Color(0xFF050914),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  sectionTitle(_tr(de: 'Account', en: 'Account')),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: const Color(0xFF050914),
                      border: Border.all(color: Colors.white.withOpacity(0.07)),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 2,
                          ),
                          leading: _buildSettingsIcon(
                            Icons.logout_rounded,
                            const Color(0xFFFDA4AF),
                          ),
                          title: Text(
                            _tr(de: 'Abmelden', en: 'Log out'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
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
                          leading: _buildSettingsIcon(
                            Icons.delete_outline_rounded,
                            const Color(0xFFFCA5A5),
                          ),
                          title: Text(
                            _tr(de: 'Account löschen', en: 'Delete account'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
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
                                title: Text(
                                  _tr(
                                    de: 'Account löschen',
                                    en: 'Delete account',
                                  ),
                                ),
                                content: Text(
                                  _tr(
                                    de: 'Möchtest du deinen Account wirklich löschen? Diese Aktion ist endgültig.',
                                    en: 'Do you really want to delete your account? This action is permanent.',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dctx).pop(false),
                                    child: Text(
                                      _tr(de: 'Abbrechen', en: 'Cancel'),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dctx).pop(true),
                                    child: Text(
                                      _tr(de: 'Löschen', en: 'Delete'),
                                    ),
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
              );
            }

            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(26),
              ),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF03050A),
                      Color(0xFF050812),
                      Color(0xFF020308),
                    ],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    top: topInset + 48,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    if (settingsPage == 'password') ...[
                                      IconButton(
                                        icon: const Icon(
                                          Icons.arrow_back_rounded,
                                          color: Colors.white,
                                        ),
                                        onPressed: () => modalSetState(
                                          () => settingsPage = 'main',
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                    ],
                                    Expanded(
                                      child: Text(
                                        settingsPage == 'password'
                                            ? _tr(
                                                de: 'Passwort ändern',
                                                en: 'Change password',
                                              )
                                            : _tr(
                                                de: 'Einstellungen',
                                                en: 'Settings',
                                              ),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
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
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            layoutBuilder:
                                (
                                  Widget? currentChild,
                                  List<Widget> previousChildren,
                                ) {
                                  return Stack(
                                    alignment: Alignment.topCenter,
                                    children: <Widget>[
                                      ...previousChildren,
                                      if (currentChild != null) currentChild,
                                    ],
                                  );
                                },
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                                  final slide = Tween<Offset>(
                                    begin: const Offset(0, 0.08),
                                    end: Offset.zero,
                                  ).animate(animation);
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: slide,
                                      child: child,
                                    ),
                                  );
                                },
                            child: settingsPage == 'password'
                                ? passwordPage()
                                : mainPage(),
                          ),
                        ],
                      ),
                    ),
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
    String? subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    final hasSubtitle = subtitle != null && subtitle.trim().isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF050914),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: hasSubtitle ? 2 : 6,
        ),
        leading: _buildSettingsIcon(icon, iconColor),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        subtitle: hasSubtitle
            ? Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.54),
                  fontSize: 12,
                ),
              )
            : null,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  Widget _buildReminderTimeTile(StateSetter modalSetState) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF050914),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: _buildSettingsIcon(
          Icons.schedule_rounded,
          const Color(0xFF60A5FA),
        ),
        title: Text(
          _tr(de: 'Erinnerungszeit', en: 'Reminder time'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          _notificationsEnabled
              ? _tr(de: 'Täglich', en: 'Daily')
              : _tr(de: 'Inaktiv', en: 'Inactive'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white.withOpacity(0.54), fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFFEC4899).withOpacity(0.14),
            border: Border.all(
              color: const Color(0xFFF472B6).withOpacity(0.28),
            ),
          ),
          child: Text(
            _formatReminderTime(_notificationReminderTime),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
        onTap: _settingsBusy
            ? null
            : () => _openReminderTimePicker(modalSetState),
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
      fillColor: const Color(0xFF050914),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.09)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.09)),
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
      fillColor: const Color(0xFF030611),
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
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.66),
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
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

  Widget _buildActivityHeatmap() {
    final weeks = _activityHeatmapWeeks;
    if (weeks.isEmpty) {
      return Text(
        'Noch keine Aktivität vorhanden.',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.68)),
      );
    }

    const cellSize = 17.0;
    const cellGap = 5.0;
    const weekdayWidth = 26.0;
    final weekHeight = cellSize * 7 + cellGap * 6;
    const weekdayLabels = <String>['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    final accent = _isStepsActivityMode
        ? const Color(0xFFFB923C)
        : const Color(0xFFFF4FB3);

    Widget buildCell(Map<String, dynamic> day) {
      final value = _activityValue(day);
      final isToday = day['isToday'] == true;
      final isFuture = day['isFuture'] == true;
      return Container(
        width: cellSize,
        height: cellSize,
        margin: const EdgeInsets.only(bottom: cellGap),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          color: _activityColor(value, isFuture: isFuture),
          border: Border.all(
            color: _activityBorderColor(value, isToday: isToday),
            width: isToday ? 1.6 : 1,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: CupertinoSlidingSegmentedControl<String>(
            groupValue: _activityMode,
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            thumbColor: accent.withValues(alpha: 0.32),
            padding: const EdgeInsets.all(4),
            children: const {
              'workouts': Padding(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: Text(
                  'Workouts',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              'steps': Padding(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: Text(
                  'Schritte',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
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
        Row(
          children: [
            Expanded(
              child: Text(
                _activityTotalLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.68),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                _activityYearTapPosition = details.globalPosition;
              },
              onTap: _openActivityYearPicker,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_selectedActivityYear',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (_activityYears.length > 1) ...[
                      const SizedBox(width: 6),
                      Icon(
                        CupertinoIcons.chevron_down,
                        color: Colors.white.withValues(alpha: 0.72),
                        size: 14,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.black.withValues(alpha: 0.1),
            border: Border.all(color: accent.withValues(alpha: 0.18)),
          ),
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
                                    color: Colors.white.withValues(alpha: 0.62),
                                    fontSize: 9.5,
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
                    padding: const EdgeInsets.only(right: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: weeks
                              .map((week) {
                                return Container(
                                  width: cellSize,
                                  margin: const EdgeInsets.only(right: cellGap),
                                  child: Text(
                                    _activityMonthLabel(week),
                                    overflow: TextOverflow.visible,
                                    softWrap: false,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.66,
                                      ),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                );
                              })
                              .toList(growable: false),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: weeks
                              .map((week) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    right: cellGap,
                                  ),
                                  child: Column(
                                    children: week
                                        .map((day) => buildCell(day))
                                        .toList(growable: false),
                                  ),
                                );
                              })
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
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Weniger',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.56),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            for (var level = 0; level <= 4; level++)
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: _activityColor(_activityLegendValue(level)),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
            const SizedBox(width: 2),
            Text(
              'Mehr',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.56),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final userName = _usernameController.text.isNotEmpty
        ? _usernameController.text
        : _tr(de: 'Benutzer', en: 'User');
    final email = _string(
      _profile['email'],
      fallback: _string(
        _profile['Email'],
        fallback: _tr(de: 'Keine E-Mail', en: 'No email'),
      ),
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
            title: _tr(de: 'Mein Profil', en: 'My Profile'),
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
                  tooltip: _tr(de: 'Einstellungen', en: 'Settings'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Stats overview (mobile-friendly)
          _SectionCard(
            title: _tr(de: 'Statistiken', en: 'Statistics'),
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
                    label: _tr(de: 'Workouts gesamt', en: 'Total workouts'),
                    value: '${_profileStats['totalWorkouts'] ?? 0}',
                    icon: const Icon(
                      Icons.fitness_center,
                      color: Color(0xFFA855F7),
                    ),
                  ),
                  _buildStatCard(
                    label: _tr(de: 'Trainingszeit', en: 'Training time'),
                    value: '${_profileStats['trainingHours'] ?? 0}h',
                    icon: const Icon(Icons.timer, color: Color(0xFF60A5FA)),
                  ),
                  _buildStatCard(
                    label: _tr(de: 'Kalorien', en: 'Calories'),
                    value: '${_profileStats['caloriesBurned'] ?? 0}',
                    icon: const Icon(
                      Icons.local_fire_department,
                      color: Color(0xFFF97316),
                    ),
                  ),
                  _buildStatCard(
                    label: _tr(de: 'Längster Streak', en: 'Longest streak'),
                    value: _tr(
                      de: '${_profileStats['longestStreak'] ?? 0} Tage',
                      en: '${_profileStats['longestStreak'] ?? 0} days',
                    ),
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
                        ? 124.0
                        : 116.0;
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

          _SectionCard(
            title: 'Wöchentliche Aktivität',
            child: _buildActivityHeatmap(),
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
