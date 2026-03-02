// lib/orders_local_repository.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'order_models.dart';
import 'orders_repository.dart';

class LocalOrdersRepository implements OrdersRepository {
  static const String storageKey = 'orders_v1';

  @override
  Future<List<Order>> loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      if (raw == null || raw.isEmpty) return const <Order>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <Order>[];
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .map(Order.fromJson)
          .toList(growable: false);
    } catch (_) {
      return const <Order>[];
    }
  }

  @override
  Future<void> saveAll(List<Order> orders) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(
        orders.map((e) => e.toJson()).toList(growable: false),
      );
      await prefs.setString(storageKey, raw);
    } catch (_) {}
  }
}
