import 'dart:io';

import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class HealthSyncResult {
  const HealthSyncResult({
    required this.steps,
    required this.kilometers,
    required this.calories,
    required this.syncedSteps,
    required this.syncedKilometers,
    required this.syncedCalories,
    required this.xpEarned,
    required this.coinsEarned,
  });

  final int steps;
  final double kilometers;
  final double calories;
  final int syncedSteps;
  final double syncedKilometers;
  final double syncedCalories;
  final int xpEarned;
  final int coinsEarned;

  bool get hasNewData =>
      syncedSteps > 0 || syncedKilometers > 0 || syncedCalories > 0;
  bool get hasRewards => xpEarned > 0 || coinsEarned > 0;
}

class HealthSyncService {
  HealthSyncService._();

  static final Health _health = Health();

  static const String _enabledKey = 'healthSync.enabled';
  static const String _lastDateKey = 'healthSync.lastDate';
  static const String _lastStepsKey = 'healthSync.lastSteps';
  static const String _lastKilometersKey = 'healthSync.lastKilometers';
  static const String _lastCaloriesKey = 'healthSync.lastCalories';

  static const List<HealthDataType> _types = <HealthDataType>[
    HealthDataType.STEPS,
    HealthDataType.DISTANCE_WALKING_RUNNING,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  static const List<HealthDataAccess> _permissions = <HealthDataAccess>[
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  static Future<bool> requestAuthorization() async {
    await _health.configure();

    if (Platform.isAndroid && !await _health.isHealthConnectAvailable()) {
      await _health.installHealthConnect();
      return false;
    }

    return _health.requestAuthorization(_types, permissions: _permissions);
  }

  static Future<HealthSyncResult> syncToday({
    bool requestPermissions = true,
  }) async {
    await _health.configure();

    if (requestPermissions) {
      final authorized = await requestAuthorization();
      if (!authorized) {
        throw Exception('Health permission denied');
      }
    }

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final dateKey = _formatDate(start);

    final steps = await _health.getTotalStepsInInterval(
      start,
      now,
      includeManualEntry: false,
    );
    final points = await _health.getHealthDataFromTypes(
      types: const <HealthDataType>[
        HealthDataType.DISTANCE_WALKING_RUNNING,
        HealthDataType.ACTIVE_ENERGY_BURNED,
      ],
      startTime: start,
      endTime: now,
    );

    final totalSteps = steps ?? 0;
    final totalMeters = _sum(points, HealthDataType.DISTANCE_WALKING_RUNNING);
    final totalKilometers = totalMeters / 1000;
    final totalCalories = _sum(points, HealthDataType.ACTIVE_ENERGY_BURNED);

    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_lastDateKey);
    final lastSteps = lastDate == dateKey
        ? prefs.getInt(_lastStepsKey) ?? 0
        : 0;
    final lastKilometers = lastDate == dateKey
        ? prefs.getDouble(_lastKilometersKey) ?? 0
        : 0.0;
    final lastCalories = lastDate == dateKey
        ? prefs.getDouble(_lastCaloriesKey) ?? 0
        : 0.0;

    final stepsDelta = (totalSteps - lastSteps).clamp(0, 1 << 31);
    final kilometersDelta = (totalKilometers - lastKilometers).clamp(
      0.0,
      double.infinity,
    );
    final caloriesDelta = (totalCalories - lastCalories).clamp(
      0.0,
      double.infinity,
    );
    var xpEarned = 0;
    var coinsEarned = 0;
    var syncedSteps = 0;
    var syncedKilometers = 0.0;
    var syncedCalories = 0.0;

    if (totalSteps > 0) {
      final reward = await ApiService.syncQuestActivityTotal(
        type: 'Steps',
        value: totalSteps.toDouble(),
        date: dateKey,
      );
      xpEarned += _toInt(reward['xpEarned']);
      coinsEarned += _toInt(reward['coinsEarned']);
      syncedSteps = _toInt(reward['syncedValue']);
    }
    if (totalKilometers > 0.01) {
      final reward = await ApiService.syncQuestActivityTotal(
        type: 'Kilometers',
        value: totalKilometers,
        date: dateKey,
      );
      xpEarned += _toInt(reward['xpEarned']);
      coinsEarned += _toInt(reward['coinsEarned']);
      syncedKilometers = _toDouble(reward['syncedValue']);
    }
    if (totalCalories >= 1) {
      final reward = await ApiService.syncQuestActivityTotal(
        type: 'Calories',
        value: totalCalories,
        date: dateKey,
      );
      syncedCalories = _toDouble(reward['syncedValue']);
    }

    await prefs.setString(_lastDateKey, dateKey);
    await prefs.setInt(_lastStepsKey, totalSteps);
    await prefs.setDouble(_lastKilometersKey, totalKilometers);
    await prefs.setDouble(_lastCaloriesKey, totalCalories);

    return HealthSyncResult(
      steps: totalSteps,
      kilometers: totalKilometers,
      calories: totalCalories,
      syncedSteps: syncedSteps > 0 ? syncedSteps : stepsDelta,
      syncedKilometers: syncedKilometers > 0
          ? syncedKilometers
          : kilometersDelta,
      syncedCalories: syncedCalories > 0 ? syncedCalories : caloriesDelta,
      xpEarned: xpEarned,
      coinsEarned: coinsEarned,
    );
  }

  static Future<HealthSyncResult?> syncIfEnabled() async {
    if (!await isEnabled()) return null;
    return syncToday(requestPermissions: false);
  }

  static double _sum(List<HealthDataPoint> points, HealthDataType type) {
    return points.where((point) => point.type == type).fold<double>(0, (
      sum,
      point,
    ) {
      final value = point.value;
      if (value is NumericHealthValue) {
        return sum + value.numericValue.toDouble();
      }
      return sum;
    });
  }

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    }
    return 0.0;
  }
}
