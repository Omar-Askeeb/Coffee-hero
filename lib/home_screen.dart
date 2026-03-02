// lib/home_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth/auth_service.dart';
import 'admin/admin_hidden_entry.dart';
import 'app_routes.dart';
import 'bottom_bar_rtl.dart';
import 'cart_screen.dart';
import 'models.dart';
import 'services/firestore_products.dart';
import 'sub_category_products_screen.dart';
import 'favorites_store.dart';
import 'favorites_models.dart';

// ==========================================================
// Guest bottom sheet
// ==========================================================
// يظهر للضيف عند محاولة إضافة منتجات للسلة أو فتح السلة.
// الهدف: ما نرفعوش مباشرة لصفحة تسجيل الدخول.
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
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'سجّل الآن لتتمكن من إتمام الطلب والوصول لجميع المزايا.',
                textAlign: TextAlign.right,
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
                    elevation: 6,
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
class CategoryItem {
  final String id;
  final String label;

  /// Fallback local asset icon (keeps the UI consistent)
  final String iconAsset;

  /// Optional Firestore icon URL (e.g., Firebase Storage download URL)
  final String? iconUrl;

  /// Optional Arabic description for sub-categories (shown under the title card)
  final String? descAr;

  const CategoryItem({
    required this.id,
    required this.label,
    required this.iconAsset,
    this.iconUrl,
    this.descAr,
  });
}

@immutable
class ProductItem {
  final String id;
  final String title;
  final String subtitle;
  final double rating;
  final String imageUrl;
  final String categoryId;

  const ProductItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.rating,
    required this.imageUrl,
    required this.categoryId,
  });
}

@immutable
class MenuItem {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final double price;

  const MenuItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.price,
  });
}

@immutable
class BottomNavAssets {
  const BottomNavAssets._();

  static const String homeActive = 'assets/icons/home (2).png';
  static const String homeInactive = 'assets/icons/home (1).png';

  static const String ordersActive =
      'assets/icons/icons8-regular-document-64.png';
  static const String ordersInactive =
      'assets/icons/icons8-regular-document-64 (1).png';

  static const String employeesActive = 'assets/icons/icons8-manager-64.png';
  static const String employeesInactive = 'assets/icons/icons8-employee-64.png';

  static const String searchActive = 'assets/icons/search-database.png';
  static const String searchInactive = 'assets/icons/search-database (1).png';

  static const String profileActive = 'assets/icons/user.png';
  static const String profileInactive = 'assets/icons/user (1).png';
}

