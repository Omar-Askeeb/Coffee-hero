// lib/sub_category_products_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth/auth_service.dart';
import 'app_routes.dart';
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

class SubCategoryProductsScreen extends StatefulWidget {
  final String subCategoryId;
  final String title;

  const SubCategoryProductsScreen({
    super.key,
    required this.subCategoryId,
    required this.title,
  });

  @override
  State<SubCategoryProductsScreen> createState() =>
      _SubCategoryProductsScreenState();
}

class _SubCategoryProductsScreenState extends State<SubCategoryProductsScreen> {
  static const Color orange = Color(0xFFF5A623);
  static const int maxQty = 50;

  String _query = '';

  bool _matchesSub(Map<String, dynamic> data) {
    final rawSub = (data['subCategoryId'] ??
            data['sub_category_id'] ??
            data['subcategoryId'] ??
            data['subId'] ??
            '')
        .toString();

    final rawCat = (data['categoryId'] ?? data['category'] ?? '').toString();

    if (rawSub.isNotEmpty && rawSub == widget.subCategoryId) return true;
    if (rawCat.isNotEmpty && rawCat == widget.subCategoryId) return true;
    return false;
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

    final desc =
        (data['descAr'] ?? data['desc'] ?? data['description'] ?? '').toString();

    return _PItem(
      id: d.id,
      title: (data['name'] ?? data['title'] ?? '').toString(),
      description: desc,
      imageUrl: img,
      price: price,
    );
  }

