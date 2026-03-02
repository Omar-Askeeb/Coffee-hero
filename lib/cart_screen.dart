// lib/cart_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'models.dart';
import 'orders_store.dart';
import 'services/firestore_employee_drafts.dart';
import 'app_routes.dart';
import 'auth/auth_service.dart';
import 'services/firestore_orders.dart';

// ==========================================================
// Guest bottom sheet (يظهر بدل تحويل الضيف للـ Login)
// ==========================================================
Future<void> _showGuestCheckoutSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 14),
              Image.asset(
                'assets/icons/add-user.png',
                height: 90,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 10),
              const Text(
                'مرحباً بك ضيفنا العزيز!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'سجّل الآن لتتمكن من إتمام الطلب والوصول لجميع المزايا.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  height: 1.4,
                  color: Color(0xFF6A6A6A),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5A623),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pushNamed(AppRoutes.login);
                  },
                  child: const Text(
                    'تسجيل الدخول / إنشاء حساب',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'لاحقاً',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class CartStore extends ChangeNotifier {
  CartStore._();

  /// Global singleton (kept to avoid changing the app structure).
  static final CartStore instance = CartStore._();

  static const int maxQtyPerItem = 50;
  static const String _storageKey = 'cart_lines_v1';

  final Map<String, CartLine> _byId = <String, CartLine>{};
  bool _restored = false;

  List<CartLine> get lines => _byId.values.toList(growable: false);

  int get totalCount => _byId.values.fold<int>(0, (a, b) => a + b.qty);

  double get totalPrice =>
      _byId.values.fold<double>(0, (a, b) => a + (b.price * b.qty));

  int qtyOf(String id) => _byId[id]?.qty ?? 0;

  /// Loads saved cart (call once at startup). Safe to call multiple times.
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
              .map((m) => CartLine.fromJson(m))
              .map((line) => MapEntry<String, CartLine>(line.id, line)),
        );

      notifyListeners();
    } catch (_) {
      // Ignore corrupted storage; keep cart empty.
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw =
          jsonEncode(lines.map((e) => e.toJson()).toList(growable: false));
      await prefs.setString(_storageKey, raw);
    } catch (_) {
      // Ignore write failures; cart still works in-memory.
    }
  }

  void addOrInc(CartLine payload) {
    final cur = _byId[payload.id];
    if (cur == null) {
      _byId[payload.id] = payload.copyWith(qty: 1);
      notifyListeners();
      _persist();
      return;
    }
    if (cur.qty >= maxQtyPerItem) return;
    _byId[payload.id] = cur.copyWith(qty: cur.qty + 1);
    notifyListeners();
    _persist();
  }

  void inc(String id) {
    final cur = _byId[id];
    if (cur == null) return;
    if (cur.qty >= maxQtyPerItem) return;
    _byId[id] = cur.copyWith(qty: cur.qty + 1);
    notifyListeners();
    _persist();
  }

  void dec(String id) {
    final cur = _byId[id];
    if (cur == null) return;
    if (cur.qty <= 1) {
      _byId.remove(id);
      notifyListeners();
      _persist();
      return;
    }
    _byId[id] = cur.copyWith(qty: cur.qty - 1);
    notifyListeners();
    _persist();
  }

  void remove(String id) {
    if (_byId.remove(id) != null) {
      notifyListeners();
      _persist();
    }
  }

  Future<void> replaceAll(Iterable<CartLine> lines) async {
    _byId
      ..clear()
      ..addEntries(lines.map((e) => MapEntry<String, CartLine>(e.id, e)));

    notifyListeners();
    await _persist();
  }

  Future<void> clear() async {
    if (_byId.isEmpty) return;
    _byId.clear();
    notifyListeners();
    await _persist();
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  static const Color orange = Color(0xFFF5A623);
  static const Color border = Color(0xFFE6E6E6);

  // ✅ CHANGED: التوصيل مجاني وثابت
  static const double deliveryFee = 0.0;

  String _money(double v) => v.toStringAsFixed(2);


  /// ✅ نجيب آخر موقع محفوظ للزبون من:
  /// customers/{uid}/locations (آخر واحد حسب createdAt)
  Future<Map<String, dynamic>?> _getLatestCustomerLocation(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('customers')
          .doc(uid)
          .collection('locations')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return null;
      return snap.docs.first.data();
    } catch (_) {
      return null;
    }
  }

  /// ✅ لو ما عندهش موقع: نطلعله شيت محترم ونمشيه لصفحة العناوين/الخريطة
  Future<void> _requireLocationSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 14),
                const Icon(Icons.location_on, size: 42, color: orange),
                const SizedBox(height: 10),
                const Text(
                  'لازم تضيف عنوان قبل تأكيد الطلب',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'باش نقدروا نوصلوا طلبك، اختار موقعك واحفظه وبعدين ارجع أكد الطلب.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    height: 1.4,
                    color: Color(0xFF6A6A6A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).pushNamed(AppRoutes.locations);
                    },
                    child: const Text(
                      'إضافة عنوان',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _placeOrder(BuildContext context) async {
    final cart = CartStore.instance;

    if (AuthService.instance.isGuest) {
      await _showGuestCheckoutSheet(context);
      return;
    }

    final user = AuthService.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سجّل دخول من جديد وبعدين حاول')),
      );
      return;
    }

    if (cart.lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('السلة فارغة')),
      );
      return;
    }


    // ✅ لازم يكون عند الزبون عنوان محفوظ قبل ما يأكد الطلب
    final latestLoc = await _getLatestCustomerLocation(user.uid);
    final latVal = latestLoc?['lat'];
    final lngVal = latestLoc?['lng'];
    final addressFromLoc = (latestLoc?['address'] ?? '').toString().trim();

    final hasCoords = (latVal is num) && (lngVal is num);
    if (!hasCoords) {
      await _requireLocationSheet(context);
      return;
    }

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'تأكيد الطلب',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  addressFromLoc.isEmpty ? OrdersStore.defaultAddress : addressFromLoc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    height: 1.4,
                    color: Color(0xFF6A6A6A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          side: const BorderSide(color: Color(0xFFE6E6E6)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('تراجع'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orange,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('تأكيد'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;

    final items = cart.lines
        .map((e) => <String, dynamic>{
              'id': e.id,
              'title': e.title,
              'qty': e.qty,
              'price': e.price,
              'imageUrl': e.imageUrl,
            })
        .toList(growable: false);

    // ✅ CHANGED: الإجمالي بدون توصيل (لأنه مجاني)
    final total = cart.totalPrice;

    // ✅ Employee: لا ينشئ طلب رسمي، فقط يرسل "مسودة" للمدير
    if (user.role == 'employee') {
      final ownerUid = user.ownerUid ?? '';
      if (ownerUid.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حساب الموظف غير مربوط بصاحب المقهى')),
        );
        return;
      }

      await FirestoreEmployeeDraftsService.instance.submitEmployeeCart(
        ownerUid: ownerUid,
        employeeUid: user.uid,
        employeeName: user.cafeName,
        items: items,
        count: cart.totalCount,
        total: total,
      );

      await cart.clear();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال السلة للمدير للمراجعة')),
      );

      Navigator.of(context).pop();
      return;
    }

    final orderId = await FirestoreOrdersService.instance.createOrder(
      customerId: user.phone,
      customerName: user.cafeName,
      customerPhone: user.phone,
      addressText: addressFromLoc.isEmpty ? OrdersStore.defaultAddress : addressFromLoc,
      lat: (latVal as num).toDouble(),
      lng: (lngVal as num).toDouble(),
      items: items,
      total: total,
      paymentMethod: 'cash',
      // لو عندك باراميتر deliveryFee في createOrder مستقبلاً، نبعته 0
    );

    await cart.clear();

    if (!context.mounted) return;

    Navigator.of(context).pushReplacementNamed(
      AppRoutes.trackOrder,
      arguments: orderId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartStore.instance;

    return AnimatedBuilder(
      animation: cart,
      builder: (context, _) {
        final lines = cart.lines;
        final isEmpty = lines.isEmpty;

        final subtotal = cart.totalPrice;
        final count = cart.totalCount;

        // ✅ CHANGED: الإجمالي = subtotal فقط
        final total = subtotal;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: false,
            titleSpacing: 0,
            title: const Padding(
              padding: EdgeInsets.only(left: 18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'السلة',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          bottomNavigationBar: isEmpty
              ? null
              : _ContinueBar(
                  total: total,
                  onTap: () => _placeOrder(context),
                ),
          body: isEmpty
              ? const _EmptyCart()
              : ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
                  children: [
                    _OrderCard(
                      coverUrl: lines.first.imageUrl,
                      totalText: '-${_money(subtotal)}',
                      piecesCount: count,
                    ),
                    const SizedBox(height: 14),
                    _CartItemsCard(
                      lines: lines,
                      onPlus: cart.inc,
                      onMinus: cart.dec,
                      onDelete: cart.remove,
                      onAddMore: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'الفاتوره',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Column(
                        children: [
                          _InvoiceRow(
                            label: 'سعر الطلبيه',
                            value: '-${_money(subtotal)}',
                            valueColor: Colors.black,
                          ),
                          const SizedBox(height: 10),
                          const _InvoiceRow(
                            label: 'عموله التطبيق',
                            value: 'مجانا',
                            valueColor: Color(0xFF2F80ED),
                          ),
                          const SizedBox(height: 10),

                          // ✅ CHANGED: التوصيل مجانا (بدون -0.00)
                          const _InvoiceRow(
                            label: 'سعر التوصيل',
                            value: 'مجانا',
                            valueColor: Color(0xFF2F80ED),
                          ),

                          const SizedBox(height: 10),
                          _InvoiceRow(
                            label: 'العدد',
                            value: '$count',
                            valueColor: Colors.black,
                          ),
                          const SizedBox(height: 14),
                          Container(height: 1, color: const Color(0xFFEDEDED)),
                          const SizedBox(height: 14),
                          _InvoiceRow(
                            label: 'الأجمالي',
                            value: '-${_money(total)}',
                            valueColor: const Color(0xFF27AE60),
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _ContinueBar extends StatelessWidget {
  final double total;
  final VoidCallback onTap;

  const _ContinueBar({
    required this.total,
    required this.onTap,
  });

  static const Color orange = Color(0xFFF5A623);

  String _money(double v) => v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: orange,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'د.ل${_money(total)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                const Text(
                  'استمرار',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icons/cart.png', width: 180, height: 180),
            const SizedBox(height: 14),
            const Text(
              'السلة فارغة',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'اضف منتجات من القائمة وبعدين تعال للسلة.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6A7890),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final String coverUrl;
  final String totalText;
  final int piecesCount;

  const _OrderCard({
    required this.coverUrl,
    required this.totalText,
    required this.piecesCount,
  });

  static const Color border = Color(0xFFE6E6E6);
  static const Color textGrey = Color(0xFF6A7890);

  String get piecesLabel => '$piecesCount قطعه';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'طلبية',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  '$totalText  |  $piecesLabel',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: textGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              coverUrl,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 44,
                height: 44,
                color: const Color(0xFFF2F2F2),
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: Color(0xFFB0B0B0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemsCard extends StatelessWidget {
  final List<CartLine> lines;
  final void Function(String id) onPlus;
  final void Function(String id) onMinus;
  final void Function(String id) onDelete;
  final VoidCallback onAddMore;

  const _CartItemsCard({
    required this.lines,
    required this.onPlus,
    required this.onMinus,
    required this.onDelete,
    required this.onAddMore,
  });

  static const Color border = Color(0xFFE6E6E6);
  static const Color orange = Color(0xFFF5A623);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        children: [
          for (int i = 0; i < lines.length; i++) ...[
            _CartLineTile(
              line: lines[i],
              onPlus: () => onPlus(lines[i].id),
              onMinus: () => onMinus(lines[i].id),
              onDelete: () => onDelete(lines[i].id),
            ),
            if (i != lines.length - 1) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFEDEDED)),
              const SizedBox(height: 12),
            ],
          ],
          const SizedBox(height: 10),
          InkWell(
            onTap: onAddMore,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '+',
                    style: TextStyle(
                      color: orange,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'إضافة عناصر',
                    style: TextStyle(
                      color: orange,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartLineTile extends StatelessWidget {
  final CartLine line;
  final VoidCallback onPlus;
  final VoidCallback onMinus;
  final VoidCallback onDelete;

  const _CartLineTile({
    required this.line,
    required this.onPlus,
    required this.onMinus,
    required this.onDelete,
  });

  static const Color orange = Color(0xFFF5A623);
  static const Color textGrey = Color(0xFF6A7890);
  static const Color border = Color(0xFFE6E6E6);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onDelete,
          child: const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.delete_outline, size: 26, color: Colors.black),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                line.title,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'د.ل${line.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: textGrey,
                ),
              ),
              const SizedBox(height: 10),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Container(
                  height: 38,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      _QtyIconBtn(icon: Icons.add, onTap: onPlus),
                      Expanded(
                        child: Center(
                          child: Text(
                            '${line.qty}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                      _QtyIconBtn(icon: Icons.remove, onTap: onMinus),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            line.imageUrl,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 56,
              height: 56,
              color: const Color(0xFFF2F2F2),
              child: const Icon(
                Icons.broken_image_outlined,
                color: Color(0xFFB0B0B0),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QtyIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyIconBtn({required this.icon, required this.onTap});

  static const Color orange = Color(0xFFF5A623);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 42,
        height: 38,
        child: Icon(icon, color: orange, size: 22),
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool bold;

  const _InvoiceRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final weight = bold ? FontWeight.w900 : FontWeight.w800;

    return Row(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: weight,
            color: valueColor,
          ),
        ),
        const Spacer(),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: weight,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