/// ===============================
/// HOME
/// ===============================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color orange = Color(0xFFF5A623);
  static const Color catBg = Color(0xFFFFE8C7);

  int navIndex = 0;

  final FavoritesStore favorites = FavoritesStore.instance;
  String selectedCategoryId = '';

  // ✅ فقط UI (الاسم هنا placeholder — انت قلت "انسى اللوكيشن" وما نلمس المنطق)
  final String _savedPlaceName = 'موقعي';

  // Used to render sub-categories using the same card UI as products.
  static const double _subCardRating = 8.5;

  ProductItem _subAsProduct(CategoryItem c) {
    return ProductItem(
      id: c.id,
      title: c.label,
      subtitle: (c.descAr != null && c.descAr!.trim().isNotEmpty)
          ? c.descAr!.trim()
          : ' ',
      rating: _subCardRating,
      imageUrl: (c.iconUrl ?? ''),
      // keep reference to the currently selected main category
      categoryId: selectedCategoryId,
    );
  }

  // Cache Firestore main categories to avoid flicker when snapshot is momentarily empty/refreshing.
  List<CategoryItem> _cachedMainCats = const [];

  // Cache sub-categories per parent to avoid a brief hide while the stream reconnects.
  final Map<String, List<CategoryItem>> _cachedSubsByParent = {};

  String _categoryLabel(String id) {
    for (final c in _cachedMainCats) {
      if (c.id == id) return c.label;
    }
    return id;
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

  void _openDetails(ProductItem product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: RestaurantDetailsScreen(
            product: product,
            categoryLabel: _categoryLabel(product.categoryId),
          ),
        ),
      ),
    );
  }

  /// ✅ يجبد الأقسام الفرعية حسب parentId (بدون ما نلمس الأقسام الرئيسية)
  Stream<List<CategoryItem>> _watchSubCategories(String parentId) {
    if (parentId.trim().isEmpty) {
      return Stream.value(const <CategoryItem>[]);
    }

    final q = FirebaseFirestore.instance
        .collection('categories')
        .where('type', isEqualTo: 'sub')
        .where('parentId', isEqualTo: parentId)
        .orderBy('order');

    return q.snapshots().map((snap) {
      final items = <CategoryItem>[];
      for (final d in snap.docs) {
        final data = d.data();

        // لو active مش موجود نعتبره true
        final active = data['active'] != false;
        if (!active) continue;

        // Always use Firestore document id for stable parentId matching.
        final id = d.id;
        final label =
            (data['nameAr'] ??
                    data['label'] ??
                    data['name'] ??
                    data['title'] ??
                    id)
                .toString();

        // ✅ iconUrl فقط (نهائياً بدون iconPath)
        final rawIcon = (data['iconUrl'] ?? data['icon'] ?? '').toString();
        final iconUrl = rawIcon.startsWith('http') ? rawIcon : null;

        final descAr = (data['descAr'] ?? data['description'] ?? '').toString();

        items.add(
          CategoryItem(
            id: id,
            label: label,
            iconAsset: 'assets/icons/coffee-beans.png', // نفس الافتراضي عندك
            iconUrl: iconUrl,
            descAr: descAr,
          ),
        );
      }
      return items;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartStore.instance;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        bottomNavigationBar: BottomBarRTL(
          currentIndex: navIndex,
          onTap: (i) {
            final route = AppRoutes.forIndex(i);
            if (route == AppRoutes.home) return;
            Navigator.of(context).pushReplacementNamed(route);
          },
        ),
        body: SafeArea(
          child: AnimatedBuilder(
            animation: cart,
            builder: (context, _) {
              return ListView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                children: [
                  const SizedBox(height: 10),

                  // ==========================================================
                  // HEADER (UI ONLY): left aligned like design + orange small arrow
                  // ==========================================================
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        // ✅ في التصميم: كارت السلة يمين
                        alignment: Alignment.centerRight,
                        child: _CartButton(
                          count: cart.totalCount,
                          onTap: _openCart,
                        ),
                      ),
                      // ✅ UI only: positioned to the LEFT of the screen like the reference
                      Align(
                        // ✅ كرت "التوصيل إلى" يسار
                        alignment: Alignment.centerLeft,
                        child: AdminHiddenEntry(
                          child: _DeliveryToHeader(
                            placeName: _savedPlaceName,
                            onTap: () => Navigator.of(context).pushNamed(
                              AppRoutes.locations,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ==========================================================
                  // BEST PRODUCTS (no discounts) - horizontal list
                  // ==========================================================
                  _BestProductsStrip(
                    stream: FirestoreProductsServiceClient.instance
                        .watchProducts(),
                    onOpen: _openDetails,
                    resolveCatLabel: _categoryLabel,
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    height: 128,
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('categories')
                          .snapshots(),
                      builder: (context, snap) {
                        final docs = snap.data?.docs ?? const [];

                        List<CategoryItem> fromFirestore() {
                          final list = docs
                              .map((d) {
                                final data = d.data();

                                // Always use Firestore document id for relational lookups (parentId)
                                // to avoid mismatches/flicker.
                                final id = d.id;
                                final label =
                                    (data['nameAr'] ??
                                            data['label'] ??
                                            data['name'] ??
                                            data['title'] ??
                                            id)
                                        .toString();

                                // If `active` field is missing, treat it as active.
                                final active = data['active'] != false;

                                // If `type` is missing, treat it as main.
                                final type = (data['type'] ?? 'main').toString();

                                int order = 0;
                                final o = data['order'];
                                if (o is num) {
                                  order = o.toInt();
                                } else {
                                  order =
                                      int.tryParse((o ?? '').toString()) ?? 0;
                                }

                                final rawIcon =
                                    (data['iconUrl'] ?? data['icon'] ?? '')
                                        .toString();
                                final iconUrl =
                                    rawIcon.startsWith('http') ? rawIcon : null;

                                return <String, dynamic>{
                                  'id': id,
                                  'label': label,
                                  'active': active,
                                  'type': type,
                                  'order': order,
                                  'iconUrl': iconUrl,
                                };
                              })
                              .where((e) {
                                // keep only active main categories (but tolerate missing fields)
                                return e['active'] == true &&
                                    (e['type'] == 'main' ||
                                        (e['type'] as String).isEmpty);
                              })
                              .toList();

                          list.sort(
                            (a, b) =>
                                (a['order'] as int).compareTo(b['order'] as int),
                          );

                          return list
                              .map((e) {
                                return CategoryItem(
                                  id: e['id'] as String,
                                  label: e['label'] as String,
                                  iconAsset: 'assets/icons/coffee-beans.png',
                                  iconUrl: e['iconUrl'] as String?,
                                );
                              })
                              .toList(growable: false);
                        }

                        // Build cats with a cache so we don't fall back to any local demo
                        // lists (you asked to remove them). We keep a cache only to prevent
                        // brief flicker when Firestore reconnects.
                        final bool hasRemote = docs.isNotEmpty;
                        List<CategoryItem> cats;
                        if (hasRemote) {
                          cats = fromFirestore();
                          _cachedMainCats = cats;
                        } else if (_cachedMainCats.isNotEmpty) {
                          cats = _cachedMainCats;
                        } else {
                          cats = const <CategoryItem>[];
                        }

                        // ensure selectedCategoryId exists
                        if (cats.isNotEmpty &&
                            !cats.any((c) => c.id == selectedCategoryId)) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            setState(() => selectedCategoryId = cats.first.id);
                          });
                        }

                        if (cats.isEmpty) {
                          return const Center(
                            child: Text(
                              'لا توجد أقسام',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF8A8A8A),
                              ),
                            ),
                          );
                        }

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              for (final c in cats) ...[
                                _CategoryTile(
                                  bg: catBg,
                                  iconAsset: c.iconAsset,
                                  iconUrl: c.iconUrl,
                                  label: c.label,
                                  selected: c.id == selectedCategoryId,
                                  onTap: () =>
                                      setState(() => selectedCategoryId = c.id),
                                ),
                                const SizedBox(width: 14),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  StreamBuilder<List<CategoryItem>>(
                    stream: _watchSubCategories(selectedCategoryId),
                    builder: (context, subSnap) {
                      // Keep last known subs for this parent to prevent a brief disappear
                      // when the stream reconnects.
                      final cached = _cachedSubsByParent[selectedCategoryId];
                      final subs = subSnap.data ?? cached ?? const <CategoryItem>[];

                      if (subSnap.hasData) {
                        _cachedSubsByParent[selectedCategoryId] = subSnap.data!;
                      }

                      // ✅ لو فيه أقسام فرعية: نعرضهم (مرحلة الأقسام فقط) ونوقف هنا
                      if (subs.isNotEmpty) {
                        return Column(
                          children: [
                            for (int i = 0; i < subs.length; i++) ...[
                              _ProductCard(
                                item: _subAsProduct(subs[i]),
                                onTap: () {
                                  final sub = subs[i];
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: SubCategoryProductsScreen(
                                          subCategoryId: sub.id,
                                          title: sub.label,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              if (i != subs.length - 1)
                                const SizedBox(height: 16),
                            ],
                          ],
                        );
                      }

                      // ✅ لو ما فيش أقسام فرعية: نعرض المنتجات (نفس الكود السابق)
                      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirestoreProductsServiceClient.instance
                            .watchProducts(),
                        builder: (context, snapshot) {
                          final docs = snapshot.data?.docs ?? [];

                          String _resolveCatId(String raw) {
                            final r = raw.trim();
                            if (r.isEmpty) return '';
                            // 1) exact match with Firestore main ids
                            for (final c in _cachedMainCats) {
                              if (c.id == r) return c.id;
                            }
                            // 2) match with labels (Arabic)
                            for (final c in _cachedMainCats) {
                              if (c.label == r) return c.id;
                            }
                            // 3) otherwise keep as-is (in case product stores the id directly)
                            return r;
                          }

                          List<ProductItem> fromFirestore() {
                            return docs
                                .map((d) {
                                  final data = d.data();
                                  final rawCat =
                                      (data['mainCategoryId'] ??
                                              data['categoryId'] ??
                                              data['category'] ??
                                              '')
                                          .toString();
                                  final catId = _resolveCatId(rawCat);
                                  final img =
                                      (data['imageUrl'] ??
                                              data['imageMainUrl'] ??
                                              data['image'] ??
                                              data['imageMainPath'] ??
                                              '')
                                          .toString();
                                  final ratingRaw = data['rating'];
                                  final rating =
                                      (ratingRaw is num) ? ratingRaw.toDouble() : 4.8;
                                  return ProductItem(
                                    id: d.id,
                                    title: (data['name'] ?? data['title'] ?? '')
                                        .toString(),
                                    subtitle: (data['descAr'] ??
                                            data['desc'] ??
                                            data['description'] ??
                                            '')
                                        .toString(),
                                    rating: rating,
                                    imageUrl: img,
                                    categoryId: catId,
                                  );
                                })
                                .toList(growable: false);
                          }

                          final products =
                              docs.isNotEmpty ? fromFirestore() : const <ProductItem>[];

                          final filtered = products
                              .where((p) {
                                if (p.categoryId.isEmpty) return true;
                                return p.categoryId == selectedCategoryId;
                              })
                              .toList(growable: false);

                          if (snapshot.connectionState == ConnectionState.waiting &&
                              docs.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 18),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          if (filtered.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 16),
                              child: Center(
                                child: Text(
                                  'لا توجد منتجات في هذا القسم',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF8A8A8A),
                                  ),
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: [
                              for (int i = 0; i < filtered.length; i++) ...[
                                _ProductCard(
                                  item: filtered[i],
                                  onTap: () => _openDetails(filtered[i]),
                                ),
                                if (i != filtered.length - 1)
                                  const SizedBox(height: 16),
                              ],
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// Delivery header (UI only)
// ==========================================================
class _DeliveryToHeader extends StatelessWidget {
  final String placeName;
  final VoidCallback onTap;
  const _DeliveryToHeader({
    required this.placeName,
    required this.onTap,
  });

  static const Color orange = Color(0xFFF5A623);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          // ✅ نخليها LTR عشان النص يكون يسار والسهم يمين (زي التصميم)
          textDirection: TextDirection.ltr,
          children: [
            // text block (left aligned)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'التوصيل إلى',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6A7890),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  placeName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400, // Regular (not bold)
                    color: Color(0xFF0F172A),
                    height: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: orange,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================
// Best products horizontal strip (no discounts)
// ==========================================================
class _BestProductsStrip extends StatelessWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final void Function(ProductItem) onOpen;
  final String Function(String) resolveCatLabel;

  const _BestProductsStrip({
    required this.stream,
    required this.onOpen,
    required this.resolveCatLabel,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) {
        final docs = snap.data?.docs ?? const [];
        if (docs.isEmpty) return const SizedBox.shrink();

        // Build list (take any 10) for "أفضل المنتجات"
        final items = <ProductItem>[];
        for (final d in docs) {
          final data = d.data();
          final img = (data['imageUrl'] ??
                  data['imageMainUrl'] ??
                  data['image'] ??
                  data['imageMainPath'] ??
                  '')
              .toString();
          if (img.trim().isEmpty) continue;

          final rawCat =
              (data['mainCategoryId'] ?? data['categoryId'] ?? data['category'] ?? '')
                  .toString();
          final catId = rawCat.trim();

          final ratingRaw = data['rating'];
          final rating = (ratingRaw is num) ? ratingRaw.toDouble() : 4.8;

          items.add(
            ProductItem(
              id: d.id,
              title: (data['name'] ?? data['title'] ?? 'منتج').toString(),
              subtitle:
                  (data['descAr'] ?? data['desc'] ?? data['description'] ?? '')
                      .toString(),
              rating: rating,
              imageUrl: img,
              categoryId: catId,
            ),
          );

          if (items.length >= 10) break;
        }

        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text(
                  'أفضل المنتجات',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final p = items[i];
                  return _MiniProductCard(
                    item: p,
                    onTap: () => onOpen(p),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MiniProductCard extends StatelessWidget {
  final ProductItem item;
  final VoidCallback onTap;
  const _MiniProductCard({required this.item, required this.onTap});

  static const Color orange = Color(0xFFF5A623);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              offset: Offset(0, 6),
              color: Color(0x22000000),
            ),
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: SizedBox(
                height: 78,
                width: double.infinity,
                child: _NetImage(url: item.imageUrl),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: orange, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      item.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6B6B6B),
                      ),
                    ),
                    const Spacer(),
                    Expanded(
                      flex: 6,
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _CartButton({required this.count, required this.onTap});

  static const Color orange = Color(0xFFF5A623);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
            if (count > 0)
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
                      '$count',
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
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Color bg;
  final String iconAsset;
  final String? iconUrl;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.bg,
    required this.iconAsset,
    this.iconUrl,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  static const Color orange = Color(0xFFF5A623);

  @override
  Widget build(BuildContext context) {
    Widget iconWidget;

    if (iconUrl != null && iconUrl!.isNotEmpty) {
      iconWidget = Image.network(
        iconUrl!,
        width: 42,
        height: 42,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.image_not_supported_outlined,
          color: Color(0xFFB0B0B0),
          size: 26,
        ),
      );
    } else {
      iconWidget = Image.asset(
        iconAsset,
        width: 42,
        height: 42,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.image_not_supported_outlined,
          color: Color(0xFFB0B0B0),
          size: 26,
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: selected ? Border.all(color: orange, width: 1.2) : null,
            ),
            child: Center(child: iconWidget),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 74,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? orange : const Color(0xFF2B2B2B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductItem item;
  final VoidCallback onTap;

  const _ProductCard({required this.item, required this.onTap});

  static const Color orange = Color(0xFFF5A623);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 270,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                blurRadius: 10,
                offset: Offset(0, 6),
                color: Color(0x22000000),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                height: 175,
                width: double.infinity,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      child: _NetImage(url: item.imageUrl),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Stack(
                    children: [
                      PositionedDirectional(
                        top: 0,
                        start: 0,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 240),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  item.subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF7A869A),
                                    height: 1.25,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        bottom: 0,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: orange, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              item.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6B6B6B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
    return Image.network(
      url,
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
        child: const Icon(
          Icons.broken_image_outlined,
          size: 34,
          color: Color(0xFFB0B0B0),
        ),
      ),
    );
  }
}

/// ===============================
/// DETAILS (Product Details) - السلة هنا Global عبر CartStore ✅
/// ===============================
class RestaurantDetailsScreen extends StatefulWidget {
  final ProductItem product;
  final String categoryLabel;

  const RestaurantDetailsScreen({
    super.key,
    required this.product,
    required this.categoryLabel,
  });

  @override
  State<RestaurantDetailsScreen> createState() => _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends State<RestaurantDetailsScreen> {
  static const int maxQty = 50;
  String _query = '';

  List<MenuItem> _filtered(List<MenuItem> items) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((e) => e.title.toLowerCase().contains(q)).toList();
  }

  List<MenuItem> get _menuItems => _menuByCategory(widget.product.categoryId);

  List<MenuItem> _menuByCategory(String categoryId) {
    const desc = 'شركة ايطاليه مختصه بجميع انواع البن';
    switch (categoryId) {
      case 'cheese':
        return const [
          MenuItem(
            id: 'c1',
            title: 'جبنه شرائح',
            description: desc,
            price: 8,
            imageUrl:
                'https://images.unsplash.com/photo-1604909052743-94e838a0a0f7?auto=format&fit=crop&w=900&q=60',
          ),
          MenuItem(
            id: 'c2',
            title: 'جبنه بيضاء',
            description: desc,
            price: 10,
            imageUrl:
                'https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?auto=format&fit=crop&w=900&q=60',
          ),
        ];
      case 'burger':
        return const [
          MenuItem(
            id: 'b1',
            title: 'برجر دجاج',
            description: desc,
            price: 15,
            imageUrl:
                'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&w=900&q=60',
          ),
          MenuItem(
            id: 'b2',
            title: 'برجر دبل',
            description: desc,
            price: 19,
            imageUrl:
                'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=900&q=60',
          ),
        ];
      case 'cups':
        return const [
          MenuItem(
            id: 'u1',
            title: 'أكواب قهوه',
            description: desc,
            price: 6,
            imageUrl:
                'https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?auto=format&fit=crop&w=900&q=60',
          ),
          MenuItem(
            id: 'u2',
            title: 'أكواب لاتيه',
            description: desc,
            price: 7,
            imageUrl:
                'https://images.unsplash.com/photo-1521305916504-4a1121188589?auto=format&fit=crop&w=900&q=60',
          ),
        ];
      case 'coffee_beans':
      default:
        return const [
          MenuItem(
            id: 'm1',
            title: 'قهوه عربيه ساده',
            description: desc,
            price: 6,
            imageUrl:
                'https://images.unsplash.com/photo-1512568400610-62da28bc8a13?auto=format&fit=crop&w=900&q=60',
          ),
          MenuItem(
            id: 'm2',
            title: 'بن محمص',
            description: desc,
            price: 6,
            imageUrl:
                'https://images.unsplash.com/photo-1511920170033-f8396924c348?auto=format&fit=crop&w=900&q=60',
          ),
          MenuItem(
            id: 'm3',
            title: 'قهوه لاتيه',
            description: desc,
            price: 6,
            imageUrl:
                'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=900&q=60',
          ),
        ];
    }
  }

  CartLine _toCartLine(MenuItem it) {
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

  @override
  Widget build(BuildContext context) {
    final cart = CartStore.instance;
    final favorites = FavoritesStore.instance;

    return AnimatedBuilder(
      animation: Listenable.merge([cart, favorites]),
      builder: (context, _) {
        final items = _filtered(_menuItems);

        return DefaultTabController(
          length: 4,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              bottomNavigationBar: _CheckoutBar(
                count: cart.totalCount,
                total: cart.totalPrice,
                coverUrl: widget.product.imageUrl,
                onTap: _openCart,
              ),
              body: NestedScrollView(
                physics: const BouncingScrollPhysics(),
                headerSliverBuilder: (context, innerBoxIsScrolled) => <Widget>[
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    pinned: true,
                    expandedHeight: 180,
                    automaticallyImplyLeading: false,

                    // ✅ عكس السهم: نخليه في بداية الشاشة (يمين في RTL) ويثبت مع السكرول
                    leadingWidth: 72,
                    leading: Padding(
                      padding: const EdgeInsetsDirectional.only(start: 12),
                      child: _CircleIconButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                    actions: const [],

                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.parallax,
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          _NetImage(url: widget.product.imageUrl),
                        ],
                      ),
                    ),
                  ),

                  // ✅ الهيدر الأبيض (تورالدوا + الوصف + التوصيل + البحث)
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _FixedDetailsHeader(
                      title: widget.product.title,
                      subtitle: widget.product.subtitle,
                      isFavorite: favorites.isFavorite(widget.product.id),
                      onToggleFavorite: () {
                        favorites.toggle(
                          FavoriteItem(
                            id: widget.product.id,
                            title: widget.product.title,
                            description: widget.product.subtitle,
                            imageUrl: widget.product.imageUrl,
                            price: 0,
                          ),
                        );
                      },
                      onQuery: (v) => setState(() => _query = v),
                    ),
                  ),
                ],
                body: TabBarView(
                  children: List.generate(
                    4,
                    (_) => _MenuListTab(
                      items: items,
                      qtyOf: cart.qtyOf,
                      onPlus: (id) async {
                        if (AuthService.instance.isGuest) {
                          await showGuestCheckoutSheet(context);
                          return;
                        }
                        final it = items.firstWhere((e) => e.id == id);
                        if (cart.qtyOf(id) >= maxQty) return;
                        cart.addOrInc(_toCartLine(it));
                      },
                      onMinus: cart.dec,
                      onTrash: cart.remove,
                      onOpenMenuItem: (menuItem) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => Directionality(
                              textDirection: TextDirection.rtl,
                              child: MenuItemDetailsScreen(
                                item: menuItem,
                                qty: cart.qtyOf(menuItem.id),
                                onPlus: () async {
                                  if (AuthService.instance.isGuest) {
                                    await showGuestCheckoutSheet(context);
                                    return;
                                  }
                                  cart.addOrInc(_toCartLine(menuItem));
                                },
                                onMinus: () {
                                  if (AuthService.instance.isGuest) return;
                                  cart.dec(menuItem.id);
                                },
                                cartCount: cart.totalCount,
                                totalPrice: cart.totalPrice,
                                onOpenCart: _openCart,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FixedDetailsHeader extends SliverPersistentHeaderDelegate {
  final String title;
  final String subtitle;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final ValueChanged<String> onQuery;

  _FixedDetailsHeader({
    required this.title,
    required this.subtitle,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onQuery,
  });

  static const Color orange = Color(0xFFF5A623);
  static const double radius = 38;

  // Expanded header (as your design)
  static const double _maxH = 292;

  // Collapsed header
  static const double _minH = 128;

  @override
  double get maxExtent => _maxH;

  @override
  double get minExtent => _minH;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final delta = maxExtent - minExtent;
    final t = (delta <= 0) ? 1.0 : (shrinkOffset / delta).clamp(0.0, 1.0);

    // smooth overlap on top of the cover image (like the mock)
    final overlapY = (-24.0) * (1.0 - t);

    final titleSize = 26.0 - (4.0 * t); // 26 -> 22
    final subtitleOpacity = (1.0 - (t * 1.2)).clamp(0.0, 1.0);
    final subtitleSpace = 8.0 * subtitleOpacity;

    return Transform.translate(
      offset: Offset(0, overlapY),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Material(
          color: Colors.white,
          elevation: 6,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(radius),
            topRight: Radius.circular(radius),
          ),
          clipBehavior: Clip.antiAlias, // ✅ fixes rounded corners not showing
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                child: Column(
                  children: [
                    // ✅ عكس عنوان/معلومات تورالدوا للجهة الثانية (زي المرجع)
                    Row(
                      textDirection: TextDirection.ltr,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: titleSize,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: onToggleFavorite,
                          borderRadius: BorderRadius.circular(999),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: orange,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: subtitleSpace),
                    if (subtitleOpacity > 0)
                      Opacity(
                        opacity: subtitleOpacity,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            subtitle,
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6A7890),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      // ✅ نعكس الترتيب: النص ثم الأيقونة (زي الصورة)
                      textDirection: TextDirection.ltr,
                      children: [
                        Text(
                          'التوصيل إلى موقعي',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6A7890),
                          ),
                        ),
                        SizedBox(width: 10),
                        _PinPill(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        onChanged: onQuery,
                        textAlign: TextAlign.right,
                        decoration: const InputDecoration(
                          hintText: 'ابحث عن عنصر...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14),
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // tabs stay visible while scrolling
              Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.centerLeft,
                child: const Directionality(
                  textDirection: TextDirection.ltr,
                  child: TabBar(
                    isScrollable: true,
                    indicatorColor: Color(0xFFFFD9A3),
                    indicatorWeight: 4,
                    labelColor: Colors.black,
                    unselectedLabelColor: Color(0xFF9AA4B2),
                    labelStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                    tabs: [
                      Tab(text: 'Most Popular'),
                      Tab(text: 'Picked for you'),
                      Tab(text: 'Starters'),
                      Tab(text: 'Salad'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _FixedDetailsHeader oldDelegate) {
    return title != oldDelegate.title ||
        subtitle != oldDelegate.subtitle ||
        isFavorite != oldDelegate.isFavorite;
  }
}

// ==========================================================
// Menu list (same as your snippet)
// ==========================================================
class _MenuListTab extends StatelessWidget {
  final List<MenuItem> items;
  final int Function(String id) qtyOf;
  final void Function(String id) onPlus;
  final void Function(String id) onMinus;
  final void Function(String id) onTrash;
  final ValueChanged<MenuItem> onOpenMenuItem;

  const _MenuListTab({
    required this.items,
    required this.qtyOf,
    required this.onPlus,
    required this.onMinus,
    required this.onTrash,
    required this.onOpenMenuItem,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 18),
      itemBuilder: (_, i) {
        final it = items[i];
        final qty = qtyOf(it.id);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onOpenMenuItem(it),
            child: _MenuRowTile(
              item: it,
              qty: qty,
              onPlus: () => onPlus(it.id),
              onMinus: () => onMinus(it.id),
              onTrash: () => onTrash(it.id),
            ),
          ),
        );
      },
    );
  }
}

class _MenuRowTile extends StatelessWidget {
  final MenuItem item;
  final int qty;
  final VoidCallback onPlus;
  final VoidCallback onMinus;
  final VoidCallback onTrash;

  const _MenuRowTile({
    required this.item,
    required this.qty,
    required this.onPlus,
    required this.onMinus,
    required this.onTrash,
  });

  static const Color orange = Color(0xFFF5A623);
  static const Color border = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.title,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.description,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7A869A),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              AuthService.instance.isGuest
                  ? const Text(
                      '—',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  : Text(
                      'د.ل ${item.price.toStringAsFixed(0)}',
                      style: const TextStyle(
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
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: border, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: _NetImage(url: item.imageUrl),
                ),
              ),
              if (qty == 0)
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: _PlusOnlyCircle(onTap: onPlus),
                )
              else
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: _QtyOverlayBar(
                    qty: qty,
                    onPlus: onPlus,
                    onMinus: onMinus,
                    onTrash: onTrash,
                  ),
                ),
            ],
          ),
        ),
      ],
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

class MenuItemDetailsScreen extends StatelessWidget {
  final MenuItem item;
  final int cartCount;
  final double totalPrice;
  final VoidCallback onOpenCart;

  final int qty;
  final VoidCallback onPlus;
  final VoidCallback onMinus;

  const MenuItemDetailsScreen({
    super.key,
    required this.item,
    required this.cartCount,
    required this.totalPrice,
    required this.onOpenCart,
    required this.qty,
    required this.onPlus,
    required this.onMinus,
  });

  static const double radius = 38;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        bottomNavigationBar: _CheckoutBar(
          count: cartCount,
          total: totalPrice,
          coverUrl: item.imageUrl,
          onTap: onOpenCart,
        ),
        body: Stack(
          children: [
            SizedBox(
              height: 340,
              width: double.infinity,
              child: _NetImage(url: item.imageUrl),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 14, left: 16, right: 16),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: _CircleIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              top: 300,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(radius),
                  topRight: Radius.circular(radius),
                ),
                child: Container(
                  color: Colors.white,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
                    children: [
                      Row(
                        children: [
                          const Spacer(),
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.description,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.4,
                          color: Color(0xFF6A7890),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        AuthService.instance.isGuest
                            ? 'السعر: —'
                            : 'السعر: د.ل ${item.price.toStringAsFixed(0)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _MiniCircle(icon: Icons.add, onTap: onPlus),
                          const SizedBox(width: 10),
                          Text(
                            '$qty',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _MiniCircle(icon: Icons.remove, onTap: onMinus),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F6F6),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Text(
                          'هنا تقدر تضيف تفاصيل أكثر (حجم/سكر/إضافات...) حسب ما تبي.',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6A7890),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MiniCircle({required this.icon, required this.onTap});

  static const Color orange = Color(0xFFF5A623);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF2F2F2),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: orange),
        ),
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  final int count;
  final double total;
  final String coverUrl;
  final VoidCallback onTap;

  const _CheckoutBar({
    required this.count,
    required this.total,
    required this.coverUrl,
    required this.onTap,
  });

  static const Color orange = Color(0xFFF5A623);

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
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
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  _CartThumbFromCover(count: count, coverUrl: coverUrl),
                  const Spacer(),
                  const Text(
                    'عرض السله',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x22FFFFFF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      AuthService.instance.isGuest
                          ? '—'
                          : 'د.ل ${total.toStringAsFixed(0)}',
                      style: const TextStyle(
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

class _CartThumbFromCover extends StatelessWidget {
  final int count;
  final String coverUrl;

  const _CartThumbFromCover({required this.count, required this.coverUrl});

  static const Color orange = Color(0xFFF5A623);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: Colors.white,
              child: _NetImage(url: coverUrl),
            ),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinPill extends StatelessWidget {
  const _PinPill();
  static const Color orange = Color(0xFFF5A623);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(color: orange, shape: BoxShape.circle),
      child: const Icon(
        Icons.location_on_outlined,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  static const Color orange = Color(0xFFF5A623);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(color: orange, shape: BoxShape.circle),
        child: Center(
          child: Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}
