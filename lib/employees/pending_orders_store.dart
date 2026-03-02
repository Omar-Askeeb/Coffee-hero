import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'pending_employee_order.dart';

class PendingOrdersStore {
  PendingOrdersStore._();
  static final PendingOrdersStore instance = PendingOrdersStore._();

  static const _kKey = 'pending_employee_orders_v1';

  Future<List<PendingEmployeeOrder>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => PendingEmployeeOrder.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<PendingEmployeeOrder> orders) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(orders.map((e) => e.toJson()).toList());
    await prefs.setString(_kKey, raw);
  }

  Future<void> seedDemoIfEmpty() async {
    final current = await load();
    if (current.isNotEmpty) return;

    final demo = [
      PendingEmployeeOrder(
        id: 'p1',
        title: 'طلب رقم #1001',
        status: 'في انتظار الموافقة',
        items: const [
          PendingOrderItem(productId: 'coffee1', name: 'قهوة تركية', price: 12.0, qty: 2),
          PendingOrderItem(productId: 'cake1', name: 'كيك شوكولاتة', price: 18.0, qty: 1),
        ],
      ),
    ];
    await save(demo);
  }
}
