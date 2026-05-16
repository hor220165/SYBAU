part of '../app_shell_screen.dart';

class ShopTab extends StatefulWidget {
  const ShopTab({
    required this.onRefreshHeader,
    required this.showSnack,
    super.key,
  });

  final Future<void> Function() onRefreshHeader;
  final void Function(String) showSnack;

  @override
  State<ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends State<ShopTab> {
  bool _loading = true;
  List<dynamic> _items = <dynamic>[];
  List<dynamic> _chests = <dynamic>[];
  List<dynamic> _ownedItems = <dynamic>[];
  Map<String, dynamic> _profile = <String, dynamic>{};
  int _currentCoins = 0;
  Map<String, dynamic>? _pendingPurchase;
  bool _buying = false;
  Map<String, dynamic>? _openingChestPreview;
  Map<String, dynamic>? _openedReward;
  bool _openingChest = false;
  int? _openingChestId;
  bool _chestRevealStarted = false;
  bool _openHintPulseBright = true;
  DateTime? _dailyShopExpiresAtUtc;
  Duration _dailyShopServerOffset = Duration.zero;
  Timer? _dailyShopTimer;
  String _dailyCountdown = '00:00:00';
  final List<Map<String, String>> _coinPacks = const [
    {
      'name': 'Starter Pack',
      'coins': '750',
      'price': '1,99 €',
      'image': 'assets/Starter_Pack.png',
    },
    {
      'name': 'Plus Pack',
      'coins': '2.250',
      'price': '4,99 €',
      'image': 'assets/Plus_Pack.png',
    },
    {
      'name': 'Pro Pack',
      'coins': '5.000',
      'price': '9,99 €',
      'image': 'assets/Pro_Pack.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _dailyShopTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tickDailyCountdown(),
    );
    unawaited(_load());
  }

  @override
  void dispose() {
    _dailyShopTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profile = await ApiService.getProfile();
      final results = await Future.wait<dynamic>([
        ApiService.getDailyShop().catchError((error) {
          debugPrint('Daily shop load error: $error');
          return <String, dynamic>{};
        }),
        ApiService.getChests().catchError((error) {
          debugPrint('Chest load error: $error');
          return <dynamic>[];
        }),
        ApiService.getUserItems().catchError((error) {
          debugPrint('Owned items load error: $error');
          return <dynamic>[];
        }),
      ]);
      if (!mounted) return;
      final dailyShop = _map(results[0]);
      final serverTime = _parseUtc(
        dailyShop['serverTimeUtc'] ?? dailyShop['ServerTimeUtc'],
      );
      final expiresAt = _parseUtc(
        dailyShop['expiresAtUtc'] ?? dailyShop['ExpiresAtUtc'],
      );
      setState(() {
        _profile = _map(profile);
        _currentCoins = _toInt(_profile['coins']);
        _items =
            (dailyShop['items'] ?? dailyShop['Items'] ?? <dynamic>[])
                as List<dynamic>;
        _chests = results[1] as List<dynamic>;
        _ownedItems = results[2] as List<dynamic>;
        _dailyShopExpiresAtUtc = expiresAt;
        _dailyShopServerOffset = serverTime == null
            ? Duration.zero
            : serverTime.difference(DateTime.now().toUtc());
        _dailyCountdown = _formatCountdown(_remainingDailyShopTime());
        _loading = false;
      });
    } catch (e) {
      debugPrint('Shop load error: $e');
      if (!mounted) return;
      setState(() => _loading = false);
      widget.showSnack(
        _lt(
          de: 'Shop konnte nicht geladen werden.',
          en: 'Shop could not be loaded.',
        ),
      );
    }
  }

  DateTime? _parseUtc(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toUtc();
  }

