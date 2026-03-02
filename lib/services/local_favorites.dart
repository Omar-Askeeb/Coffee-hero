import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalFavorites extends ChangeNotifier {
  LocalFavorites._();
  static final LocalFavorites instance = LocalFavorites._();

  static const _kKey = 'favorite_product_ids';
  final Set<String> _ids = <String>{};
  bool _ready = false;

  bool get isReady => _ready;

  Future<void> init() async {
    if (_ready) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kKey) ?? const <String>[];
    _ids
      ..clear()
      ..addAll(list);
    _ready = true;
    notifyListeners();
  }

  bool isFav(String id) => _ids.contains(id);

  Future<void> toggle(String id) async {
    final prefs = await SharedPreferences.getInstance();
    if (_ids.contains(id)) {
      _ids.remove(id);
    } else {
      _ids.add(id);
    }
    await prefs.setStringList(_kKey, _ids.toList());
    notifyListeners();
  }

  List<String> get allIds => _ids.toList(growable: false);
}
