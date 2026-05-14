part of '../app_shell_screen.dart';

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
  final TextEditingController _requestController = TextEditingController();
  final TextEditingController _challengeTitleController =
      TextEditingController();
  final TextEditingController _challengeDescriptionController =
      TextEditingController();
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
  String _challengeGoalUnit = 'reps';
  String _challengeDistanceUnit = 'm';

  String _challengeSecondsToTime(int value) {
    final seconds = value.clamp(0, 999999);
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  int _challengeParseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 3) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final s = int.tryParse(parts[2]) ?? 0;
    return h * 3600 + m * 60 + s;
  }

  String _challengeFormatTimeInput(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    final d = digits.length > 6 ? digits.substring(digits.length - 6) : digits;
    if (d.isEmpty) return '00:00:00';
    final padded = d.padLeft(6, '0');
    final h = int.tryParse(padded.substring(0, 2)) ?? 0;
    final m = int.tryParse(padded.substring(2, 4)) ?? 0;
    final s = int.tryParse(padded.substring(4, 6)) ?? 0;
    return _challengeSecondsToTime(h * 3600 + m * 60 + s);
  }

  double _challengeParseDistanceDraft(String raw) {
    return double.tryParse(raw.replaceAll(',', '.')) ?? 0;
  }

  String _challengeFormatDistanceDraft(double value, String unit) {
    if (unit == 'km') {
      var text = value.toStringAsFixed(2);
      text = text.replaceFirst(RegExp(r'\.?0+$'), '');
      return text.isEmpty ? '0' : text;
    }
    return value.round().toString();
  }

  String _formatChallengeAmount(int value, String unit) {
    final lower = unit.toLowerCase();
    if (lower == 'time') {
      final totalSeconds = value.clamp(0, 1 << 30);
      final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
      final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
      final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
    if (lower == 'km') {
      final km = value / 1000;
      return km == km.roundToDouble() ? '${km.round()}' : km.toStringAsFixed(1);
    }
    if (lower == 'distance' || lower == 'm') {
      return '$value';
    }
    return '$value';
  }

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
        _userDirectory = directory;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      widget.showSnack(
        _lt(
          de: 'Freunde konnten nicht geladen werden.',
          en: 'Friends could not be loaded.',
        ),
      );
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
      widget.showSnack(_lt(de: 'Anfrage gesendet.', en: 'Request sent.'));
      await _load();
    } catch (_) {
      widget.showSnack(
        _lt(de: 'Anfrage fehlgeschlagen.', en: 'Request failed.'),
      );
    }
  }

  Future<void> _acceptChallenge(int id) async {
    try {
      await ApiService.acceptFriendChallenge(id);
      widget.showSnack(
        _lt(de: 'Challenge angenommen.', en: 'Challenge accepted.'),
      );
      await _load();
    } catch (_) {
      widget.showSnack(
        _lt(
          de: 'Challenge konnte nicht angenommen werden.',
          en: 'Challenge could not be accepted.',
        ),
      );
    }
  }

  Future<void> _declineChallenge(int id) async {
    try {
      await ApiService.declineFriendChallenge(id);
      widget.showSnack(
        _lt(de: 'Challenge abgelehnt.', en: 'Challenge declined.'),
      );
      await _load();
    } catch (_) {
      widget.showSnack(
        _lt(
          de: 'Challenge konnte nicht abgelehnt werden.',
          en: 'Challenge could not be declined.',
        ),
      );
    }
  }

  Future<void> _hideChallenge(int id) async {
    try {
      await ApiService.hideFriendChallenge(id);
      widget.showSnack(
        _lt(de: 'Challenge ausgeblendet.', en: 'Challenge hidden.'),
      );
      await _load();
    } catch (_) {
      widget.showSnack(
        _lt(
          de: 'Challenge konnte nicht ausgeblendet werden.',
          en: 'Challenge could not be hidden.',
        ),
      );
    }
  }

  int _challengeGoalAmountToSend() {
    if (_challengeGoalUnit == 'time') {
      return _challengeParseTime(_challengeGoalController.text.trim());
    }

    if (_challengeGoalUnit == 'distance') {
      final raw = _challengeParseDistanceDraft(
        _challengeGoalController.text.trim(),
      );
      if (_challengeDistanceUnit == 'km') {
        return (raw * 1000).round();
      }
      return raw.round();
    }

    return int.tryParse(_challengeGoalController.text.trim()) ?? 100;
  }

  Future<void> _openChallengeIosTimePicker(VoidCallback refresh) async {
    var selected = Duration(
      seconds: _challengeParseTime(
        _challengeGoalController.text.trim().isEmpty
            ? '00:10:00'
            : _challengeGoalController.text.trim(),
      ),
    );

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
                          child: const Text(
                            'Abbrechen',
                            style: TextStyle(
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
                            _challengeGoalController.text =
                                _challengeSecondsToTime(selected.inSeconds);
                            refresh();
                            Navigator.of(modalContext).pop();
                          },
                          child: Text(
                            _lt(de: 'Fertig', en: 'Done'),
                            style: const TextStyle(
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

  Future<void> _createChallenge() async {
    final opponent = _challengeOpponent;
    final title = _challengeTitleController.text.trim();
    if (opponent == null || title.isEmpty) {
      widget.showSnack(
        _lt(
          de: 'Bitte Titel und Gegner auswählen.',
          en: 'Please choose a title and opponent.',
        ),
      );
      return;
    }

    final goalAmount = _challengeGoalAmountToSend();
    final durationHours =
        int.tryParse(_challengeDurationController.text.trim()) ?? 0;
    final goalUnit = _challengeGoalUnit == 'distance'
        ? _challengeDistanceUnit
        : _challengeGoalUnit;

    if (goalAmount <= 0) {
      widget.showSnack(
        _challengeGoalUnit == 'time'
            ? _lt(
                de: 'Bitte eine gültige Zielzeit eingeben.',
                en: 'Please enter a valid goal time.',
              )
            : _lt(
                de: 'Bitte ein gültiges Ziel eingeben.',
                en: 'Please enter a valid goal.',
              ),
      );
      return;
    }

    if (durationHours < 1 || durationHours > 168) {
      widget.showSnack(
        _lt(
          de: 'Stunden müssen zwischen 1 und 168 liegen.',
          en: 'Hours must be between 1 and 168.',
        ),
      );
      return;
    }

    try {
      await ApiService.createFriendChallenge(
        opponentId: _toInt(
          opponent['friendId'],
          fallback: _toInt(
            opponent['userId'],
            fallback: _toInt(opponent['id']),
          ),
        ),
        title: title,
        description: _challengeDescriptionController.text.trim(),
        goalAmount: goalAmount,
        goalUnit: goalUnit,
        durationHours: durationHours,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.showSnack(_lt(de: 'Challenge gesendet.', en: 'Challenge sent.'));
      await _load();
    } catch (error) {
      if (error is ApiException) {
        try {
          final parsed = jsonDecode(error.body ?? '');
          if (parsed is Map<String, dynamic>) {
            final message = _string(parsed['message']);
            if (message.isNotEmpty) {
              widget.showSnack(message);
              return;
            }
          }
        } catch (_) {}
      }

      final raw = error.toString();
      final bodyMatch = RegExp(
        r'Request failed \(\d+\): (.+)$',
      ).firstMatch(raw);
      if (bodyMatch != null) {
        try {
          final parsed = jsonDecode(bodyMatch.group(1)!);
          if (parsed is Map<String, dynamic>) {
            final message = _string(parsed['message']);
            if (message.isNotEmpty) {
              widget.showSnack(message);
              return;
            }
          }
        } catch (_) {}
      }

      widget.showSnack(
        _lt(
          de: 'Challenge konnte nicht erstellt werden.',
          en: 'Challenge could not be created.',
        ),
      );
    }
  }

  Future<void> _updateProgress(Map<String, dynamic> challenge) async {
    final goalUnit = _string(challenge['goalUnit'], fallback: 'reps');
    final amount = goalUnit.toLowerCase() == 'time'
        ? _parseChallengeTimeToSeconds(_progressController.text.trim())
        : (int.tryParse(_progressController.text.trim()) ?? 0);
    if (amount <= 0) return;

    try {
      final data = await ApiService.updateFriendChallengeProgress(
        id: _toInt(challenge['id']),
        amount: amount,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.showSnack(
        _string(
          data['message'],
          fallback: _lt(de: 'Fortschritt gemeldet.', en: 'Progress reported.'),
        ),
      );
      await _load();
      await widget.onRefreshHeader();
    } catch (_) {
      widget.showSnack(
        _lt(
          de: 'Fortschritt konnte nicht gemeldet werden.',
          en: 'Progress could not be reported.',
        ),
      );
    }
  }

  int _parseChallengeTimeToSeconds(String raw) {
    final parts = raw
        .split(':')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
    if (parts.length == 3)
      return (parts[0] * 3600) + (parts[1] * 60) + parts[2];
    if (parts.length == 2) return (parts[0] * 60) + parts[1];
    if (parts.length == 1) return parts[0];
    return 0;
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
      hintText: _lt(de: 'Benutzername suchen...', en: 'Search username...'),
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
      widget.showSnack(_lt(de: 'Anfrage akzeptiert.', en: 'Request accepted.'));
      await _load();
    } catch (_) {
      widget.showSnack(
        _lt(de: 'Akzeptieren fehlgeschlagen.', en: 'Accept failed.'),
      );
    }
  }

  Future<void> _decline(int id) async {
    try {
      await ApiService.declineFriendRequest(id);
      widget.showSnack(_lt(de: 'Anfrage abgelehnt.', en: 'Request declined.'));
      await _load();
    } catch (_) {
      widget.showSnack(
        _lt(de: 'Ablehnen fehlgeschlagen.', en: 'Decline failed.'),
      );
    }
  }

  Future<void> _remove(int id) async {
    try {
      await ApiService.removeFriend(id);
      widget.showSnack(_lt(de: 'Freund entfernt.', en: 'Friend removed.'));
      await _load();
    } catch (_) {
      widget.showSnack(
        _lt(de: 'Entfernen fehlgeschlagen.', en: 'Remove failed.'),
      );
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
        color: Color(0xFF1E293B),
      ),
      child: ClipOval(
        child: imageUrl == null
            ? Image.asset(_noProfilePictureAsset, fit: BoxFit.cover)
            : _buildProfileImageFromUrl(imageUrl, fit: BoxFit.cover),
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
      backgroundColor: Color(0xFF05070D),
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
    _challengeGoalController.text = '100';
    _challengeDurationController.text = '24';
    _challengeGoalUnit = 'reps';
    _challengeDistanceUnit = 'm';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, modalSetState) {
          Future<void> changeGoalUnit(String nextUnit) async {
            if (_challengeGoalUnit == nextUnit) return;

            modalSetState(() {
              if (nextUnit == 'time') {
                _challengeGoalController.text = _challengeFormatTimeInput(
                  _challengeGoalController.text.trim(),
                );
              } else if (_challengeGoalUnit == 'time') {
                _challengeGoalController.text = '100';
              }

              _challengeGoalUnit = nextUnit;
            });
          }

          void changeDistanceUnit(String nextUnit) {
            if (_challengeDistanceUnit == nextUnit) return;

            final raw = _challengeParseDistanceDraft(
              _challengeGoalController.text.trim(),
            );
            final converted = _challengeDistanceUnit == 'm'
                ? raw / 1000
                : raw * 1000;

            modalSetState(() {
              _challengeDistanceUnit = nextUnit;
              if (_challengeGoalController.text.trim().isNotEmpty) {
                _challengeGoalController.text = _challengeFormatDistanceDraft(
                  converted,
                  nextUnit,
                );
              }
            });
          }

          return Padding(
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
                    _lt(
                      de: 'Challenge an ${_string(friend['userName'], fallback: _string(friend['friendUserName']))}',
                      en: 'Challenge ${_string(friend['userName'], fallback: _string(friend['friendUserName']))}',
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _settingsTextField(
                    _challengeTitleController,
                    _lt(de: 'Titel', en: 'Title'),
                  ),
                  const SizedBox(height: 10),
                  _settingsTextField(
                    _challengeDescriptionController,
                    _lt(de: 'Beschreibung', en: 'Description'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _challengeGoalUnit,
                          dropdownColor: const Color(0xFF0F172A),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: _lt(de: 'Einheit', en: 'Unit'),
                            labelStyle: TextStyle(
                              color: Colors.white.withOpacity(0.72),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.04),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.12),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.12),
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                              borderSide: BorderSide(color: Color(0xFFEC4899)),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'reps',
                              child: Text('Reps'),
                            ),
                            DropdownMenuItem(
                              value: 'time',
                              child: Text('Time'),
                            ),
                            DropdownMenuItem(
                              value: 'distance',
                              child: Text('Distance'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            changeGoalUnit(value);
                          },
                        ),
                      ),
                      if (_challengeGoalUnit == 'distance') ...[
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 90,
                          child: DropdownButtonFormField<String>(
                            value: _challengeDistanceUnit,
                            dropdownColor: const Color(0xFF0F172A),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'm/km',
                              labelStyle: TextStyle(
                                color: Colors.white.withOpacity(0.72),
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.04),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                                borderSide: BorderSide(
                                  color: Color(0xFFEC4899),
                                ),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'm', child: Text('m')),
                              DropdownMenuItem(value: 'km', child: Text('km')),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              changeDistanceUnit(value);
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _challengeGoalUnit == 'time'
                            ? (Theme.of(context).platform == TargetPlatform.iOS
                                  ? GestureDetector(
                                      onTap: () => _openChallengeIosTimePicker(
                                        () => modalSetState(() {}),
                                      ),
                                      child: InputDecorator(
                                        decoration: InputDecoration(
                                          labelText: _lt(
                                            de: 'Ziel',
                                            en: 'Goal',
                                          ),
                                          labelStyle: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.72,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white.withOpacity(
                                            0.04,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.white.withOpacity(
                                                0.12,
                                              ),
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.white.withOpacity(
                                                0.12,
                                              ),
                                            ),
                                          ),
                                          focusedBorder:
                                              const OutlineInputBorder(
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(12),
                                                ),
                                                borderSide: BorderSide(
                                                  color: Color(0xFFEC4899),
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
                                              _challengeGoalController.text
                                                      .trim()
                                                      .isEmpty
                                                  ? '00:00:00'
                                                  : _challengeGoalController
                                                        .text,
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
                                  : TextField(
                                      controller: _challengeGoalController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: _lt(de: 'Ziel', en: 'Goal'),
                                        hintText: '00:00:00',
                                        hintStyle: TextStyle(
                                          color: Colors.white.withOpacity(0.35),
                                        ),
                                        labelStyle: TextStyle(
                                          color: Colors.white.withOpacity(0.72),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(
                                          0.04,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.white.withOpacity(
                                              0.12,
                                            ),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.white.withOpacity(
                                              0.12,
                                            ),
                                          ),
                                        ),
                                        focusedBorder: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(12),
                                          ),
                                          borderSide: BorderSide(
                                            color: Color(0xFFEC4899),
                                          ),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        final formatted =
                                            _challengeFormatTimeInput(value);
                                        if (formatted ==
                                            _challengeGoalController.text) {
                                          return;
                                        }
                                        _challengeGoalController
                                            .value = TextEditingValue(
                                          text: formatted,
                                          selection: TextSelection.collapsed(
                                            offset: formatted.length,
                                          ),
                                        );
                                        modalSetState(() {});
                                      },
                                    ))
                            : _settingsTextField(
                                _challengeGoalController,
                                _lt(de: 'Ziel', en: 'Goal'),
                                keyboardType: _challengeGoalUnit == 'distance'
                                    ? const TextInputType.numberWithOptions(
                                        decimal: true,
                                      )
                                    : TextInputType.number,
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _settingsTextField(
                          _challengeDurationController,
                          _lt(de: 'Stunden', en: 'Hours'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white.withOpacity(0.04),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: Wrap(
                      spacing: 14,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/XP_Pixel.png',
                              width: 16,
                              height: 16,
                              filterQuality: FilterQuality.none,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _lt(de: 'XP automatisch', en: 'XP automatic'),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/SYBAU_Coin.png',
                              width: 16,
                              height: 16,
                              filterQuality: FilterQuality.none,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _lt(
                                de: 'Coins automatisch',
                                en: 'Coins automatic',
                              ),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: _GradientActionButton(
                      onPressed: () async {
                        await _createChallenge();
                      },
                      label: _lt(de: 'Challenge senden', en: 'Send challenge'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openProgressModal(Map<String, dynamic> challenge) {
    _progressController.text = '1';
    final goalUnit = _string(challenge['goalUnit'], fallback: 'reps');
    if (goalUnit.toLowerCase() == 'time') {
      _progressController.text = '00:01:00';
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Color(0xFF0F172A),
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
            _settingsTextField(
              _progressController,
              _lt(de: 'Fortschritt', en: 'Progress'),
              keyboardType: goalUnit.toLowerCase() == 'time'
                  ? TextInputType.datetime
                  : TextInputType.number,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: _GradientActionButton(
                onPressed: () => _updateProgress(challenge),
                label: _lt(de: 'Fortschritt melden', en: 'Report progress'),
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
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType:
          keyboardType ??
          (label == 'Titel' || label == 'Beschreibung'
              ? TextInputType.text
              : TextInputType.number),
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
      ('friends', _lt(de: 'Freunde', en: 'Friends'), Icons.groups_rounded),
      (
        'requests',
        _lt(de: 'Anfragen', en: 'Requests'),
        Icons.person_add_alt_1_rounded,
      ),
      (
        'challenges',
        _lt(de: 'Challenges', en: 'Challenges'),
        Icons.emoji_events_rounded,
      ),
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
                          ? Color(0xFFEC4899).withOpacity(0.26)
                          : Colors.white.withOpacity(0.05),
                      border: Border.all(
                        color: active
                            ? Color(0xFFEC4899).withOpacity(0.55)
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
            color: Color(0xFFFDA4AF),
          ),
          IconButton(
            onPressed: _toInt(friend['id']) == 0
                ? null
                : () => _remove(_toInt(friend['id'])),
            icon: const Icon(Icons.delete_outline_rounded),
            color: Color(0xFFFCA5A5),
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
    final goalUnit = _string(challenge['goalUnit'], fallback: 'reps');
    final formattedMyProgress = _formatChallengeAmount(myProgress, goalUnit);
    final formattedOtherProgress = _formatChallengeAmount(
      otherProgress,
      goalUnit,
    );
    final formattedGoal = _formatChallengeAmount(goal, goalUnit);

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
              _statusText(status),
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
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              Text(
                _lt(
                  de: 'Du: $formattedMyProgress/$formattedGoal',
                  en: 'You: $formattedMyProgress/$formattedGoal',
                ),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.58),
                  fontSize: 11,
                ),
              ),
              Text(
                _lt(
                  de: 'Gegner: $formattedOtherProgress/$formattedGoal',
                  en: 'Opponent: $formattedOtherProgress/$formattedGoal',
                ),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.58),
                  fontSize: 11,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/XP_Pixel.png',
                    width: 14,
                    height: 14,
                    filterQuality: FilterQuality.none,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatCompactNumber(_toInt(challenge['xpReward']))} XP',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.58),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/SYBAU_Coin.png',
                    width: 14,
                    height: 14,
                    filterQuality: FilterQuality.none,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatCompactNumber(_toInt(challenge['coinReward']))} Coins',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.58),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Text(
                _lt(
                  de: 'Ziel: $formattedGoal ${_challengeUnitShort(goalUnit)}',
                  en: 'Goal: $formattedGoal ${_challengeUnitShort(goalUnit)}',
                ),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.58),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isPendingForMe)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _GradientActionButton(
                        onPressed: id == 0 ? null : () => _acceptChallenge(id),
                        label: _lt(de: 'Annehmen', en: 'Accept'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: id == 0 ? null : () => _declineChallenge(id),
                        child: Text(_lt(de: 'Ablehnen', en: 'Decline')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildHideChallengeButton(id),
                ),
              ],
            )
          else if (status == 'Pending')
            Align(
              alignment: Alignment.centerRight,
              child: _buildHideChallengeButton(id),
            )
          else if (status == 'Accepted')
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: _GradientActionButton(
                    onPressed: () => _openProgressModal(challenge),
                    label: _lt(de: 'Fortschritt melden', en: 'Report progress'),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildHideChallengeButton(id),
                ),
              ],
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: _buildHideChallengeButton(id),
            ),
        ],
      ),
    );
  }

  Widget _buildHideChallengeButton(int id) {
    return TextButton.icon(
      onPressed: id == 0 ? null : () => _hideChallenge(id),
      icon: const Icon(
        Icons.visibility_off_rounded,
        color: Color(0xFFCBD5E1),
        size: 18,
      ),
      label: Text(
        _lt(de: 'Ausblenden', en: 'Hide'),
        style: const TextStyle(
          color: Color(0xFFCBD5E1),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _statusText(String status) {
    final color = switch (status) {
      'Accepted' => Color(0xFF22C55E),
      'Pending' => Color(0xFFF59E0B),
      'Completed' => Color(0xFFEC4899),
      'Declined' => Color(0xFFEF4444),
      _ => Color(0xFF94A3B8),
    };
    return Text(
      _localizedChallengeStatus(status),
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        shadows: [Shadow(color: color.withOpacity(0.55), blurRadius: 14)],
      ),
    );
  }

  String _localizedChallengeStatus(String status) {
    return switch (status) {
      'Accepted' => _lt(de: 'Aktiv', en: 'Active'),
      'Pending' => _lt(de: 'Ausstehend', en: 'Pending'),
      'Completed' => _lt(de: 'Abgeschlossen', en: 'Completed'),
      'Declined' => _lt(de: 'Abgelehnt', en: 'Declined'),
      'Expired' => _lt(de: 'Abgelaufen', en: 'Expired'),
      _ => status,
    };
  }

  String _challengeUnitShort(String unit) {
    return switch (unit.toLowerCase()) {
      'time' => _lt(de: 'Sek', en: 'sec'),
      'm' => 'm',
      'km' => 'km',
      'distance' => 'm',
      _ => 'Reps',
    };
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
              title: _lt(de: 'Freunde finden', en: 'Find friends'),
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
                      _lt(
                        de: 'Keine passenden Nutzer gefunden.',
                        en: 'No matching users found.',
                      ),
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
                                label: _lt(de: 'Senden', en: 'Send'),
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
              title: _lt(de: 'Freunde', en: 'Friends'),
              child: _friends.isEmpty
                  ? Text(
                      _lt(de: 'Noch keine Freunde.', en: 'No friends yet.'),
                      style: const TextStyle(color: Colors.white70),
                    )
                  : Column(
                      children: _friends
                          .map((f) => _buildFriendCard(_map(f)))
                          .toList(growable: false),
                    ),
            ),
          ] else if (_activeSection == 'requests') ...[
            _SectionCard(
              title: _lt(de: 'Eingehende Anfragen', en: 'Incoming Requests'),
              child: _requests.isEmpty
                  ? Text(
                      _lt(
                        de: 'Keine offenen Anfragen.',
                        en: 'No open requests.',
                      ),
                      style: const TextStyle(color: Colors.white70),
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
                                    child: Text(
                                      _lt(de: 'Annehmen', en: 'Accept'),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: id == 0
                                        ? null
                                        : () => _decline(id),
                                    child: Text(
                                      _lt(de: 'Ablehnen', en: 'Decline'),
                                    ),
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
              title: _lt(de: 'Gesendet', en: 'Sent'),
              child: _sentRequests.isEmpty
                  ? Text(
                      _lt(
                        de: 'Keine gesendeten offenen Anfragen.',
                        en: 'No sent open requests.',
                      ),
                      style: const TextStyle(color: Colors.white70),
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
                              subtitle: Text(
                                _lt(de: 'Gesendet', en: 'Sent'),
                                style: const TextStyle(color: Colors.white54),
                              ),
                            );
                          })
                          .toList(growable: false),
                    ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            _SectionCard(
              title: _lt(de: 'Challenge-Einladungen', en: 'Challenge Invites'),
              child: _pendingChallenges.isEmpty
                  ? Text(
                      _lt(de: 'Keine Einladungen.', en: 'No invitations.'),
                      style: const TextStyle(color: Colors.white70),
                    )
                  : Column(
                      children: _pendingChallenges
                          .map(_buildChallengeCard)
                          .toList(growable: false),
                    ),
            ),
            const SizedBox(height: 10),
            _SectionCard(
              title: _lt(de: 'Aktive Challenges', en: 'Active Challenges'),
              child: _activeChallenges.isEmpty
                  ? Text(
                      _lt(
                        de: 'Keine aktiven Challenges.',
                        en: 'No active challenges.',
                      ),
                      style: const TextStyle(color: Colors.white70),
                    )
                  : Column(
                      children: _activeChallenges
                          .map(_buildChallengeCard)
                          .toList(growable: false),
                    ),
            ),
            const SizedBox(height: 10),
            _SectionCard(
              title: _lt(de: 'Vergangene Challenges', en: 'Past Challenges'),
              child: _pastChallenges.isEmpty
                  ? Text(
                      _lt(
                        de: 'Keine vergangenen Challenges.',
                        en: 'No past challenges.',
                      ),
                      style: const TextStyle(color: Colors.white70),
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