  Duration _remainingDailyShopTime() {
    final expiresAt = _dailyShopExpiresAtUtc;
    if (expiresAt == null) return Duration.zero;
    final serverNow = DateTime.now().toUtc().add(_dailyShopServerOffset);
    final remaining = expiresAt.difference(serverNow);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String _formatCountdown(Duration duration) {
    final totalSeconds = duration.inSeconds.clamp(0, 24 * 60 * 60);
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return [
      hours,
      minutes,
      seconds,
    ].map((value) => value.toString().padLeft(2, '0')).join(':');
  }

  void _tickDailyCountdown() {
    if (!mounted || _dailyShopExpiresAtUtc == null) return;
    final remaining = _remainingDailyShopTime();
    setState(() => _dailyCountdown = _formatCountdown(remaining));
    if (remaining == Duration.zero && !_loading) {
      _dailyShopExpiresAtUtc = null;
      unawaited(_load());
    }
  }

  int _ownedQuantityFor(int itemId) {
    for (final raw in _ownedItems) {
      final m = _map(raw);
      if (_toInt(m['id']) == itemId || _toInt(m['itemId']) == itemId) {
        return _toInt(m['quantity'], fallback: 1);
      }
    }
    return 0;
  }

  void _requestPurchase(Map<String, dynamic> item, {bool isChest = false}) {
    setState(() {
      _pendingPurchase = {...item, 'isChest': isChest};
    });
  }

  void _cancelPurchase() {
    setState(() => _pendingPurchase = null);
  }

  Future<void> _confirmPurchase() async {
    if (_pendingPurchase == null || _buying) return;
    final purchase = _pendingPurchase!;
    final isChest = purchase['isChest'] == true;
    final id = _toInt(purchase['id']);

    if (isChest) {
      setState(() {
        _pendingPurchase = null;
        _buying = false;
        _openingChestPreview = Map<String, dynamic>.from(purchase);
        _openingChest = false;
        _openingChestId = null;
        _openedReward = null;
        _chestRevealStarted = false;
        _openHintPulseBright = true;
      });
      return;
    }

    setState(() => _buying = true);
    try {
      await ApiService.buyItem(id);
      widget.showSnack(
        _lt(
          de: '${_string(purchase['name'])} gekauft!',
          en: '${_string(purchase['name'])} purchased!',
        ),
      );
      setState(() {
        _pendingPurchase = null;
        _buying = false;
      });
      await widget.onRefreshHeader();
      await _load();
    } catch (e) {
      debugPrint('Purchase error: $e');
      setState(() {
        _pendingPurchase = null;
        _buying = false;
      });
      widget.showSnack(_lt(de: 'Kauf fehlgeschlagen.', en: 'Purchase failed.'));
    }
  }

  // ---------- Chest flow ----------

  Future<void> _openChest(int chestId) async {
    if (_openingChest || _chestRevealStarted) return;
    setState(() {
      _openingChest = true;
      _openingChestId = chestId;
      _openedReward = null;
      _chestRevealStarted = true;
    });
    try {
      final result = await ApiService.openChest(chestId);
      if (!mounted) return;
      setState(() {
        _openedReward = _map(result);
        _openingChest = false;
      });
      await widget.onRefreshHeader();
    } catch (e) {
      debugPrint('Chest open error: $e');
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      String errorMsg = _lt(
        de: 'Chest konnte nicht geöffnet werden.',
        en: 'Chest could not be opened.',
      );
      if (e is ApiException && e.statusCode == 400) {
        try {
          final body = jsonDecode(e.body ?? '');
          if (body is String) {
            errorMsg = body;
          } else if (body is Map) {
            errorMsg =
                body['error'] ?? body['message'] ?? body['title'] ?? errorMsg;
          }
        } catch (_) {}
      }
      setState(() {
        _openingChest = false;
        _openingChestId = null;
        _openingChestPreview = null;
        _chestRevealStarted = false;
      });
      widget.showSnack(errorMsg);
    }
  }

  void _closeChestReward() {
    setState(() {
      _openedReward = null;
      _openingChestId = null;
      _openingChestPreview = null;
      _openingChest = false;
      _chestRevealStarted = false;
    });
    unawaited(_load());
  }

  // ---------- Classification helpers ----------

  String _shopCategory(Map<String, dynamic> item) {
    final type = _string(item['type']).toLowerCase();
    if (type == 'booster') return 'boost';
    final searchBase =
        '${_string(item['name'])} ${_string(item['description'])}'
            .toLowerCase();
    if (searchBase.contains('chest') ||
        searchBase.contains('crate') ||
        searchBase.contains('box')) {
      return 'chest';
    }
    if (searchBase.contains('boost') ||
        searchBase.contains('xp') ||
        type.contains('booster')) {
      return 'boost';
    }
    return 'item';
  }

  String _shopRarity(Map<String, dynamic> item) {
    final explicit = _string(item['rarity']).toLowerCase();
    if (explicit == 'common' ||
        explicit == 'rare' ||
        explicit == 'epic' ||
        explicit == 'legendary' ||
        explicit == 'mythic') {
      return explicit;
    }
    final price = _toInt(item['price']);
    if (price >= 1800) return 'mythic';
    if (price >= 1200) return 'legendary';
    if (price >= 700) return 'epic';
    if (price >= 350) return 'rare';
    return 'common';
  }

  Color _rarityAccent(String rarity) {
    switch (rarity) {
      case 'mythic':
        return Color(0xFFF472B6);
      case 'rare':
        return Color(0xFF60A5FA);
      case 'epic':
        return Color(0xFFC084FC);
      case 'legendary':
        return Color(0xFFFBBF24);
      default:
        return Color(0xFF94A3B8);
    }
  }

  String _rarityLabel(String rarity) {
    if (rarity == 'mythic') return 'Mythisch';
    return _td(rarity);
  }

  String _rarityIcon(String rarity, {String category = 'item'}) {
    if (category == 'chest') {
      switch (rarity) {
        case 'mythic':
          return '🌌';
        case 'legendary':
          return '👑';
        case 'epic':
          return '💎';
        case 'rare':
          return '🎁';
        default:
          return '📦';
      }
    }
    if (category == 'boost') {
      switch (rarity) {
        case 'mythic':
          return '🌠';
        case 'legendary':
          return '✨';
        case 'epic':
          return '⚡';
        case 'rare':
          return '🧪';
        default:
          return '💫';
      }
    }
    return '🛡️';
  }

  Map<String, dynamic> _buildDisplayItem(Map<String, dynamic> m) {
    final id = _toInt(m['id']);
    final owned = _ownedQuantityFor(id);
    return <String, dynamic>{
      'id': id,
      'name': _string(m['name'], fallback: 'Item'),
      'description': _string(m['description']),
      'price': _toInt(m['price']),
      'type': _string(m['type']),
      'xpBoostPercentage': _toInt(
        m['xpBoostPercentage'] ?? m['xpBoostPercent'],
      ),
      'coinBoostPercentage': _toInt(
        m['coinBoostPercentage'] ?? m['coinBoostPercent'],
      ),
      'imageUrl': _string(m['imageUrl'] ?? m['ImageUrl']),
      'rarity': _shopRarity(m),
      'category': _shopCategory(m),
      'ownedQuantity': owned,
    };
  }

  List<Map<String, dynamic>> get _displayItems {
    return _items
        .map((item) => _buildDisplayItem(_map(item)))
        .toList(growable: false);
  }

  List<Map<String, dynamic>> get _displayChests {
    return _chests
        .map((chest) {
          final m = _map(chest);
          return <String, dynamic>{
            'id': _toInt(m['id']),
            'name': _string(m['name'], fallback: 'Chest'),
            'price': _toInt(m['price']),
            'imageUrl': _string(m['imageUrl'] ?? m['ImageUrl']),
            'commonChance': _toInt(m['commonChance'] ?? m['CommonChance']),
            'rareChance': _toInt(m['rareChance'] ?? m['RareChance']),
            'epicChance': _toInt(m['epicChance'] ?? m['EpicChance']),
            'legendaryChance': _toInt(
              m['legendaryChance'] ?? m['LegendaryChance'],
            ),
            'mythicChance': _toInt(m['mythicChance'] ?? m['MythicChance']),
            'items': (m['items'] ?? m['Items'] ?? []) as List<dynamic>,
          };
        })
        .toList(growable: false);
  }

  // ---------- Image / placeholder builders ----------

  Widget _buildShopImageFromUrl(
    String? imageUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    required Widget Function() fallback,
  }) {
    return _buildMediaImageFromUrl(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      fallback: fallback,
    );
  }

