part of '../app_shell_screen.dart';

class AvatarTab extends StatefulWidget {
  const AvatarTab({
    required this.onRefreshHeader,
    required this.showSnack,
    super.key,
  });

  final Future<void> Function() onRefreshHeader;
  final void Function(String) showSnack;

  @override
  State<AvatarTab> createState() => _AvatarTabState();
}

class _AvatarTabState extends State<AvatarTab> {
  bool _loading = true;
  Map<String, dynamic> _profile = <String, dynamic>{};
  List<Booster> _inventory = <Booster>[];
  // _ownedItems removed — inventory driven by _inventory (Booster list) now
  final List<Booster?> _slots = <Booster?>[null, null, null, null];
  Booster? _selectingSlotFor;
  Booster? _pendingSellBooster;
  bool _sellingItem = false;

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
        ApiService.getUserBoosters(),
      ]);
      if (!mounted) return;

      final profile = _map(results[0]);
      final boostersRaw = (results[1] as List<dynamic>?) ?? <dynamic>[];
      // ownedItems removed — sell flow uses _inventory boosters now
      final boosters = boostersRaw
          .map((dynamic b) => Booster.fromJson(_map(b)))
          .where((Booster b) => b.id != null)
          .toList(growable: false);

      final avatar = _map(profile['avatar']);
      final slotNames = <String?>[
        _slotName(avatar['boost1']),
        _slotName(avatar['boost2']),
        _slotName(avatar['boost3']),
        _slotName(avatar['boost4']),
      ];

      final nextSlots = List<Booster?>.filled(4, null, growable: false);
      for (int i = 0; i < 4; i++) {
        final name = i < slotNames.length ? slotNames[i] : null;
        if (name == null) continue;
        nextSlots[i] =
            _findBoosterByName(boosters, name) ?? Booster.placeholder(name);
      }

      setState(() {
        _profile = profile;
        _inventory = boosters;
        // _ownedItems assignment removed
        for (int i = 0; i < 4; i++) {
          _slots[i] = nextSlots[i];
        }
        _selectingSlotFor = null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      widget.showSnack(
        _lt(
          de: 'Avatar-Daten konnten nicht geladen werden.',
          en: 'Avatar data could not be loaded.',
        ),
      );
    }
  }

  String? _slotName(dynamic raw) {
    final s = _string(raw);
    return s.isEmpty ? null : s;
  }

  Booster? _findBoosterByName(List<Booster> list, String name) {
    for (final booster in list) {
      if (booster.name == name) return booster;
    }
    return null;
  }

  String _rarityOf(Booster booster) {
    final explicit = booster.rarity.toLowerCase();
    if (explicit == 'mythic' ||
        explicit == 'legendary' ||
        explicit == 'epic' ||
        explicit == 'rare' ||
        explicit == 'common') {
      return explicit;
    }
    final total = booster.xpBoostPercentage + booster.coinBoostPercentage;
    if (total >= 100) return 'mythic';
    if (total >= 60) return 'legendary';
    if (total >= 40) return 'epic';
    if (total >= 20) return 'rare';
    return 'common';
  }

  String _boosterIcon(Booster booster) {
    final xp = booster.xpBoostPercentage;
    final coin = booster.coinBoostPercentage;
    if (xp > 0 && coin > 0) return '🔥';
    if (coin > 0) return '🪙';
    return '⚡';
  }

  int _sellPriceForBooster(Booster booster) {
    return math.max(1, (booster.price * 0.5).floor());
  }

  // _sellableItems removed — inventory uses _inventory Booster list now

  Color _boosterAccent(Booster booster) {
    final rarity = _rarityOf(booster);
    switch (rarity) {
      case 'mythic':
        return Color(0xFFF472B6);
      case 'legendary':
        return Color(0xFFFBBF24);
      case 'epic':
        return Color(0xFFC084FC);
      case 'rare':
        return Color(0xFF60A5FA);
      default:
        return Color(0xFF94A3B8);
    }
  }

  String _rarityLabel(String rarity) {
    if (rarity == 'mythic') return 'Mythisch';
    return _td(rarity);
  }

  Widget _inventoryQuantityBadge(int quantity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFF2A1230).withOpacity(0.94),
        border: Border.all(color: const Color(0xFFF9A8D4).withOpacity(0.38)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC4899).withOpacity(0.24),
            blurRadius: 12,
          ),
        ],
      ),
      child: Text(
        'x$quantity',
        maxLines: 1,
        style: const TextStyle(
          color: Color(0xFFF9A8D4),
          fontWeight: FontWeight.w900,
          fontSize: 10.5,
          height: 1,
        ),
      ),
    );
  }

  Widget _inventoryBoostText({required String label, required Color color}) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontSize: 13,
        height: 1.08,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Future<void> _requestSellBooster(Booster booster) async {
    setState(() {
      _pendingSellBooster = booster;
    });
  }

  Future<void> _confirmSellBooster() async {
    final booster = _pendingSellBooster;
    if (booster == null || _sellingItem) return;
    setState(() => _sellingItem = true);
    try {
      final result = await ApiService.sellItem(booster.id!);
      final sellPrice = _toInt(_map(result)['sellPrice']) > 0
          ? _toInt(_map(result)['sellPrice'])
          : _sellPriceForBooster(booster);
      if (!mounted) return;
      setState(() {
        _pendingSellBooster = null;
        _sellingItem = false;
      });
      widget.showSnack(
        _lt(
          de: '${_td(booster.name)} verkauft. +$sellPrice Coins',
          en: '${_td(booster.name)} sold. +$sellPrice Coins',
        ),
      );
      await _load();
      await widget.onRefreshHeader();
    } catch (_) {
      if (!mounted) return;
      setState(() => _sellingItem = false);
      widget.showSnack(
        _lt(
          de: 'Booster konnte nicht verkauft werden.',
          en: 'Booster could not be sold.',
        ),
      );
    }
  }

  int _availableQuantityForSlot(int slotIndex, Booster booster) {
    final equippedElsewhere = _slots
        .asMap()
        .entries
        .where(
          (entry) => entry.key != slotIndex && entry.value?.id == booster.id,
        )
        .length;
    return booster.quantity - equippedElsewhere;
  }

  int get _totalXpBoost =>
      _slots.fold<int>(0, (sum, slot) => sum + (slot?.xpBoostPercentage ?? 0));

  int get _totalCoinBoost => _slots.fold<int>(
    0,
    (sum, slot) => sum + (slot?.coinBoostPercentage ?? 0),
  );

  Future<void> _persistSlots(List<Booster?> oldSlots) async {
    final ids = _slots.map((Booster? b) => b?.id).toList(growable: false);
    try {
      await ApiService.updateBoostSlots(ids);
      await widget.onRefreshHeader();
      widget.showSnack(
        _lt(de: 'Booster-Slots gespeichert.', en: 'Booster slots saved.'),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        for (int i = 0; i < 4; i++) {
          _slots[i] = oldSlots[i];
        }
      });
      widget.showSnack(
        _lt(
          de: 'Booster-Slots konnten nicht gespeichert werden.',
          en: 'Booster slots could not be saved.',
        ),
      );
    }
  }

  Future<void> _handleSlotTap(int index) async {
    if (index < 0 || index >= _slots.length) return;

    await _openBoosterModal(index);
  }

  Future<void> _openBoosterModal(int slotIndex) async {
    if (_inventory.isEmpty) {
      widget.showSnack(
        _lt(
          de: 'Keine Booster vorhanden. Kaufe Booster im Shop.',
          en: 'No boosters available. Buy boosters in the shop.',
        ),
      );
      return;
    }

    final previous = List<Booster?>.from(_slots);
    final current = _slots[slotIndex];

    final selected = await showModalBottomSheet<_BoosterSelection?>(
      context: context,
      backgroundColor: Color(0xFF0B1220),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (BuildContext modalContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _lt(de: 'Booster auswählen', en: 'Choose booster'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Text(
                      'Slot ${slotIndex + 1}',
                      style: const TextStyle(
                        color: Color(0xFFC084FC),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  current == null
                      ? _lt(
                          de: 'Wähle einen Booster aus deinem Inventar.',
                          en: 'Choose a booster from your inventory.',
                        )
                      : _lt(
                          de: 'Aktuell ausgerüstet: ${_td(current.name)}',
                          en: 'Currently equipped: ${_td(current.name)}',
                        ),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.68),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 420),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _inventory.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final canClear = current != null;
                        return InkWell(
                          onTap: canClear
                              ? () => Navigator.pop(
                                  modalContext,
                                  const _BoosterSelection.clear(),
                                )
                              : null,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: canClear
                                  ? Colors.white.withOpacity(0.04)
                                  : Colors.white.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: canClear
                                    ? Colors.white.withOpacity(0.08)
                                    : Colors.white.withOpacity(0.05),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.white.withOpacity(0.05),
                                  ),
                                  child: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.white54,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _lt(de: 'Slot leeren', en: 'Clear slot'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final booster = _inventory[index - 1];
                      final rarity = _rarityOf(booster);
                      final accent = _boosterAccent(booster);
                      final available = _availableQuantityForSlot(
                        slotIndex,
                        booster,
                      );
                      final isCurrent = current?.id == booster.id;

                      return InkWell(
                        onTap: available > 0 || isCurrent
                            ? () => Navigator.pop(
                                modalContext,
                                _BoosterSelection.booster(booster),
                              )
                            : null,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: available > 0 || isCurrent
                                ? accent.withOpacity(0.12)
                                : Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: available > 0 || isCurrent
                                  ? accent.withOpacity(0.3)
                                  : Colors.white.withOpacity(0.06),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 50,
                                height: 50,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: accent.withOpacity(0.12),
                                      ),
                                      child: booster.imageUrl.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: _buildMediaImageFromUrl(
                                                booster.imageUrl,
                                                width: 34,
                                                height: 34,
                                                fit: BoxFit.contain,
                                                fallback: () => Text(
                                                  _boosterIcon(booster),
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Text(
                                              _boosterIcon(booster),
                                              style: const TextStyle(
                                                fontSize: 20,
                                              ),
                                            ),
                                    ),
                                    Positioned(
                                      top: -4,
                                      right: 0,
                                      child: _inventoryQuantityBadge(
                                        booster.quantity,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _td(booster.name),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _rarityLabel(rarity).toUpperCase(),
                                      style: TextStyle(
                                        color: accent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    if (booster.xpBoostPercentage > 0)
                                      _inventoryBoostText(
                                        label:
                                            'XP +${booster.xpBoostPercentage}%',
                                        color: const Color(0xFF60A5FA),
                                      ),
                                    if (booster.coinBoostPercentage > 0)
                                      _inventoryBoostText(
                                        label:
                                            'Coins +${booster.coinBoostPercentage}%',
                                        color: const Color(0xFFFACC15),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                isCurrent
                                    ? _lt(de: 'Aktiv', en: 'Active')
                                    : '$available/${booster.quantity}',
                                style: TextStyle(
                                  color: available > 0 || isCurrent
                                      ? Color(0xFFC084FC)
                                      : Color(0xFFFCA5A5),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) return;

    setState(() {
      _slots[slotIndex] = selected.clear ? null : selected.booster;
      _selectingSlotFor = null;
    });
    await _persistSlots(previous);
  }

  Widget _buildBoostCard({
    required IconData icon,
    required String label,
    required int value,
    required List<Color> barGradient,
    required Color iconColor,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 165;
        final iconBoxSize = compact ? 28.0 : 32.0;
        final horizontalPadding = compact ? 9.0 : 12.0;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: Colors.white.withOpacity(0.09)),
          ),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            compact ? 10 : 12,
            horizontalPadding,
            10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: iconBoxSize,
                    height: iconBoxSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: iconColor.withOpacity(0.14),
                      border: Border.all(color: iconColor.withOpacity(0.35)),
                    ),
                    child: label == 'XP Boost'
                        ? Padding(
                            padding: EdgeInsets.all(compact ? 6 : 7),
                            child: Image.asset(
                              'assets/XP_Pixel.png',
                              fit: BoxFit.contain,
                            ),
                          )
                        : label == 'Coin Boost'
                        ? Padding(
                            padding: EdgeInsets.all(compact ? 5 : 6),
                            child: Image.asset(
                              'assets/SYBAU_Coin.png',
                              fit: BoxFit.contain,
                            ),
                          )
                        : Icon(icon, color: iconColor, size: compact ? 15 : 17),
                  ),
                  SizedBox(width: compact ? 6 : 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            label,
                            maxLines: 1,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '+$value%',
                            maxLines: 1,
                            style: TextStyle(
                              color: value > 0
                                  ? Color(0xFF34D399)
                                  : Colors.white.withOpacity(0.32),
                              fontSize: compact ? 17 : 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 4,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(color: Colors.white.withOpacity(0.06)),
                      FractionallySizedBox(
                        widthFactor: (value / 100).clamp(0.0, 1.0),
                        alignment: Alignment.centerLeft,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: barGradient),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEquipSlot(int index, {double size = 82}) {
    final item = _slots[index];
    final isFilled = item != null;
    final iconSize = size * 0.50;
    final valueSize = size * 0.14;

    return GestureDetector(
      onTap: () => _handleSlotTap(index),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isFilled
              ? Color(0xFFA855F7).withOpacity(0.14)
              : Color(0xFF0F172A).withOpacity(0.52),
          border: Border.all(
            color: isFilled
                ? Color(0xFFA855F7).withOpacity(0.45)
                : Color(0xFFA855F7).withOpacity(0.28),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: isFilled
              ? SizedBox(
                  width: size,
                  height: size,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.translate(
                        offset: Offset(0, -size * 0.07),
                        child: item.imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: _buildMediaImageFromUrl(
                                  item.imageUrl,
                                  width: iconSize,
                                  height: iconSize,
                                  fit: BoxFit.contain,
                                  fallback: () => Text(
                                    _boosterIcon(item),
                                    style: TextStyle(fontSize: iconSize),
                                  ),
                                ),
                              )
                            : Text(
                                _boosterIcon(item),
                                style: TextStyle(fontSize: iconSize),
                              ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: size * 0.12,
                        child: Center(
                          child: _buildBoosterPercentBadges(
                            item,
                            fontSize: math.max(8.0, valueSize * 0.78),
                            horizontalPadding: size < 70 ? 2 : 3,
                            verticalPadding: 0,
                            gap: size < 70 ? 4 : 5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Text(
                  'Leer',
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: valueSize,
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

    final avatar = _map(_profile['avatar']);
    final userName = _string(
      _profile['userName'],
      fallback: _string(_profile['UserName'], fallback: 'Champion'),
    );
    final bodyStage = _normalizeBodyStage(
      _string(avatar['bodyStage'], fallback: 'Skinny'),
    );

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            await _load();
            await widget.onRefreshHeader();
          },
          child: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildBoostCard(
                      icon: Icons.trending_up,
                      label: _lt(de: 'XP Boost', en: 'XP Boost'),
                      value: _totalXpBoost,
                      barGradient: const [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                      iconColor: Color(0xFF60A5FA),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildBoostCard(
                      icon: Icons.monetization_on,
                      label: _lt(de: 'Coin Boost', en: 'Coin Boost'),
                      value: _totalCoinBoost,
                      barGradient: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                      iconColor: Color(0xFFFBBF24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: _lt(de: 'Avatar & Ausrüstung', en: 'Avatar & Equipment'),
                child: Column(
                  children: [
                    Text(
                      userName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.76),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3.2,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const leftRightSlots = 2;
                        const gap = 10.0;
                        final availableWidth = constraints.maxWidth;
                        final isSmall = availableWidth < 410;
                        final isTablet = availableWidth >= 720;

                        final targetAvatarWidth = isTablet
                            ? 294.0
                            : (isSmall ? 176.0 : 242.0);
                        final targetAvatarHeight = isTablet
                            ? 322.0
                            : (isSmall ? 220.0 : 278.0);
                        final targetSlotSize = isTablet ? 104.0 : 90.0;
                        final targetSideWidth = targetSlotSize;
                        final targetSpacing = gap;
                        final targetTotalWidth =
                            targetSideWidth * leftRightSlots +
                            targetAvatarWidth +
                            targetSpacing * 2;
                        final scale = targetTotalWidth > availableWidth
                            ? availableWidth / targetTotalWidth
                            : 1.0;

                        final slotSize = (targetSlotSize * scale).clamp(
                          66.0,
                          targetSlotSize,
                        );
                        final avatarWidth = (targetAvatarWidth * scale).clamp(
                          160.0,
                          targetAvatarWidth,
                        );
                        final avatarHeight = (targetAvatarHeight * scale).clamp(
                          196.0,
                          targetAvatarHeight,
                        );
                        final horizontalGap = (targetSpacing * scale).clamp(
                          6.0,
                          10.0,
                        );
                        final baseScale = isTablet
                            ? 3.72
                            : (isSmall ? 2.52 : 3.34);

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: slotSize,
                              child: Column(
                                children: [
                                  _buildEquipSlot(0, size: slotSize),
                                  SizedBox(height: horizontalGap),
                                  _buildEquipSlot(1, size: slotSize),
                                ],
                              ),
                            ),
                            SizedBox(width: horizontalGap),
                            SizedBox(
                              width: avatarWidth,
                              height: avatarHeight + (isTablet ? 54 : 48),
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: avatarWidth,
                                    height: avatarHeight + (isTablet ? 26 : 20),
                                    child: OverflowBox(
                                      alignment: Alignment(
                                        0,
                                        isTablet ? -0.34 : -0.4,
                                      ),
                                      minWidth: 0,
                                      minHeight: 0,
                                      maxWidth: double.infinity,
                                      maxHeight: double.infinity,
                                      child: _SpriteAnimator(
                                        stage: bodyStage,
                                        frameWidth: 128,
                                        frameHeight: 128,
                                        columns: 2,
                                        frameCount: 4,
                                        speed: const Duration(
                                          milliseconds: 1000,
                                        ),
                                        scale: baseScale * scale,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: isTablet ? 6 : 4),
                                  Container(
                                    width: avatarWidth * 0.62,
                                    height: isTablet ? 16 : 14,
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
                            ),
                            SizedBox(width: horizontalGap),
                            SizedBox(
                              width: slotSize,
                              child: Column(
                                children: [
                                  _buildEquipSlot(2, size: slotSize),
                                  SizedBox(height: horizontalGap),
                                  _buildEquipSlot(3, size: slotSize),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    if (_selectingSlotFor != null)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Color(0xFFA855F7).withOpacity(0.16),
                          border: Border.all(
                            color: Color(0xFFA855F7).withOpacity(0.38),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.bolt,
                              size: 15,
                              color: Color(0xFFC084FC),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _lt(
                                  de: 'Wähle einen Slot für ${_selectingSlotFor!.name}',
                                  en: 'Choose a slot for ${_selectingSlotFor!.name}',
                                ),
                                style: const TextStyle(
                                  color: Color(0xFFE9D5FF),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() => _selectingSlotFor = null);
                              },
                              child: Text(
                                _lt(de: 'Abbrechen', en: 'Cancel'),
                                style: const TextStyle(
                                  color: Color(0xFFFCA5A5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _SectionCard(
                title: _lt(de: 'Inventar', en: 'Inventory'),
                child: Column(
                  children: _inventory.isEmpty
                      ? [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                              _lt(
                                de: 'Keine Booster vorhanden. Kaufe Booster im Shop.',
                                en: 'No boosters available. Buy boosters in the shop.',
                              ),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.68),
                              ),
                            ),
                          ),
                        ]
                      : _inventory
                            .map((booster) {
                              final accent = _boosterAccent(booster);
                              final rarity = _rarityOf(booster);

                              return SizedBox(
                                height: 118,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        accent.withOpacity(0.08),
                                        Colors.white.withOpacity(0.035),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: accent.withOpacity(0.22),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 64,
                                        height: 64,
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Container(
                                              width: 58,
                                              height: 58,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    accent.withOpacity(0.2),
                                                    accent.withOpacity(0.06),
                                                  ],
                                                ),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withOpacity(0.06),
                                                ),
                                              ),
                                              child: Center(
                                                child:
                                                    booster.imageUrl.isNotEmpty
                                                    ? ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        child: _buildMediaImageFromUrl(
                                                          booster.imageUrl,
                                                          width: 44,
                                                          height: 44,
                                                          fit: BoxFit.contain,
                                                          fallback: () => Text(
                                                            _boosterIcon(
                                                              booster,
                                                            ),
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 21,
                                                                ),
                                                          ),
                                                        ),
                                                      )
                                                    : Text(
                                                        _boosterIcon(booster),
                                                        style: const TextStyle(
                                                          fontSize: 21,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                            Positioned(
                                              top: -4,
                                              right: 0,
                                              child: _inventoryQuantityBadge(
                                                booster.quantity,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _td(booster.name),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 18,
                                                height: 1.05,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _rarityLabel(
                                                rarity,
                                              ).toUpperCase(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: accent,
                                                fontSize: 10,
                                                height: 1,
                                                letterSpacing: 1.35,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            SizedBox(
                                              height: 32,
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  if (booster
                                                          .xpBoostPercentage >
                                                      0)
                                                    _inventoryBoostText(
                                                      label:
                                                          'XP +${booster.xpBoostPercentage}%',
                                                      color: const Color(
                                                        0xFF60A5FA,
                                                      ),
                                                    ),
                                                  if (booster
                                                          .coinBoostPercentage >
                                                      0)
                                                    _inventoryBoostText(
                                                      label:
                                                          'Coins +${booster.coinBoostPercentage}%',
                                                      color: const Color(
                                                        0xFFFACC15,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () =>
                                            _requestSellBooster(booster),
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            color: Color(
                                              0xFFF43F5E,
                                            ).withOpacity(0.12),
                                            border: Border.all(
                                              color: Color(
                                                0xFFF43F5E,
                                              ).withOpacity(0.22),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.sell_rounded,
                                            color: Color(0xFFF43F5E),
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            })
                            .toList(growable: false),
                ),
              ),
            ],
          ),
        ),
        if (_pendingSellBooster != null) _buildSellConfirmDialog(),
      ],
    );
  }

  Widget _buildSellConfirmDialog() {
    if (_pendingSellBooster == null) return const SizedBox.shrink();
    final booster = _pendingSellBooster!;
    final sellPrice = _sellPriceForBooster(booster);
    return GestureDetector(
      onTap: _sellingItem
          ? null
          : () => setState(() => _pendingSellBooster = null),
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Color(0xFF0F172A).withOpacity(0.96),
              border: Border.all(color: Color(0xFFEF4444).withOpacity(0.28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.42),
                  blurRadius: 60,
                  offset: const Offset(0, 26),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _lt(de: 'Verkaufen?', en: 'Sell?'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _lt(
                    de: '${_td(booster.name)} verkaufen',
                    en: 'Sell ${_td(booster.name)}',
                  ),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.68),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: 72,
                  height: 72,
                  child: Center(
                    child: booster.imageUrl.isNotEmpty
                        ? _buildMediaImageFromUrl(
                            booster.imageUrl,
                            width: 58,
                            height: 58,
                            fit: BoxFit.contain,
                            fallback: () => const Icon(
                              Icons.inventory_2_rounded,
                              color: Colors.white38,
                              size: 34,
                            ),
                          )
                        : const Icon(
                            Icons.inventory_2_rounded,
                            color: Colors.white38,
                            size: 34,
                          ),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Color(0xFF020617).withOpacity(0.48),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _lt(de: 'Erhalt', en: 'You get'),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.58),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Row(
                        children: [
                          Image.asset(
                            'assets/SYBAU_Coin.png',
                            width: 20,
                            height: 20,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            '+${_formatCompactNumber(sellPrice)}',
                            style: const TextStyle(
                              color: Color(0xFFFACC15),
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _lt(
                    de: '50% des Kaufpreises',
                    en: '50% of the purchase price',
                  ),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.42),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _sellingItem
                            ? null
                            : () => setState(() => _pendingSellBooster = null),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1E293B).withOpacity(0.76),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                          minimumSize: const Size.fromHeight(44),
                        ),
                        child: Text(
                          _lt(de: 'Abbrechen', en: 'Cancel'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: !_sellingItem ? _confirmSellBooster : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: Color(0xFFEF4444).withOpacity(0.42),
                            ),
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFF87171).withOpacity(0.34),
                                Color(0xFFDC2626).withOpacity(0.92),
                              ],
                            ),
                          ),
                          child: SizedBox(
                            height: 44,
                            child: Center(
                              child: _sellingItem
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _lt(de: 'Verkaufen', en: 'Sell'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
