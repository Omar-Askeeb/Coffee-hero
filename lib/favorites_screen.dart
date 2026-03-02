import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'services/local_favorites.dart';
import 'services/firestore_products.dart';
import 'product_details_screen.dart';

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

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  static const Color orange = Color(0xFFF5A623);
  static const Color border = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    LocalFavorites.instance.init();
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'المفضلة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black), // ✅ عكس + لون أسود
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: AnimatedBuilder(
          animation: LocalFavorites.instance,
          builder: (context, _) {
            final favIds = LocalFavorites.instance.allIds.toSet();

            if (favIds.isEmpty) {
              return const Center(
                child: Text(
                  'ما عندكش عناصر في المفضلة حالياً',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF8A8A8A),
                  ),
                ),
              );
            }

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirestoreProductsServiceClient.instance.watchProducts(),
              builder: (context, snap) {
                final docs = snap.data?.docs ?? const [];
                if (snap.connectionState == ConnectionState.waiting && docs.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final all = docs.map(_docToItem).toList(growable: false);
                final favItems = all.where((p) => favIds.contains(p.id)).toList();

                if (favItems.isEmpty) {
                  return const Center(
                    child: Text(
                      'المفضلة عندك موجودة، لكن المنتجات مش لاقينها في الداتا (تأكد من IDs)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF8A8A8A),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                  itemCount: favItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    final it = favItems[i];

                    return InkWell(
                      onTap: () => _openDetails(it),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: border),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 12,
                              offset: Offset(0, 6),
                              color: Color(0x11000000),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            // صورة
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: _NetImage(url: it.imageUrl, w: 86, h: 86),
                            ),
                            const SizedBox(width: 12),

                            // نصوص
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    it.title,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
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
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: Color(0xFF7A869A),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'د.ل ${it.price.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 10),

                            // زر حذف من المفضلة
                            IconButton(
                              onPressed: () => LocalFavorites.instance.toggle(it.id),
                              icon: const Icon(Icons.favorite, color: orange),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NetImage extends StatelessWidget {
  final String url;
  final double w;
  final double h;
  const _NetImage({required this.url, required this.w, required this.h});

  @override
  Widget build(BuildContext context) {
    final u = url.trim();
    if (u.isEmpty) {
      return Container(
        width: w,
        height: h,
        color: const Color(0xFFF2F2F2),
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined, color: Color(0xFFB0B0B0)),
      );
    }

    return Image.network(
      u,
      width: w,
      height: h,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          width: w,
          height: h,
          color: const Color(0xFFF2F2F2),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        width: w,
        height: h,
        color: const Color(0xFFF2F2F2),
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined, color: Color(0xFFB0B0B0)),
      ),
    );
  }
}