  Widget _buildItemImage(String? imageUrl, {double size = 86}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: _buildShopImageFromUrl(
        imageUrl,
        width: size,
        height: size,
        fallback: () => _buildEmojiPlaceholder(size),
      ),
    );
  }

  Widget _buildEmojiPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(0.04),
      ),
      child: Center(
        child: Icon(
          Icons.inventory_2_rounded,
          color: Colors.white38,
          size: size * 0.42,
        ),
      ),
    );
  }

  // ---------- Chest card ----------

  Widget _buildChestCard(Map<String, dynamic> chest, {bool compact = false}) {
    final price = _toInt(chest['price']);
    final canAfford = _currentCoins >= price;
    final isOpening = _openingChestId == _toInt(chest['id']);
    final imageUrl = _string(chest['imageUrl']);
    final imageSize = compact ? 80.0 : 112.0;
    final imageHeight = compact ? 88.0 : 112.0;

    return SizedBox(
      height: compact ? 198 : 222,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF080A1F).withOpacity(0.96),
              Color(0xFF15051A).withOpacity(0.9),
            ],
          ),
          border: Border.all(color: Color(0xFFEC4899).withOpacity(0.26)),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFEC4899).withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(compact ? 8 : 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: imageHeight,
                    child: Center(
                      child: imageUrl.isNotEmpty
                          ? Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: compact ? 0 : 4,
                                vertical: 2,
                              ),
                              child: _buildShopImageFromUrl(
                                imageUrl,
                                width: imageSize,
                                height: imageSize,
                                fallback: () => const Text(
                                  '📦',
                                  style: TextStyle(fontSize: 42),
                                ),
                              ),
                            )
                          : const Text('📦', style: TextStyle(fontSize: 42)),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _td(_string(chest['name'])),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 12.5 : 14.5,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: compact ? 36 : 38,
                    child: ElevatedButton(
                      onPressed: canAfford && !isOpening
                          ? () => _requestPurchase(chest, isChest: true)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        disabledBackgroundColor: Colors.white.withOpacity(0.06),
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9),
                          gradient: canAfford
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF22C55E),
                                    Color(0xFF14532D),
                                  ],
                                )
                              : null,
                          color: canAfford
                              ? null
                              : Colors.white.withOpacity(0.06),
                          border: Border.all(
                            color: canAfford
                                ? Color(0xFF4ADE80).withOpacity(0.42)
                                : Color(0xFF94A3B8).withOpacity(0.18),
                          ),
                        ),
                        child: Center(
                          child: isOpening
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      'assets/SYBAU_Coin.png',
                                      width: 16,
                                      height: 16,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.none,
                                      isAntiAlias: false,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      _formatCompactNumber(price),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: compact ? 16 : 18,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: compact ? 4 : 8,
              right: compact ? 4 : 8,
              child: InkWell(
                onTap: () => _showChestRatesDialog(chest),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: compact ? 22 : 26,
                  height: compact ? 22 : 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF0F172A).withOpacity(0.86),
                    border: Border.all(
                      color: Color(0xFFF9A8D4).withOpacity(0.34),
                    ),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Color(0xFFF9A8D4),
                    size: compact ? 13 : 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChestRatesDialog(Map<String, dynamic> chest) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Color(0xFF0F172A).withOpacity(0.98),
            border: Border.all(color: Color(0xFF8B5CF6).withOpacity(0.24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _td(_string(chest['name'])),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRateChip(
                    'Common',
                    _toInt(chest['commonChance']),
                    Color(0xFF94A3B8),
                  ),
                  _buildRateChip(
                    'Rare',
                    _toInt(chest['rareChance']),
                    Color(0xFF60A5FA),
                  ),
                  _buildRateChip(
                    'Epic',
                    _toInt(chest['epicChance']),
                    Color(0xFFC084FC),
                  ),
                  _buildRateChip(
                    'Legendary',
                    _toInt(chest['legendaryChance']),
                    Color(0xFFFBBF24),
                  ),
                  _buildRateChip(
                    'Mythisch',
                    _toInt(chest['mythicChance']),
                    Color(0xFFF472B6),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRateChip(String label, int chance, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text(
        '$label $chance%',
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ---------- Shop item card ----------

  Widget _buildCompactShopItemCard(Map<String, dynamic> item) {
    final rarity = _string(item['rarity']);
    final accent = _rarityAccent(rarity);
    final price = _toInt(item['price']);
    final owned = _toInt(item['ownedQuantity']);
    final canBuy = _currentCoins >= price;
    final imageUrl = _string(item['imageUrl']);
    final category = _string(item['category']);
    final icon = _rarityIcon(rarity, category: category);
    final xpBoost = _toInt(item['xpBoostPercentage']);
    final coinBoost = _toInt(item['coinBoostPercentage']);
    final boostValues = <Widget>[
      if (xpBoost > 0)
        _buildBoostValue(
          label: '+$xpBoost% XP',
          textColor: const Color(0xFF60A5FA),
        ),
      if (coinBoost > 0)
        _buildBoostValue(
          label: '+$coinBoost% Coins',
          textColor: const Color(0xFFFACC15),
        ),
    ];

    return SizedBox(
      height: 274,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 18, 8, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF080A1F).withOpacity(0.96),
              Color(0xFF15051A).withOpacity(0.9),
            ],
          ),
          border: Border.all(color: accent.withOpacity(0.26)),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 96,
                  child: Center(
                    child: SizedBox(
                      width: 110,
                      height: 96,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          imageUrl.isNotEmpty
                              ? _buildShopImageFromUrl(
                                  imageUrl,
                                  width: 92,
                                  height: 92,
                                  fallback: () => Text(
                                    icon,
                                    style: const TextStyle(fontSize: 42),
                                  ),
                                )
                              : Text(
                                  icon,
                                  style: const TextStyle(fontSize: 42),
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                SizedBox(
                  height: 34,
                  child: Center(
                    child: Text(
                      _td(_string(item['name'])),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _rarityLabel(rarity).toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: accent,
                    fontSize: 9.5,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 38,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        for (var index = 0; index < boostValues.length; index++)
                          Padding(
                            padding: EdgeInsets.only(top: index == 0 ? 0 : 3),
                            child: Center(child: boostValues[index]),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SizedBox(
                width: double.infinity,
                height: 38,
                child: ElevatedButton(
                  onPressed: canBuy ? () => _requestPurchase(item) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    disabledBackgroundColor: Colors.white.withOpacity(0.06),
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      gradient: canBuy
                          ? const LinearGradient(
                              colors: [Color(0xFF22C55E), Color(0xFF14532D)],
                            )
                          : null,
                      color: canBuy ? null : Colors.white.withOpacity(0.06),
                      border: Border.all(
                        color: canBuy
                            ? Color(0xFF4ADE80).withOpacity(0.42)
                            : Color(0xFF94A3B8).withOpacity(0.18),
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/SYBAU_Coin.png',
                            width: 16,
                            height: 16,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.none,
                            isAntiAlias: false,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              _formatCompactNumber(price),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: canBuy ? Colors.white : Colors.white54,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (owned > 0)
              Positioned(
                top: -14,
                right: -12,
                child: _buildQuantityBadge('x$owned'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFF2A1230).withOpacity(0.92),
        border: Border.all(color: const Color(0xFFF9A8D4).withOpacity(0.38)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC4899).withOpacity(0.28),
            blurRadius: 12,
          ),
        ],
      ),
      child: Text(
        label,
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

  Widget _buildBoostValue({required String label, required Color textColor}) {
    return Text(
      label,
      textAlign: TextAlign.center,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.clip,
      style: TextStyle(
        color: textColor,
        fontWeight: FontWeight.w900,
        fontSize: 10.5,
        height: 1,
      ),
    );
  }

  Widget _buildShopItemCard(Map<String, dynamic> item) {
    final rarity = _string(item['rarity']);
    final accent = _rarityAccent(rarity);
    final price = _toInt(item['price']);
    final owned = _toInt(item['ownedQuantity']);
    final canBuy = _currentCoins >= price;
    final imageUrl = _string(item['imageUrl']);
    final category = _string(item['category']);
    final icon = _rarityIcon(rarity, category: category);
    final xpBoost = _toInt(item['xpBoostPercentage']);
    final coinBoost = _toInt(item['coinBoostPercentage']);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Color(0xFF080A1F).withOpacity(0.78),
        border: Border.all(color: accent.withOpacity(0.18)),
      ),
      padding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Color(0xFF020617).withOpacity(0.26),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Center(
                      child: imageUrl.isNotEmpty
                          ? _buildShopImageFromUrl(
                              imageUrl,
                              width: 74,
                              height: 74,
                              fallback: () => Text(
                                icon,
                                style: const TextStyle(fontSize: 40),
                              ),
                            )
                          : Text(icon, style: const TextStyle(fontSize: 40)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 4,
                        right: owned > 0 ? 48 : 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _td(_string(item['name'])),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (xpBoost > 0 || coinBoost > 0) ...[
                            const SizedBox(height: 11),
                            if (xpBoost > 0 && coinBoost > 0)
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildBoostPill(
                                      iconAsset: 'assets/XP_Pixel.png',
                                      label: '+$xpBoost% XP',
                                      textColor: Color(0xFF60A5FA),
                                      borderColor: Color(0xFF3B82F6),
                                      backgroundColor: Color(0xFF2563EB),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: _buildBoostPill(
                                      iconAsset: 'assets/SYBAU_Coin.png',
                                      label: '+$coinBoost% Coins',
                                      textColor: Color(0xFFFACC15),
                                      borderColor: Color(0xFFF59E0B),
                                      backgroundColor: Color(0xFFF59E0B),
                                    ),
                                  ),
                                ],
                              )
                            else if (xpBoost > 0)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: _buildBoostPill(
                                  iconAsset: 'assets/XP_Pixel.png',
                                  label: '+$xpBoost% XP',
                                  textColor: Color(0xFF60A5FA),
                                  borderColor: Color(0xFF3B82F6),
                                  backgroundColor: Color(0xFF2563EB),
                                  compact: true,
                                ),
                              )
                            else if (coinBoost > 0)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: _buildBoostPill(
                                  iconAsset: 'assets/SYBAU_Coin.png',
                                  label: '+$coinBoost% Coins',
                                  textColor: Color(0xFFFACC15),
                                  borderColor: Color(0xFFF59E0B),
                                  backgroundColor: Color(0xFFF59E0B),
                                  compact: true,
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton(
                  onPressed: canBuy ? () => _requestPurchase(item) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    disabledBackgroundColor: Colors.white.withOpacity(0.06),
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      gradient: canBuy
                          ? const LinearGradient(
                              colors: [Color(0xFF22C55E), Color(0xFF14532D)],
                            )
                          : null,
                      color: canBuy ? null : Colors.white.withOpacity(0.06),
                      border: Border.all(
                        color: canBuy
                            ? Color(0xFF4ADE80).withOpacity(0.42)
                            : Color(0xFF94A3B8).withOpacity(0.18),
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/SYBAU_Coin.png',
                            width: 19,
                            height: 19,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.none,
                            isAntiAlias: false,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _formatCompactNumber(price),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: canBuy ? Colors.white : Colors.white54,
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (owned > 0)
            Positioned(
              top: 0,
              right: 0,
              child: Text(
                'x$owned',
                style: const TextStyle(
                  color: Color(0xFFF9A8D4),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  shadows: [Shadow(color: Color(0xFFEC4899), blurRadius: 12)],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBoostPill({
    required String iconAsset,
    required String label,
    required Color textColor,
    required Color borderColor,
    required Color backgroundColor,
    bool compact = false,
  }) {
    return Container(
      width: compact ? null : double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        color: backgroundColor.withOpacity(0.16),
        border: Border.all(color: borderColor.withOpacity(0.38)),
      ),
      child: Row(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Image.asset(
            iconAsset,
            width: 15,
            height: 15,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
            isAntiAlias: false,
          ),
          const SizedBox(width: 5),
          if (compact)
            Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            )
          else
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCoinPackCard(Map<String, String> pack) {
    return SizedBox(
      height: 220,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 9, 8, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF080A1F).withOpacity(0.96),
              Color(0xFF18071D).withOpacity(0.9),
            ],
          ),
          border: Border.all(color: Color(0xFFEC4899).withOpacity(0.24)),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFEC4899).withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 76,
              child: Image.asset(
                pack['image']!,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
                isAntiAlias: false,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              pack['name']!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 1.05,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/SYBAU_Coin.png',
                    width: 17,
                    height: 17,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none,
                    isAntiAlias: false,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    pack['coins']!,
                    style: const TextStyle(
                      color: Color(0xFFFACC15),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              height: 36,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22C55E), Color(0xFF14532D)],
                  ),
                  border: Border.all(
                    color: Color(0xFF4ADE80).withOpacity(0.42),
                  ),
                ),
                child: Center(
                  child: Text(
                    pack['price']!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Buy / Open confirm dialog ----------

  Widget _buildConfirmDialog() {
    if (_pendingPurchase == null) return const SizedBox.shrink();
    final isChest = _pendingPurchase!['isChest'] == true;
    final name = _td(_string(_pendingPurchase!['name']));
    final price = _toInt(_pendingPurchase!['price']);
    final canAfford = _currentCoins >= price;

    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Color(0xFF0F172A).withOpacity(0.96),
            border: Border.all(color: Color(0xFFEC4899).withOpacity(0.28)),
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
                isChest
                    ? _lt(de: 'Chest öffnen?', en: 'Open chest?')
                    : _lt(de: 'Kaufen?', en: 'Buy?'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isChest
                    ? _lt(de: '$name öffnen', en: 'Open $name')
                    : _lt(de: '$name kaufen', en: 'Buy $name'),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.68),
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 18),
              // Price row
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
                      _lt(de: 'Kosten', en: 'Cost'),
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
                          _formatCompactNumber(price),
                          style: const TextStyle(
                            color: Color(0xFFF8FAFC),
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!canAfford)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _lt(de: 'Nicht genug Coins!', en: 'Not enough coins!'),
                    style: TextStyle(
                      color: Colors.red.shade300,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _cancelPurchase,
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
                      onPressed: canAfford && !_buying
                          ? _confirmPurchase
                          : null,
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
                            color: Color(0xFF4ADE80).withOpacity(0.42),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF22C55E).withOpacity(0.24),
                              Color(0xFF14532D).withOpacity(0.86),
                            ],
                          ),
                        ),
                        child: SizedBox(
                          height: 44,
                          child: Center(
                            child: _buying
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    isChest
                                        ? _lt(de: 'Öffnen', en: 'Open')
                                        : _lt(de: 'Kaufen', en: 'Buy'),
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
    );
  }

  String _openChestAssetForName(String name, String imageUrl) {
    final search = '$name $imageUrl'.toLowerCase();
    if (search.contains('premium') || search.contains('prestige')) {
      return 'assets/Prestige_Chest_open.png';
    }
    if (search.contains('gold')) return 'assets/Gold_Chest_open.png';
    return 'assets/Starter_Chest_open.png';
  }

  // ---------- Chest reward overlay ----------

  Widget _buildChestRewardOverlay() {
    final chest = _openingChestPreview;
    if (chest == null) return const SizedBox.shrink();

    final chestId = _toInt(chest['id']);
    final chestName = _td(_string(chest['name'], fallback: 'Chest'));
    final closedImageUrl = _string(chest['imageUrl']);
    final openedChestAsset = _openChestAssetForName(chestName, closedImageUrl);
    final reward = _openedReward;
    final rewardItem = reward == null
        ? <String, dynamic>{}
        : _map(reward['item'] ?? reward['Item'] ?? reward);
    final rewardName = reward == null
        ? ''
        : _td(
            _string(rewardItem['name'] ?? rewardItem['Name'] ?? reward['name']),
          );
    final rewardImageUrl = reward == null
        ? ''
        : _string(
            rewardItem['imageUrl'] ??
                rewardItem['ImageUrl'] ??
                reward['imageUrl'],
          );
    final rarity = reward == null ? 'common' : _shopRarity(rewardItem);
    final accent = _rarityAccent(rarity);

    return AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 220),
      child: Container(
        color: Colors.black.withOpacity(0.88),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                  builder: (_, value, __) {
                    final imageScale = 0.86 + (value * 0.14);
                    final imageOffset = 28 * (1 - value);
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_chestRevealStarted) ...[
                          GestureDetector(
                            onTap: () => _openChest(chestId),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Transform.translate(
                                  offset: Offset(0, imageOffset),
                                  child: Transform.scale(
                                    scale: imageScale,
                                    child: _buildShopImageFromUrl(
                                      closedImageUrl,
                                      width: 238,
                                      height: 238,
                                      fallback: () => const Text(
                                        '📦',
                                        style: TextStyle(fontSize: 92),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                TweenAnimationBuilder<double>(
                                  tween: Tween<double>(
                                    begin: _openHintPulseBright ? 0.5 : 1,
                                    end: _openHintPulseBright ? 1 : 0.5,
                                  ),
                                  duration: const Duration(milliseconds: 900),
                                  curve: Curves.easeInOut,
                                  onEnd: () {
                                    if (mounted &&
                                        _openingChestPreview != null &&
                                        !_chestRevealStarted) {
                                      setState(
                                        () => _openHintPulseBright =
                                            !_openHintPulseBright,
                                      );
                                    }
                                  },
                                  builder: (_, opacity, child) =>
                                      Opacity(opacity: opacity, child: child),
                                  child: Text(
                                    _lt(
                                      de: 'Klicke zum Öffnen',
                                      en: 'Click to open',
                                    ),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          if (_openingChest && reward == null) ...[
                            Transform.translate(
                              offset: Offset(0, imageOffset * 0.5),
                              child: Transform.scale(
                                scale: imageScale,
                                child: Image.asset(
                                  openedChestAsset,
                                  width: 270,
                                  height: 210,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.none,
                                  isAntiAlias: false,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFF9A8D4),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _lt(de: 'Öffnet...', en: 'Opening...'),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                          if (reward != null) ...[
                            SizedBox(
                              height: 292,
                              child: Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: ColorFiltered(
                                      colorFilter: ColorFilter.mode(
                                        Colors.black.withOpacity(0.42),
                                        BlendMode.srcATop,
                                      ),
                                      child: Image.asset(
                                        openedChestAsset,
                                        width: 284,
                                        height: 190,
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.none,
                                        isAntiAlias: false,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    top: -54,
                                    child: TweenAnimationBuilder<double>(
                                      key: ValueKey(
                                        '$chestId-$rewardName-$rewardImageUrl',
                                      ),
                                      tween: Tween<double>(begin: 0, end: 1),
                                      duration: const Duration(
                                        milliseconds: 620,
                                      ),
                                      curve: Curves.easeOutBack,
                                      builder: (_, revealValue, child) {
                                        final progress = revealValue.clamp(
                                          0.0,
                                          1.0,
                                        );
                                        return Opacity(
                                          opacity: progress,
                                          child: Transform.translate(
                                            offset: Offset(
                                              0,
                                              72 * (1 - progress),
                                            ),
                                            child: Transform.scale(
                                              scale: 0.74 + (progress * 0.26),
                                              child: child,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Center(
                                        child: rewardImageUrl.isNotEmpty
                                            ? _buildShopImageFromUrl(
                                                rewardImageUrl,
                                                width: 160,
                                                height: 160,
                                                fallback: () => Text(
                                                  _rarityIcon(rarity),
                                                  style: const TextStyle(
                                                    fontSize: 86,
                                                  ),
                                                ),
                                              )
                                            : Text(
                                                _rarityIcon(rarity),
                                                style: const TextStyle(
                                                  fontSize: 86,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              rewardName,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _rarityLabel(rarity).toUpperCase(),
                              style: TextStyle(
                                color: accent,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.6,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _closeChestReward,
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
                                      colors: [
                                        Color(0xFFEC4899),
                                        Color(0xFFF43F5E),
                                      ],
                                    ),
                                  ),
                                  child: SizedBox(
                                    height: 50,
                                    child: Center(
                                      child: Text(
                                        _lt(de: 'Weiter', en: 'Continue'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
            children: [
              Text(
                _lt(de: 'Item Shop', en: 'Item Shop'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _lt(
                  de: 'Booster, Chests und mehr.',
                  en: 'Boosters, chests and more.',
                ),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.68),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),

              // ---- Daily items section ----
              if (_displayItems.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _lt(de: 'Tägliche Items', en: 'Daily items'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: Color(0xFFEC4899).withOpacity(0.12),
                          border: Border.all(
                            color: Color(0xFFEC4899).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _dailyCountdown,
                          style: const TextStyle(
                            color: Color(0xFFF9A8D4),
                            fontSize: 12,
                            fontFeatures: [ui.FontFeature.tabularFigures()],
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 10.0;
                    final columns = constraints.maxWidth >= 330 ? 3 : 2;
                    final cardWidth =
                        (constraints.maxWidth - spacing * (columns - 1)) /
                        columns;
                    return Wrap(
                      alignment: WrapAlignment.center,
                      spacing: spacing,
                      runSpacing: spacing,
                      children: _displayItems
                          .map(
                            (item) => SizedBox(
                              width: cardWidth,
                              child: _buildCompactShopItemCard(item),
                            ),
                          )
                          .toList(growable: false),
                    );
                  },
                ),
                const SizedBox(height: 18),
              ],

              // ---- Chests section ----
              if (_displayChests.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _lt(de: 'Chests', en: 'Chests'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 10.0;
                    final columns = constraints.maxWidth >= 330 ? 3 : 2;
                    final cardWidth =
                        (constraints.maxWidth - spacing * (columns - 1)) /
                        columns;
                    return Wrap(
                      alignment: WrapAlignment.center,
                      spacing: spacing,
                      runSpacing: spacing,
                      children: _displayChests
                          .map(
                            (c) => SizedBox(
                              width: cardWidth,
                              child: _buildChestCard(c, compact: columns == 3),
                            ),
                          )
                          .toList(growable: false),
                    );
                  },
                ),
                const SizedBox(height: 18),
              ],

              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _lt(de: 'Coin Pakete', en: 'Coin packs'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 8.0;
                  final cardWidth = (constraints.maxWidth - spacing * 2) / 3;
                  return Row(
                    children: [
                      for (
                        var index = 0;
                        index < _coinPacks.length;
                        index++
                      ) ...[
                        if (index > 0) const SizedBox(width: spacing),
                        SizedBox(
                          width: cardWidth,
                          child: _buildCoinPackCard(_coinPacks[index]),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),

              if (_displayChests.isEmpty && _displayItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    _lt(de: 'Keine Items gefunden.', en: 'No items found.'),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.68),
                      fontSize: 14,
                    ),
                  ),
                ),

              // Earn section
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _lt(de: 'Coins verdienen', en: 'Earn coins'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _lt(
                        de: 'Schließe Aktivitäten ab. Die Coins werden danach automatisch deinem Konto gutgeschrieben.',
                        en: 'Complete activities. Coins are then credited to your account automatically.',
                      ),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.68),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: Color(0xFF020617).withOpacity(0.42),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.075),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _lt(
                                    de: 'Workout abschließen',
                                    en: 'Complete workout',
                                  ),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.62),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Image.asset(
                                      'assets/SYBAU_Coin.png',
                                      width: 20,
                                      height: 20,
                                      fit: BoxFit.contain,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      '50–150',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: Color(0xFF020617).withOpacity(0.42),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.075),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _lt(
                                    de: 'Quest erledigen',
                                    en: 'Finish quest',
                                  ),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.62),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Image.asset(
                                      'assets/SYBAU_Coin.png',
                                      width: 20,
                                      height: 20,
                                      fit: BoxFit.contain,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      '100–500',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Overlays
        if (_pendingPurchase != null) _buildConfirmDialog(),
        if (_openingChestPreview != null) _buildChestRewardOverlay(),
      ],
    );
  }
}
