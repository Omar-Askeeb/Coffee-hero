// lib/search_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth/auth_service.dart';
import 'app_routes.dart';
import 'bottom_bar_rtl.dart'; // ✅ main bottom bar
import 'cart_screen.dart';
import 'models.dart';
import 'product_details_screen.dart';
import 'services/firestore_products.dart';

/// ==========================================================
/// Guest bottom sheet (نفس HomeScreen)
/// ==========================================================
Future<void> showGuestCheckoutSheet(BuildContext context) async {
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

@immutable
class _PItem {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final double price;

  const _PItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.price,
  });
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const Color orange = Color(0xFFF5A623);
  static const Color border = Color(0xFFE5E7EB);
  static const int maxQty = 50;

  // ✅ Search tab index in BottomBarRTL
  static const int _tabIndex = 3;

  // ✅ Bottom bar height (from your BottomBarRTL)
  static const double _bottomBarH = 78;

  final TextEditingController _c = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _onBottomTap(int i) {
    if (i == _tabIndex) return; // نفس الصفحة
    Navigator.of(context).pushReplacementNamed(AppRoutes.forIndex(i));
  }

  _PItem _docToItem(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data();

    final img = (data['iconUrl'] ??
            data['imageUrl'] ??
            data['imageMainUrl'] ??
            data['image'] ??
            data['imageMainPath'] ??
            '')
        .toString();

    final priceRaw = data['price'];
    final price = (priceRaw is num) ? priceRaw.toDouble() : 0.0;

    final desc = (data['descAr'] ?? data['desc'] ?? data['description'] ?? '')
        .toString();

    return _PItem(
      id: d.id,
      title: (data['name'] ?? data['title'] ?? '').toString(),
      description: desc,
      imageUrl: img,
      price: price,
    );
  }

  List<_PItem> _filter(List<_PItem> items) {
    final q = _q.trim().toLowerCase();
    if (q.isEmpty) return const <_PItem>[];
    return items.where((e) {
      final t = e.title.toLowerCase();
      final d = e.description.toLowerCase();
      return t.contains(q) || d.contains(q);
    }).toList();
  }

  CartLine _toCartLine(_PItem it) {
    return CartLine(
      id: it.id,
      title: it.title,
      description: it.description,
      imageUrl: it.imageUrl,
      price: it.price,
      qty: 1,
    );
  }

  Future<void> _openCart() async {
    if (AuthService.instance.isGuest) {
      await showGuestCheckoutSheet(context);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const Directionality(
          textDirection: TextDirection.rtl,
          child: CartScreen(),
        ),
      ),
    );
  }

  void _openDetails(_PItem p) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: ProductDetailsScreen(
            id: p.id,
            title: p.title,
            subtitle: p.description,
            imageUrl: p.imageUrl,
            price: p.price,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartStore.instance;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,

        // ✅ Search is a main page
        bottomNavigationBar: BottomBarRTL(
          currentIndex: _tabIndex,
          onTap: _onBottomTap,
        ),

        // ✅ IMPORTANT: Checkout bar as bottomSheet فوق الشريط السفلي (يحل overflow)
        bottomSheet: AnimatedBuilder(
          animation: cart,
          builder: (context, _) {
            return _CheckoutBar(
              count: cart.totalCount,
              total: cart.totalPrice,
              onTap: _openCart,
              bottomOffset: _bottomBarH,
            );
          },
        ),

        body: SafeArea(
          child: AnimatedBuilder(
            animation: cart,
            builder: (context, _) {
              return Column(
                children: [
                  // ====== Header ======
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: _openCart,
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 46,
                            height: 46,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2F2F2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.shopping_cart_outlined,
                                      color: orange,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                if (cart.totalCount > 0)
                                  Positioned(
                                    top: -6,
                                    right: -6,
                                    child: Container(
                                      width: 18,
                                      height: 18,
                                      decoration: const BoxDecoration(
                                        color: orange,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${cart.totalCount}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            height: 1,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'البحث',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ✅ NEW SEARCH BAR DESIGN (مثل التصميم)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: const Color(0xFFE6E6E6),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),

                          Expanded(
                            child: TextField(
                              controller: _c,
                              textAlign: TextAlign.right,
                              onChanged: (v) => setState(() => _q = v),
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'هل تريد البحث عن عناصر؟',
                                hintStyle: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF9AA6B2),
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),

                          Container(
                            width: 46,
                            height: 46,
                            margin: const EdgeInsets.only(left: 10, right: 6),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.search,
                              color: Color(0xFFF5A623),
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ====== Results ======
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirestoreProductsServiceClient.instance
                          .watchProducts(),
                      builder: (context, snap) {
                        final docs = snap.data?.docs ?? const [];
                        if (snap.connectionState ==
                                ConnectionState.waiting &&
                            docs.isEmpty) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final all =
                            docs.map(_docToItem).toList(growable: false);
                        final results = _filter(all);

                        if (_q.trim().isEmpty) {
                          return const Center(
                            child: Text(
                              'اكتب كلمة في البحث لعرض النتائج',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF8A8A8A),
                              ),
                            ),
                          );
                        }

                        if (results.isEmpty) {
                          return const Center(
                            child: Text(
                              'لا توجد نتائج',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF8A8A8A),
                              ),
                            ),
                          );
                        }

                        // ✅ padding bottom محسوب عشان ما ينداس تحت checkout + bottom bar
                        const bottomPad = _bottomBarH + 90;

                        return ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                              16, 6, 16, bottomPad),
                          itemCount: results.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, i) {
                            final it = results[i];
                            final qty = cart.qtyOf(it.id);

                            return InkWell(
                              onTap: () => _openDetails(it),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          it.title,
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          it.description,
                                          textAlign: TextAlign.right,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 14,
                                            color: Color(0xFF7A869A),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        AuthService.instance.isGuest
                                            ? const Text(
                                                '—',
                                                style: TextStyle(
                                                  fontFamily: 'Cairo',
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              )
                                            : Text(
                                                'د.ل ${it.price.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  fontFamily: 'Cairo',
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  SizedBox(
                                    width: 120,
                                    height: 120,
                                    child: Stack(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(28),
                                            border: Border.all(
                                                color: border, width: 2),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(26),
                                            child:
                                                _NetImage(url: it.imageUrl),
                                          ),
                                        ),
                                        if (qty == 0)
                                          Positioned(
                                            left: 10,
                                            bottom: 10,
                                            child: _PlusOnlyCircle(
                                              onTap: () async {
                                                if (AuthService.instance
                                                    .isGuest) {
                                                  await showGuestCheckoutSheet(
                                                      context);
                                                  return;
                                                }
                                                cart.addOrInc(_toCartLine(it));
                                              },
                                            ),
                                          )
                                        else
                                          Positioned(
                                            left: 10,
                                            right: 10,
                                            bottom: 10,
                                            child: _QtyOverlayBar(
                                              qty: qty,
                                              onPlus: () async {
                                                if (AuthService.instance
                                                    .isGuest) {
                                                  await showGuestCheckoutSheet(
                                                      context);
                                                  return;
                                                }
                                                if (cart.qtyOf(it.id) >=
                                                    maxQty) return;
                                                cart.addOrInc(_toCartLine(it));
                                              },
                                              onMinus: () => cart.dec(it.id),
                                              onTrash: () => cart.remove(it.id),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PlusOnlyCircle extends StatelessWidget {
  final VoidCallback onTap;
  const _PlusOnlyCircle({required this.onTap});

  static const Color orange = Color(0xFFF5A623);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 46,
          height: 46,
          child: Icon(Icons.add, color: orange, size: 26),
        ),
      ),
    );
  }
}

class _QtyOverlayBar extends StatelessWidget {
  final int qty;
  final VoidCallback onPlus;
  final VoidCallback onMinus;
  final VoidCallback onTrash;

  const _QtyOverlayBar({
    required this.qty,
    required this.onPlus,
    required this.onMinus,
    required this.onTrash,
  });

  static const Color orange = Color(0xFFF5A623);
  static const Color border = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    final showTrash = qty == 1;

    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            _CtlBtn(icon: Icons.add, onTap: onPlus),
            _CtlDivider(),
            Expanded(
              child: Center(
                child: Text(
                  '$qty',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ),
            _CtlDivider(),
            _CtlBtn(
              icon: showTrash ? Icons.delete_outline : Icons.remove,
              onTap: showTrash ? onTrash : onMinus,
            ),
          ],
        ),
      ),
    );
  }
}

class _CtlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CtlBtn({required this.icon, required this.onTap});

  static const Color orange = Color(0xFFF5A623);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 42,
        height: 40,
        child: Icon(icon, color: orange, size: 20),
      ),
    );
  }
}

