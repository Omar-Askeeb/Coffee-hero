// lib/state/cart_store.dart
import 'package:flutter/material.dart';
import '../models/cart_line.dart';

class CartStore extends ChangeNotifier {
  CartStore._();
  static final CartStore instance = CartStore._();

  static const int maxQtyPerItem = 50;

  final Map<String, CartLine> _byId = <String, CartLine>{};

  List<CartLine> get lines => _byId.values.toList(growable: false);

  int get totalCount => _byId.values.fold<int>(0, (a, b) => a + b.qty);

  double get totalPrice =>
      _byId.values.fold<double>(0, (a, b) => a + (b.price * b.qty));

  int qtyOf(String id) => _byId[id]?.qty ?? 0;

  void addOrInc(CartLine payload) {
    final cur = _byId[payload.id];
    if (cur == null) {
      _byId[payload.id] = payload.copyWith(qty: 1);
      notifyListeners();
      return;
    }
    if (cur.qty >= maxQtyPerItem) return;
    _byId[payload.id] = cur.copyWith(qty: cur.qty + 1);
    notifyListeners();
  }

  void inc(String id) {
    final cur = _byId[id];
    if (cur == null) return;
    if (cur.qty >= maxQtyPerItem) return;
    _byId[id] = cur.copyWith(qty: cur.qty + 1);
    notifyListeners();
  }

  void dec(String id) {
    final cur = _byId[id];
    if (cur == null) return;
    if (cur.qty <= 1) {
      _byId.remove(id);
      notifyListeners();
      return;
    }
    _byId[id] = cur.copyWith(qty: cur.qty - 1);
    notifyListeners();
  }

  void remove(String id) {
    if (_byId.remove(id) != null) notifyListeners();
  }
}
