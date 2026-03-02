// lib/orders_store.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'models.dart';
import 'order_models.dart';
import 'orders_local_repository.dart';
import 'orders_repository.dart';

class OrdersStore extends ChangeNotifier {
  OrdersStore._();
  static final OrdersStore instance = OrdersStore._();

  OrdersRepository _repo = LocalOrdersRepository();

  void useRepository(OrdersRepository repo) {
    _repo = repo;
  }

  static const Duration _toPreparing = Duration(seconds: 25);
  static const Duration _toOnTheWay = Duration(seconds: 50);
  static const Duration _toDelivered = Duration(seconds: 90);

  static const double defaultDeliveryFee = 12.0;
  static const double defaultServiceFee = 0.0;
  static const String defaultPaymentMethod = 'الدفع عند الاستلام';

  static const String defaultStoreName = 'هانا الرئيسي';
  static const String defaultStoreArea = 'حي الاندلس';
  static const String defaultAddress = 'حي الاندلس';

  final List<Order> _orders = <Order>[];
  bool _restored = false;
  Timer? _ticker;

  List<Order> get activeOrders =>
      _orders.where((o) => o.status.isActive).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<Order> get historyOrders =>
      _orders.where((o) => !o.status.isActive).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Order? byId(String id) {
    for (final o in _orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  Future<void> restore() async {
    if (_restored) return;
    _restored = true;

    final loaded = await _repo.loadAll();
    _orders
      ..clear()
      ..addAll(loaded);

    _refreshStatuses();
    notifyListeners();
    _startTicker();
  }

  Future<Order> createFromCart({
    required List<CartLine> cartLines,
    String address = defaultAddress,
  }) async {
    final now = DateTime.now();
    final id = _newOrderId(now);

    final lines = cartLines
        .map(
          (c) => OrderLine(
            id: c.id,
            title: c.title,
            imageUrl: c.imageUrl,
            price: c.price,
            qty: c.qty,
          ),
        )
        .toList(growable: false);

    final order = Order(
      id: id,
      createdAt: now,
      statusUpdatedAt: now,
      status: OrderStatus.pendingCompanyAccept,
      storeName: defaultStoreName,
      storeArea: defaultStoreArea,
      address: address,
      deliveryFee: defaultDeliveryFee,
      serviceFee: defaultServiceFee,
      paymentMethod: defaultPaymentMethod,
      lines: lines,
    );

    _orders.insert(0, order);
    notifyListeners();
    await _persist();
    return order;
  }

  Future<void> cancel(String orderId) async {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx < 0) return;

    final cur = _orders[idx];
    if (cur.status == OrderStatus.cancelled) return;

    _orders[idx] = cur.copyWith(
      status: OrderStatus.cancelled,
      statusUpdatedAt: DateTime.now(),
    );
    notifyListeners();
    await _persist();
  }

  void _startTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 2), (_) => _tick());
  }

  void _tick() {
    final changed = _refreshStatuses();
    if (changed) {
      notifyListeners();
      _persist();
    }
  }

  bool _refreshStatuses() {
    var changed = false;
    final now = DateTime.now();

    for (var i = 0; i < _orders.length; i++) {
      final o = _orders[i];
      if (!o.status.isActive) continue;

      final elapsed = now.difference(o.createdAt);
      final target = _statusForElapsed(elapsed);

      if (target != o.status) {
        _orders[i] = o.copyWith(status: target, statusUpdatedAt: now);
        changed = true;
      }
    }
    return changed;
  }

  OrderStatus _statusForElapsed(Duration elapsed) {
    if (elapsed < _toPreparing) return OrderStatus.pendingCompanyAccept;
    if (elapsed < _toOnTheWay) return OrderStatus.preparing;
    if (elapsed < _toDelivered) return OrderStatus.onTheWay;
    return OrderStatus.delivered;
  }

  Future<void> _persist() async {
    await _repo.saveAll(_orders);
  }

  String _newOrderId(DateTime now) {
    final rnd = Random().nextInt(900) + 100;
    return '${now.millisecondsSinceEpoch}$rnd';
  }
}
