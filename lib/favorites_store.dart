import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'favorites_models.dart';

class FavoritesStore extends ChangeNotifier {
  FavoritesStore._();

  static final FavoritesStore instance = FavoritesStore._();

  static const String _storageKey = 'favorites_v1';

  final Map<String, FavoriteItem> _byId = <String, FavoriteItem>{};
  bool _restored = false;

  List<FavoriteItem> get items => _byId.values.toList(growable: false);

  bool isFavorite(String id) => _byId.containsKey(id);

  Future<void> restore() async {
    if (_restored) return;
    _restored = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      _byId
        ..clear()
        ..addEntries(
          decoded
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .map(FavoriteItem.fromJson)
              .map((it) => MapEntry(it.id, it)),
        );

      notifyListeners();
    } catch (_) {
      // ignore
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(items.map((e) => e.toJson()).toList(growable: false));
      await prefs.setString(_storageKey, raw);
    } catch (_) {
      // ignore
    }
  }

  Future<void> toggle(FavoriteItem item) async {
    if (_byId.containsKey(item.id)) {
      _byId.remove(item.id);
    } else {
      _byId[item.id] = item;
    }
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String id) async {
    if (_byId.remove(id) != null) {
      notifyListeners();
      await _persist();
    }
  }

  Future<void> clear() async {
    if (_byId.isEmpty) return;
    _byId.clear();
    notifyListeners();
    await _persist();
  }
}
