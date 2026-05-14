part of '../app_shell_screen.dart';

class Booster {
  Booster({
    required this.id,
    required this.name,
    required this.quantity,
    required this.xpBoostPercentage,
    required this.coinBoostPercentage,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.rarity,
  });

  final int? id;
  final String name;
  final int quantity;
  final int xpBoostPercentage;
  final int coinBoostPercentage;
  final String description;
  final String imageUrl;
  final int price;
  final String rarity;

  int get bestBoostPercent =>
      xpBoostPercentage > 0 ? xpBoostPercentage : coinBoostPercentage;

  static Booster fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return Booster(
      id: json['id'] is int ? json['id'] as int : null,
      name: (json['name'] ?? '') as String,
      quantity: parseInt(json['quantity']),
      xpBoostPercentage: parseInt(json['xpBoostPercentage']),
      coinBoostPercentage: parseInt(json['coinBoostPercentage']),
      description: (json['description'] ?? '') as String,
      imageUrl: (json['imageUrl'] ?? json['ImageUrl'] ?? '') as String,
      price: parseInt(json['price']),
      rarity: (json['rarity'] ?? json['Rarity'] ?? '') as String,
    );
  }

  static Booster placeholder(String name) {
    return Booster(
      id: null,
      name: name,
      quantity: 1,
      xpBoostPercentage: 0,
      coinBoostPercentage: 0,
      description: '',
      imageUrl: '',
      price: 0,
      rarity: '',
    );
  }
}

class _BoosterSelection {
  const _BoosterSelection._({this.booster, required this.clear});

  const _BoosterSelection.clear() : this._(clear: true);

  const _BoosterSelection.booster(this.booster) : clear = false;

  final Booster? booster;
  final bool clear;
}
