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
  Map<String, dynamic>? _openedReward;
  bool _openingChest = false;
  int? _openingChestId;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profile = await ApiService.getProfile();
      final results = await Future.wait<dynamic>([
        ApiService.getShopItems().catchError((error) {
          debugPrint('Shop items load error: $error');
          return <dynamic>[];
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
      setState(() {
        _profile = _map(profile);
        _currentCoins = _toInt(_profile['coins']);
        _items = results[0] as List<dynamic>;
        _chests = results[1] as List<dynamic>;
        _ownedItems = results[2] as List<dynamic>;
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
      // Dismiss the confirm dialog immediately so it doesn't overlap with the reward overlay
      setState(() {
        _pendingPurchase = null;
        _buying = false;
      });
      await _openChest(id);
      await widget.onRefreshHeader();
      // _load() is deferred to _closeChestReward so the shop stays stable while the reward is visible
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
    setState(() {
      _openingChest = true;
      _openingChestId = chestId;
      _openedReward = null;
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
      });
      widget.showSnack(errorMsg);
    }
  }

  void _closeChestReward() {
    setState(() {
      _openedReward = null;
      _openingChestId = null;
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
        explicit == 'legendary') {
      return explicit;
    }
    final price = _toInt(item['price']);
    if (price >= 1200) return 'legendary';
    if (price >= 700) return 'epic';
    if (price >= 350) return 'rare';
    return 'common';
  }

  Color _rarityAccent(String rarity) {
    switch (rarity) {
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

  String _rarityIcon(String rarity, {String category = 'item'}) {
    if (category == 'chest') {
      switch (rarity) {
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
            'items': (m['items'] ?? m['Items'] ?? []) as List<dynamic>,
          };
        })
        .toList(growable: false);
  }

  // ---------- Image / placeholder builders ----------

  Widget _buildItemImage(String? imageUrl, {double size = 86}) {
    final resolved = ApiService.mediaUrl(imageUrl);
    if (resolved != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          resolved,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildEmojiPlaceholder(size),
        ),
      );
    }
    return _buildEmojiPlaceholder(size);
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

  Widget _buildChestCard(Map<String, dynamic> chest) {
    final price = _toInt(chest['price']);
    final canAfford = _currentCoins >= price;
    final isOpening = _openingChestId == _toInt(chest['id']);
    final imageUrl = _string(chest['imageUrl']);

    return Container(
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
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 104,
                  child: Center(
                    child: imageUrl.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Image.network(
                              ApiService.mediaUrl(imageUrl) ?? '',
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.none,
                              isAntiAlias: false,
                              errorBuilder: (_, __, ___) => const Text(
                                '📦',
                                style: TextStyle(fontSize: 42),
                              ),
                            ),
                          )
                        : const Text('📦', style: TextStyle(fontSize: 42)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _td(_string(chest['name'])),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 38,
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
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: canAfford
                            ? const LinearGradient(
                                colors: [Color(0xFF22C55E), Color(0xFF14532D)],
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
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatCompactNumber(price),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
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
            top: 10,
            right: 10,
            child: InkWell(
              onTap: () => _showChestRatesDialog(chest),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 26,
                height: 26,
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
                  size: 14,
                ),
              ),
            ),
          ),
        ],
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
                          ? Image.network(
                              ApiService.mediaUrl(imageUrl) ?? '',
                              width: 74,
                              height: 74,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.none,
                              isAntiAlias: false,
                              errorBuilder: (_, __, ___) => Text(
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
                          const SizedBox(height: 6),
                          Text(
                            _td(rarity).toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.2,
                            ),
                          ),
                          if (xpBoost > 0 || coinBoost > 0) ...[
                            const SizedBox(height: 11),
                            if (xpBoost > 0)
                              _buildBoostPill(
                                iconAsset: 'assets/XP_Pixel.png',
                                label: '+$xpBoost% XP',
                                textColor: Color(0xFF60A5FA),
                                borderColor: Color(0xFF3B82F6),
                                backgroundColor: Color(0xFF2563EB),
                              ),
                            if (xpBoost > 0 && coinBoost > 0)
                              const SizedBox(height: 5),
                            if (coinBoost > 0)
                              _buildBoostPill(
                                iconAsset: 'assets/SYBAU_Coin.png',
                                label: '+$coinBoost% Coins',
                                textColor: Color(0xFFFACC15),
                                borderColor: Color(0xFFF59E0B),
                                backgroundColor: Color(0xFFF59E0B),
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
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        color: backgroundColor.withOpacity(0.16),
        border: Border.all(color: borderColor.withOpacity(0.38)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Image.asset(
            iconAsset,
            width: 16,
            height: 16,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
            isAntiAlias: false,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Buy / Open confirm dialog ----------

  Widget _buildConfirmDialog() {
    if (_pendingPurchase == null) return const SizedBox.shrink();
    final isChest = _pendingPurchase!['isChest'] == true;
    final name = _td(_string(_pendingPurchase!['name']));
    final price = _toInt(_pendingPurchase!['price']);
    final imageUrl = _string(_pendingPurchase!['imageUrl']);
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

  // ---------- Chest reward overlay ----------

  Widget _buildChestRewardOverlay() {
    if (_openedReward == null) return const SizedBox.shrink();
    final reward = _openedReward!;
    final rewardItem = _map(reward['item'] ?? reward['Item'] ?? reward);
    final rewardName = _td(
      _string(rewardItem['name'] ?? rewardItem['Name'] ?? reward['name']),
    );
    final rewardImageUrl = _string(
      rewardItem['imageUrl'] ?? rewardItem['ImageUrl'] ?? reward['imageUrl'],
    );
    final rarity = _shopRarity(rewardItem);
    final accent = _rarityAccent(rarity);

    return AnimatedOpacity(
      opacity: _openedReward == null ? 0 : 1,
      duration: const Duration(milliseconds: 220),
      child: Container(
        color: Colors.black.withOpacity(0.88),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                  builder: (_, value, __) {
                    final imageScale = 0.82 + (value * 0.18);
                    final imageOffset = 28 * (1 - value);
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _lt(de: 'Du hast erhalten:', en: 'You received:'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Transform.translate(
                          offset: Offset(0, imageOffset),
                          child: Opacity(
                            opacity: value.clamp(0, 1),
                            child: Transform.scale(
                              scale: imageScale,
                              child: rewardImageUrl.isNotEmpty
                                  ? Image.network(
                                      ApiService.mediaUrl(rewardImageUrl) ?? '',
                                      width: 118,
                                      height: 118,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.none,
                                      isAntiAlias: false,
                                      errorBuilder: (_, __, ___) => Text(
                                        rarity == 'legendary'
                                            ? '👑'
                                            : rarity == 'epic'
                                            ? '💎'
                                            : '⭐',
                                        style: const TextStyle(fontSize: 72),
                                      ),
                                    )
                                  : Text(
                                      rarity == 'legendary'
                                          ? '👑'
                                          : rarity == 'epic'
                                          ? '💎'
                                          : '⭐',
                                      style: const TextStyle(fontSize: 72),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Opacity(
                          opacity: (value - 0.18).clamp(0, 1),
                          child: Column(
                            children: [
                              Text(
                                rewardName,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _td(rarity).toUpperCase(),
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
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
              // Hero section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shop',
                    style: TextStyle(
                      color: Color(0xFFF9A8D4),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
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
                ],
              ),
              const SizedBox(height: 16),

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
                    final cardWidth = (constraints.maxWidth - spacing) / 2;
                    return Wrap(
                      alignment: WrapAlignment.center,
                      spacing: spacing,
                      runSpacing: spacing,
                      children: _displayChests
                          .map(
                            (c) => SizedBox(
                              width: cardWidth,
                              child: _buildChestCard(c),
                            ),
                          )
                          .toList(growable: false),
                    );
                  },
                ),
                const SizedBox(height: 18),
              ],

              // ---- Items section ----
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
                      Text(
                        _lt(de: 'Items', en: 'Items'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                ..._displayItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildShopItemCard(item),
                  ),
                ),
              ],

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
        if (_openedReward != null) _buildChestRewardOverlay(),
      ],
    );
  }
}