class _CtlDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 18, color: const Color(0xFFE5E7EB));
}

class _CheckoutBar extends StatelessWidget {
  final int count;
  final double total;
  final VoidCallback onTap;

  // ✅ عشان يطلع فوق BottomBar
  final double bottomOffset;

  const _CheckoutBar({
    required this.count,
    required this.total,
    required this.onTap,
    required this.bottomOffset,
  });

  static const Color orange = Color(0xFFF5A623);

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomOffset + 14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 66,
            decoration: BoxDecoration(
              color: orange,
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 18,
                  offset: Offset(0, 10),
                  color: Color(0x33000000),
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.25),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'عرض السله',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0x22FFFFFF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      AuthService.instance.isGuest
                          ? '—'
                          : 'د.ل ${total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NetImage extends StatelessWidget {
  final String url;
  const _NetImage({required this.url});

  @override
  Widget build(BuildContext context) {
    final u = url.trim();
    if (u.isEmpty) {
      return Container(
        color: const Color(0xFFF2F2F2),
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined,
            size: 34, color: Color(0xFFB0B0B0)),
      );
    }

    return Image.network(
      u,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: const Color(0xFFF2F2F2),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFFF2F2F2),
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined,
            size: 34, color: Color(0xFFB0B0B0)),
      ),
    );
  }
}