  List<_PItem> _filter(List<_PItem> items) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items
        .where((e) =>
            e.title.toLowerCase().contains(q) ||
            e.description.toLowerCase().contains(q))
        .toList();
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
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('categories')
            .doc(widget.subCategoryId)
            .snapshots(),
        builder: (context, subSnap) {
          final subData = subSnap.data?.data() ?? {};
          final headerUrl = (subData['iconUrl'] ?? subData['icon'] ?? '')
              .toString()
              .trim();
          final subDesc =
              (subData['descAr'] ?? subData['description'] ?? '').toString();

          return AnimatedBuilder(
            animation: cart,
            builder: (context, _) {
              return Scaffold(
                bottomNavigationBar: _CheckoutBar(
                  count: cart.totalCount,
                  total: cart.totalPrice,
                  coverUrl: headerUrl.isNotEmpty
                      ? headerUrl
                      : 'https://via.placeholder.com/300',
                  onTap: _openCart,
                ),
                body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirestoreProductsServiceClient.instance.watchProducts(),
                  builder: (context, snap) {
                    final docs = snap.data?.docs ?? const [];

                    final matched =
                        docs.where((d) => _matchesSub(d.data())).toList();

                    final items = matched.map(_docToItem).toList();
                    final filtered = _filter(items);

                    return NestedScrollView(
                      physics: const BouncingScrollPhysics(),
                      headerSliverBuilder: (context, _) => [
                        SliverAppBar(
                          pinned: true,
                          collapsedHeight: 56,
                          expandedHeight: 220,
                          backgroundColor: Colors.white,
                          elevation: 0,
                          automaticallyImplyLeading: false,
                          title: Text(
                            (subData['nameAr'] ?? widget.title ?? '').toString(),
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: Colors.black,
                            ),
                          ),
                          centerTitle: false,
                          actions: [
                            Padding(
                              padding: const EdgeInsetsDirectional.only(end: 8),
                              child: _CircleIconButton(
                                icon: Icons.arrow_back,
                                onTap: () => Navigator.of(context).pop(),
                              ),
                            ),
                          ],
                          flexibleSpace: FlexibleSpaceBar(
                            collapseMode: CollapseMode.parallax,
                            background: Stack(
                              fit: StackFit.expand,
                              children: [
                                _NetImage(url: headerUrl),
                              ],
                            ),
                          ),
                        ),
                        SliverPersistentHeader(
                          pinned: false,
                          delegate: _FixedDetailsHeader(
                            title: widget.title,
                            subtitle: subDesc.trim().isEmpty ? ' ' : subDesc,
                            onQuery: (v) => setState(() => _query = v),
                          ),
                        ),
                      ],
                      body: (snap.connectionState == ConnectionState.waiting &&
                              docs.isEmpty)
                          ? const Center(child: CircularProgressIndicator())
                          : (filtered.isEmpty)
                              ? const Padding(
                                  padding: EdgeInsets.only(top: 18),
                                  child: Center(
                                    child: Text(
                                      'لا توجد منتجات في هذا القسم',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF8A8A8A),
                                      ),
                                    ),
                                  ),
                                )
                              : _MenuListTab(
                                  items: filtered,
                                  qtyOf: cart.qtyOf,
                                  onPlus: (id) async {
                                    if (AuthService.instance.isGuest) {
                                      await showGuestCheckoutSheet(context);
                                      return;
                                    }
                                    if (cart.qtyOf(id) >= maxQty) return;
                                    final it =
                                        filtered.firstWhere((e) => e.id == id);
                                    cart.addOrInc(_toCartLine(it));
                                  },
                                  onMinus: cart.dec,
                                  onTrash: cart.remove,
                                  onOpenItem: (it) => _openDetails(it),
                                ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FixedDetailsHeader extends SliverPersistentHeaderDelegate {
  final String title;
  final String subtitle;
  final ValueChanged<String> onQuery;

  _FixedDetailsHeader({
    required this.title,
    required this.subtitle,
    required this.onQuery,
  });

  static const double radius = 38;

  @override
  double get maxExtent => 220;

  @override
  double get minExtent => 220;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Transform.translate(
      offset: const Offset(0, -22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(radius),
            topRight: Radius.circular(radius),
          ),
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Column(
                      // ✅ هذا يخلي كل العناصر تتجه لليمين
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // ✅ title أقصى اليمين (عرض كامل)
                        SizedBox(
                          width: double.infinity,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              title,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ✅ subtitle أقصى اليمين (عرض كامل)
                        SizedBox(
                          width: double.infinity,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              subtitle,
                              textAlign: TextAlign.right,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6A7890),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ✅ location أقصى اليمين (عرض كامل)
                        AuthService.instance.isGuest
                            ? const SizedBox(
                                width: double.infinity,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'يرجى تسجيل الدخول لعرض موقع التوصيل',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF6A7890),
                                    ),
                                  ),
                                ),
                              )
                            : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                        .collection('customers')
                        .doc(AuthService.instance.user!.uid)
                        .snapshots(),
                        builder: (context, customerSnap) {
                        final selectedId =
                        customerSnap.data?.data()?['selectedLocationId'];
                        
                        if (selectedId == null) {
                        return const SizedBox();
                        }
                        
                        return StreamBuilder<
                        DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                        .collection('customers')
                        .doc(AuthService.instance.user!.uid)
                        .collection('locations')
                        .doc(selectedId)
                        .snapshots(),
                        builder: (context, locSnap) {
                        final locName =
                        (locSnap.data?.data()?['name'] ?? '')
                        .toString();
                        
                        return SizedBox(
                        width: double.infinity,
                        child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                        Text(
                        locName,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6A7890),
                        ),
                        ),
                        const SizedBox(width: 8),
                        const _PinPill(),
                        ],
                        ),
                        );
                        },
                        );
                        },
                        ),

                        const SizedBox(height: 12),

                        // ✅ search box (يمين)
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
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 14),
                              // في RTL خليها يمين
                              suffixIcon: Icon(Icons.search),
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
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _FixedDetailsHeader oldDelegate) {
    return title != oldDelegate.title || subtitle != oldDelegate.subtitle;
  }
}

class _MenuListTab extends StatelessWidget {
  final List<_PItem> items;
  final int Function(String id) qtyOf;
  final void Function(String id) onPlus;
  final void Function(String id) onMinus;
  final void Function(String id) onTrash;
  final ValueChanged<_PItem> onOpenItem;

  const _MenuListTab({
    required this.items,
    required this.qtyOf,
    required this.onPlus,
    required this.onMinus,
    required this.onTrash,
    required this.onOpenItem,
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
            onTap: () => onOpenItem(it),
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
  final _PItem item;
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

  static const Color border = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.description,
                textAlign: TextAlign.left,
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
                  ? const Text('—',
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 18,
                          fontWeight: FontWeight.w900))
                  : Text(
                      'د.ل ${item.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 18,
                          fontWeight: FontWeight.w900),
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
                )
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

class _CartThumbFromCover extends StatelessWidget {
  final int count;
  final String coverUrl;

  const _CartThumbFromCover({
    required this.count,
    required this.coverUrl,
  });

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
            child:
                Container(color: Colors.white, child: _NetImage(url: coverUrl)),
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
                    fontFamily: 'Cairo',
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
      child: const Icon(Icons.location_on_outlined,
          color: Colors.white, size: 20),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
  });

  static const Color orange = Color(0xFFF5A623);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: orange,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
            textDirection: TextDirection.ltr,
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