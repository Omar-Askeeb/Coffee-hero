// lib/product_details_screen.dart
import 'package:flutter/material.dart';

import 'cart_screen.dart';
import 'models.dart';
import 'services/local_favorites.dart';
import 'auth/auth_service.dart';

// ==========================================================
// Guest bottom sheet
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
              const Icon(Icons.person_add_alt_1,
                  size: 48, color: Color(0xFFF5A623)),
              const SizedBox(height: 10),
              const Text(
                'سجّل دخولك أولاً',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'لازم تسجل دخول باش تقدر تضيف منتجات للسلة.',
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
                    Navigator.of(context).pushNamed('/login');
                  },
                  child: const Text(
                    'تسجيل الدخول',
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

class ProductDetailsScreen extends StatelessWidget {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final double price;

  const ProductDetailsScreen({
    super.key,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.price,
  });

  Future<void> _add(BuildContext context) async {
    if (AuthService.instance.isGuest) {
      await _showGuestCheckoutSheet(context);
      return;
    }

    CartStore.instance.addOrInc(
      CartLine(
        id: id,
        title: title,
        description: subtitle,
        price: price,
        qty: 1,
        imageUrl: imageUrl,
      ),
    );
  }

  void _dec() => CartStore.instance.dec(id);

  static String _formatPrice(double v) {
    final s = v.toStringAsFixed(2);
    return s.endsWith('.00') ? s.substring(0, s.length - 3) : s;
  }

  @override
  Widget build(BuildContext context) {
    LocalFavorites.instance.init();

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation:
            Listenable.merge([CartStore.instance, LocalFavorites.instance]),
        builder: (context, _) {
          final qty = CartStore.instance.qtyOf(id);
          final isFav = LocalFavorites.instance.isFav(id);

          return Column(
            children: [
              // الصورة
              Stack(
                children: [
                  SizedBox(
                    height: 320,
                    width: double.infinity,
                    child: (imageUrl.trim().isEmpty)
                        ? Container(color: const Color(0xFFF2F2F2))
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: const Color(0xFFF2F2F2)),
                          ),
                  ),

                  // زر الرجوع
                  Positioned(
                    top: 40,
                    left: 16,
                    child: _CircleBackButton(
                      onTap: () => Navigator.pop(context),
                    ),
                  ),

                  // زر المفضلة
                  Positioned(
                    top: 40,
                    right: 16,
                    child: _FavButton(
                      active: isFav,
                      onTap: () => LocalFavorites.instance.toggle(id),
                    ),
                  ),
                ],
              ),

              // المحتوى
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (subtitle.trim().isNotEmpty)
                        Text(
                          subtitle,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF6C7A89),
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'السعر: ${_formatPrice(price)} د.ل',
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                          _QtyStepper(
                            qty: qty,
                            onAdd: () => _add(context),
                            onDec: _dec,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // شريط السلة
              if (CartStore.instance.totalCount > 0)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                    child: SizedBox(
                      height: 56,
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF5A623),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CartScreen()),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'د.ل${CartStore.instance.totalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            const Text(
                              'عرض السلة',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${CartStore.instance.totalCount}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// زر الرجوع الدائري
class _CircleBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CircleBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5A623),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 46,
          height: 46,
          child: Icon(Icons.arrow_forward, color: Colors.white),
        ),
      ),
    );
  }
}

// زر القلب
class _FavButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _FavButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 6,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            active ? Icons.favorite : Icons.favorite_border,
            color:
                active ? const Color(0xFFF5A623) : const Color(0xFF9AA6B2),
          ),
        ),
      ),
    );
  }
}

// عداد الكمية
class _QtyStepper extends StatelessWidget {
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onDec;

  const _QtyStepper({
    required this.qty,
    required this.onAdd,
    required this.onDec,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          IconButton(onPressed: onDec, icon: const Icon(Icons.remove, size: 20)),
          SizedBox(
            width: 28,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          IconButton(onPressed: onAdd, icon: const Icon(Icons.add, size: 20)),
        ],
      ),
    );
  }
}
