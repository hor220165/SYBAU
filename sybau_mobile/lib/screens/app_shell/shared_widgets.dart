part of '../app_shell_screen.dart';

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

Widget _buildBoosterPercentBadges(
  Booster booster, {
  double fontSize = 10,
  double horizontalPadding = 6,
  double verticalPadding = 2,
  double gap = 4,
}) {
  final badges = <Widget>[
    if (booster.xpBoostPercentage > 0)
      _buildBoostPercentBadge(
        value: booster.xpBoostPercentage,
        color: const Color(0xFF60A5FA),
        fontSize: fontSize,
        horizontalPadding: horizontalPadding,
        verticalPadding: verticalPadding,
      ),
    if (booster.coinBoostPercentage > 0)
      _buildBoostPercentBadge(
        value: booster.coinBoostPercentage,
        color: const Color(0xFFFACC15),
        fontSize: fontSize,
        horizontalPadding: horizontalPadding,
        verticalPadding: verticalPadding,
      ),
  ];

  if (badges.isEmpty) return const SizedBox.shrink();

  return Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var i = 0; i < badges.length; i++) ...[
        if (i > 0) SizedBox(width: gap),
        badges[i],
      ],
    ],
  );
}

Widget _buildBoostPercentBadge({
  required int value,
  required Color color,
  required double fontSize,
  required double horizontalPadding,
  required double verticalPadding,
}) {
  return Padding(
    padding: EdgeInsets.symmetric(
      horizontal: horizontalPadding * 0.2,
      vertical: verticalPadding * 0.2,
    ),
    child: Text(
      '+$value%',
      maxLines: 1,
      overflow: TextOverflow.visible,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        height: 1.0,
        shadows: [Shadow(color: color.withOpacity(0.45), blurRadius: 8)],
      ),
    ),
  );
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement});

  final Map<String, dynamic> achievement;

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement['unlocked'] == true;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: unlocked
            ? Color(0xFFFBBF24).withOpacity(0.14)
            : Colors.white.withOpacity(0.03),
        border: Border.all(
          color: unlocked
              ? Color(0xFFFBBF24).withOpacity(0.42)
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
                    fontSize: 12.5,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                unlocked ? Icons.check_circle : Icons.lock,
                color: unlocked ? Color(0xFFFBBF24) : Colors.white54,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 7),
          Expanded(
            child: Text(
              _string(achievement['description']),
              maxLines: 3,
              overflow: TextOverflow.fade,
              style: TextStyle(
                color: Colors.white.withOpacity(0.72),
                height: 1.2,
                fontSize: 11,
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
        color: resolved == null ? Color(0xFF1E293B) : null,
      ),
      child: ClipOval(
        child: resolved == null
            ? Image.asset(_noProfilePictureAsset, fit: BoxFit.cover)
            : _buildProfileImageFromUrl(resolved, fit: BoxFit.cover),
      ),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.onPressed,
    required this.label,
    this.compact = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final interactive = onPressed != null;
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
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 9),
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
                    fontSize: 15.5,
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

bool _toBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return fallback;
}

String _string(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final v = value.toString();
  return v.isEmpty ? fallback : v;
}
