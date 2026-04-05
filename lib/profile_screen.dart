import 'package:flutter/material.dart';

import 'app_routes.dart';
import 'bottom_bar_rtl.dart';
import 'auth/auth_service.dart';
import 'favorites_screen.dart'; // ✅ NEW

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color orange = Color(0xFFF5A623);

  void _onBottomTap(BuildContext context, int i) {
    final route = AppRoutes.forIndex(i);
    if (route == AppRoutes.profile) return;
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;

    return Scaffold(
      bottomNavigationBar: BottomBarRTL(
        currentIndex: 4,
        onTap: (i) => _onBottomTap(context, i),
      ),
      appBar: AppBar(
        title: const Text('', style: TextStyle(fontWeight: FontWeight.w900)),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: auth,
        builder: (context, _) {
          final user = auth.user;
          final isGuest = auth.isGuest;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            children: [
              const SizedBox(height: 0),
              Row(
                children: [
                  _ProfileAvatar(avatarPath: user?.avatarPath),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isGuest ? 'ضيف' : (user?.cafeName ?? ''),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isGuest ? '' : (user?.phone ?? ''),
                          style: const TextStyle(color: Color(0xFF777777)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              _MenuItem(
                icon: Icons.favorite,
                title: 'المفضلة لديك',
                stroke: true, // ✅ ستروك
                onTap: () {
                  if (isGuest) {
                    Navigator.of(context).pushNamed(AppRoutes.login);
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                  );
                },
              ),

              _MenuItem(
                icon: Icons.location_on,
                title: 'عناويني',
                stroke: true, // ✅ ستروك
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.locations),
              ),
              _MenuItem(
                icon: Icons.support_agent,
                title: 'اتصال خدمة العملاء',
                stroke: true, // ✅ ستروك
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.support),
              ),
              _MenuItem(
                icon: Icons.account_balance_wallet,
                title: 'المحفظة',
                stroke: true, // ✅ ستروك
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.wallet),
              ),
              _MenuItem(
                icon: Icons.shopping_bag,
                title: 'المشتريات',
                stroke: true, // ✅ ستروك
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.purchases),
              ),

              const SizedBox(height: 10),
              if (!isGuest)
                _MenuItem(
                  icon: Icons.delete_forever,
                  title: 'حذف الحساب',
                  danger: true,
                  stroke: false,
                  onTap: () => _showDeleteConfirmation(context, auth),
                ),

              _MenuItem(
                icon: Icons.logout,
                title: 'تسجيل خروج',
                danger: true,
                stroke: false, // ❌ بدون ستروك (زي ما طلبت)
                onTap: () async {
                  await auth.signOut();
                  if (!context.mounted) return;
                  Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.welcome, (r) => false);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الحساب', textAlign: TextAlign.right),
        content: const Text(
          'هل أنت متأكد من حذف الحساب نهائياً؟ لا يمكن التراجع عن هذه العملية وسيتم مسح جميع بياناتك.',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // إغلاق الدايلوج
              try {
                // عرض مؤشر تحميل بسيط
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator(color: orange)),
                );

                await auth.deleteAccount();

                if (!context.mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.welcome, (r) => false);
              } catch (e) {
                if (!context.mounted) return;
                Navigator.pop(context); // إغلاق مؤشر التحميل
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString(), textAlign: TextAlign.right),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('حذف الآن', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String? avatarPath;
  const _ProfileAvatar({required this.avatarPath});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 84,
        height: 84,
        color: const Color(0xFFF2F2F2),
        alignment: Alignment.center,
        child: const Icon(Icons.person, size: 40, color: Color(0xFFB0B0B0)),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;

  /// ✅ جديد: نخلي الستروك اختياري
  final bool stroke;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
    this.stroke = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.red : Colors.black;

    final tile = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.right,
                style: TextStyle(fontWeight: FontWeight.w800, color: color),
              ),
            ),
          ],
        ),
      ),
    );

    if (!stroke) return tile;

    // ✅ ستروك فقط (رمادي + زوايا ناعمة) بدون تغيير باقي التصميم
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
      ),
      child: tile,
    );
  }
}
