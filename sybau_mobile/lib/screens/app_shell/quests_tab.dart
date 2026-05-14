part of '../app_shell_screen.dart';

class QuestsTab extends StatefulWidget {
  const QuestsTab({
    required this.onRefreshHeader,
    required this.onQuestStatusChanged,
    required this.showSnack,
    super.key,
  });

  final Future<void> Function() onRefreshHeader;
  final Future<void> Function() onQuestStatusChanged;
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
      await widget.onQuestStatusChanged();
    } catch (_) {
      if (!mounted) return;
      if (showLoader) {
        setState(() => _loading = false);
      }
      widget.showSnack(
        _lt(
          de: 'Quest-Daten konnten nicht geladen werden.',
          en: 'Quest data could not be loaded.',
        ),
      );
    }
  }

  Future<void> _claim(int userQuestId) async {
    try {
      await ApiService.claimQuestReward(userQuestId);
      widget.showSnack(
        _lt(de: 'Belohnung eingesammelt.', en: 'Reward claimed.'),
      );
      await _load(showLoader: false);
      await widget.onRefreshHeader();
    } catch (_) {
      widget.showSnack(
        _lt(
          de: 'Belohnung konnte nicht eingesammelt werden.',
          en: 'Reward could not be claimed.',
        ),
      );
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
        return Color(0xFF60A5FA);
      case 'epic':
        return Color(0xFFA855F7);
      case 'legendary':
        return Color(0xFFFBBF24);
      case 'common':
      default:
        return Color(0xFF9CA3AF);
    }
  }

  Color _sectionAccent(String type) {
    switch (type) {
      case 'weekly':
        return Color(0xFF60A5FA);
      case 'monthly':
        return Color(0xFFFBBF24);
      case 'daily':
      default:
        return Color(0xFFEC4899);
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
          final isCompleted = _toBool(m['isCompleted'] ?? m['IsCompleted']);
          final rewardClaimed = _toBool(
            m['isRewardClaimed'] ?? m['IsRewardClaimed'],
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withOpacity(0.06),
                border: Border.all(
                  color: isCompleted
                      ? Color(0xFF22C55E).withOpacity(0.44)
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
                          _td(rarity),
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
                    _td(_questName(m)),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _td(
                      _string(
                        m['description'],
                        fallback: _lt(
                          de: 'Quest Beschreibung',
                          en: 'Quest description',
                        ),
                      ),
                    ),
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
                        isCompleted ? Color(0xFF22C55E) : Color(0xFFEC4899),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '+${_formatCompactNumber(_toInt(m['xpReward']))} XP',
                        style: const TextStyle(
                          color: Color(0xFF60A5FA),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_toInt(m['coinReward']) > 0)
                        Text(
                          '+${_formatCompactNumber(_toInt(m['coinReward']))} Coins',
                          style: const TextStyle(
                            color: Color(0xFFFBBF24),
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
                              gradient: LinearGradient(
                                colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                              ),
                            ),
                            child: SizedBox(
                              height: 36,
                              width: 102,
                              child: Center(
                                child: Text(
                                  _lt(de: 'Einfordern', en: 'Claim'),
                                  style: const TextStyle(
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
                        Text(
                          _lt(de: 'Erhalten', en: 'Claimed'),
                          style: const TextStyle(
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
          Text(
            _lt(de: 'Quest Log', en: 'Quest Log'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _lt(
              de: 'Schließe Quests ab und sammle epische Belohnungen.',
              en: 'Complete quests and collect epic rewards.',
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
                _buildQuestStatPill(
                  icon: Icons.emoji_events,
                  label: _lt(de: 'Abgeschl.', en: 'Done'),
                  value: '${_toInt(_stats['completed'])}',
                  accent: Color(0xFFFBBF24),
                ),
                const SizedBox(width: 10),
                _buildQuestStatPill(
                  icon: Icons.flash_on,
                  label: _lt(de: 'Aktiv', en: 'Active'),
                  value: '${_toInt(_stats['active'])}',
                  accent: Color(0xFF60A5FA),
                ),
                const SizedBox(width: 10),
                _buildQuestStatPill(
                  icon: Icons.auto_awesome,
                  label: _lt(de: 'Verdient', en: 'Earned'),
                  value:
                      '${_formatCompactNumber(_toInt(_stats['totalXpEarned']))} XP',
                  accent: Color(0xFFEC4899),
                ),
              ],
            ),
          ),
          _buildQuestSection(
            title: _lt(de: 'Tägliche Quests', en: 'Daily Quests'),
            icon: '🔥',
            type: 'daily',
            quests: _dailyQuests,
          ),
          _buildQuestSection(
            title: _lt(de: 'Wöchentliche Quests', en: 'Weekly Quests'),
            icon: '🎯',
            type: 'weekly',
            quests: _weeklyQuests,
          ),
          _buildQuestSection(
            title: _lt(de: 'Monatliche Quests', en: 'Monthly Quests'),
            icon: '🏆',
            type: 'monthly',
            quests: _monthlyQuests,
          ),
          if (_quests.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                _lt(de: 'Keine Quests verfügbar.', en: 'No quests available.'),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.68)),
              ),
            ),
        ],
      ),
    );
  }
}
