import 'package:flutter/material.dart';
import '../app_routes.dart';

Future<void> showGuestGateSheet(BuildContext context) async {
  await showModalBottomSheet(
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
                height: 150,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 10),
              const Text(
                'مرحباً بك ضيفنا العزيز!',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 6),
              const Text(
                'سجّل الآن لتتمكن من إضافة المنتجات وإتمام الطلب.',
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pushNamed(AppRoutes.login);
                  },
                  child: const Text(
                    'تسجيل الدخول',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              SizedBox(
                height: 52,
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: const BorderSide(color: Color(0xFFD9D9D9)),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pushNamed(AppRoutes.register);
                  },
                  child: const Text(
                    'إنشاء حساب',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'لاحقاً',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
