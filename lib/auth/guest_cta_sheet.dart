import 'package:flutter/material.dart';

import '../app_routes.dart';
import 'ui_tokens.dart';

class GuestCtaSheet extends StatelessWidget {
  const GuestCtaSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const GuestCtaSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFB0BEC5),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FB),
                borderRadius: BorderRadius.circular(22),
              ),
              alignment: Alignment.center,
              child: Image.network(
                'https://images.unsplash.com/photo-1521791136064-7986c2920216?auto=format&fit=crop&w=900&q=80',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 14),
            const Text('مرحباً بك صديقي العزيز!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text(
              'سجّل الآن لتتمكن من الوصول لجميع مزايا وعروض التطبيق.',
              style: TextStyle(fontSize: 13, color: UiTokens.subText, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 54,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: UiTokens.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed(AppRoutes.welcome);
                },
                child: const Text('تسجيل الدخول / إنشاء حساب'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
