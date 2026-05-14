part of '../app_shell_screen.dart';

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
      widget.showSnack(
        _lt(
          de: 'Leaderboard konnte nicht geladen werden.',
          en: 'Leaderboard could not be loaded.',
        ),
      );
    }
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return Color(0xFFD4AF37);
      case 2:
        return Color(0xFFC0C7D1);
      case 3:
        return Color(0xFFCD7F32);
      default:
        return Color(0xFF475569);
    }
  }

  Color _rankHighlightColor(int rank) {
    switch (rank) {
      case 1:
        return Color(0xFFFFECB3);
      case 2:
        return Color(0xFFF3F4F6);
      case 3:
        return Color(0xFFF1C38A);
      default:
        return Color(0xFFE2E8F0);
    }
  }

  Color _rankShadowColor(int rank) {
    switch (rank) {
      case 1:
        return Color(0xFF7A5A12);
      case 2:
        return Color(0xFF6B7280);
      case 3:
        return Color(0xFF7B4A1D);
      default:
        return Color(0xFF1E293B);
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
        color: imageUrl == null ? Color(0xFF1E293B) : null,
      ),
      child: ClipOval(
        child: imageUrl == null
            ? Image.asset(_noProfilePictureAsset, fit: BoxFit.cover)
            : _buildProfileImageFromUrl(imageUrl, fit: BoxFit.cover),
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
      backgroundColor: Color(0xFF0F172A),
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
        Text(
          _lt(de: 'Globales Ranking', en: 'Global Ranking'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _lt(
            de: 'Kämpfe dich durch Workouts und Quests nach oben.',
            en: 'Climb through workouts and quests.',
          ),
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
      title: _lt(de: 'Top Champions', en: 'Top Champions'),
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
    final rankHighlightColor = _rankHighlightColor(place);
    final rankShadowColor = _rankShadowColor(place);
    final avatarSize = isTablet
        ? (isFirst ? 72.0 : (place == 2 ? 58.0 : 48.0))
        : isCompact
        ? (isFirst ? 52.0 : (place == 2 ? 42.0 : 34.0))
        : (isFirst ? 60.0 : (place == 2 ? 48.0 : 36.0));
    final cardHeight = isTablet
        ? (isFirst ? 254.0 : (place == 2 ? 222.0 : 194.0))
        : isCompact
        ? (isFirst ? 214.0 : (place == 2 ? 184.0 : 160.0))
        : (isFirst ? 230.0 : (place == 2 ? 198.0 : 174.0));
    final nameFontSize = isTablet ? 14.0 : 13.0;
    final metaFontSize = isTablet ? 12.0 : 11.0;
    final xpFontSize = isTablet ? 13.0 : 12.0;

    return Container(
      height: cardHeight,
      padding: EdgeInsets.all(isTablet ? 8 : 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            rankHighlightColor.withOpacity(isFirst ? 0.12 : 0.08),
            rankColor.withOpacity(isFirst ? 0.18 : 0.14),
            rankShadowColor.withOpacity(isFirst ? 0.42 : 0.34),
            const Color(0xFF0B1220),
          ],
          stops: const [0.0, 0.28, 0.72, 1.0],
        ),
        border: Border.all(
          color: rankHighlightColor.withOpacity(isFirst ? 0.34 : 0.24),
        ),
        boxShadow: [
          BoxShadow(
            color: rankShadowColor.withOpacity(isFirst ? 0.18 : 0.12),
            blurRadius: isFirst ? 24 : 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(isTablet ? 3.0 : 2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [rankHighlightColor, rankColor, rankShadowColor],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: rankShadowColor.withOpacity(
                          isFirst ? 0.28 : 0.2,
                        ),
                        blurRadius: isFirst ? 18 : 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: _buildLeaderboardAvatar(player, size: avatarSize),
                ),
                SizedBox(height: isTablet ? 6 : 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: rankColor.withOpacity(0.18),
                    border: Border.all(
                      color: rankHighlightColor.withOpacity(0.26),
                    ),
                  ),
                  child: Text(
                    '#$place',
                    style: TextStyle(
                      color: rankHighlightColor,
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
                      const Icon(
                        Icons.star,
                        color: Color(0xFFFBBF24),
                        size: 14,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  'Level ${player['level']}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: metaFontSize,
                  ),
                ),
                SizedBox(height: isTablet ? 6 : 4),
                Text(
                  '${_formatCompactNumber(_toInt(player['totalXp']))} XP',
                  style: TextStyle(
                    color: rankHighlightColor,
                    fontWeight: FontWeight.w800,
                    fontSize: xpFontSize,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardRow(Map<String, dynamic> player) {
    final rank = player['rank'] as int;
    final isCurrentUser = player['isCurrentUser'] == true;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.zero,
        color: isCurrentUser
            ? Color(0xFFA855F7).withOpacity(0.14)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: isCurrentUser
                ? Color(0xFFEC4899).withOpacity(0.22)
                : Colors.white.withOpacity(0.08),
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: rank <= 3
                    ? _rankColor(rank)
                    : Colors.white.withOpacity(0.72),
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _buildLeaderboardAvatar(player, size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
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
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.star,
                          color: Color(0xFFFBBF24),
                          size: 13,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'lvl ${player['level']}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.66),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCompactNumber(_toInt(player['totalXp'])),
                style: const TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'XP',
                style: TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
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
            title: _lt(de: 'Globale Rangliste', en: 'Global Leaderboard'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _entries.isEmpty
                  ? [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          _lt(
                            de: 'Noch keine Leaderboard-Daten vorhanden.',
                            en: 'No leaderboard data yet.',
                          ),
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
