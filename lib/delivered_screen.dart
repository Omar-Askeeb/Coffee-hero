// lib/delivered_screen.dart
import 'package:flutter/material.dart';

import 'app_routes.dart';
import 'support_screen.dart';

class DeliveredScreen extends StatelessWidget {
  const DeliveredScreen({super.key, required this.orderId});
  final String orderId;

  static const Color orange = Color(0xFFF5A623);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              child: Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.of(context).pushReplacementNamed(AppRoutes.orders),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.close, color: orange, size: 22),
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SupportScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: orange,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text(
                        'مساعدة',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'أرجوك استمتع بخدماتنا!',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 22),
              child: Text(
                '''لقد بذل المندوبين والعاملين بالمكتب جهودهم
السحرية من أجلك (للاتصال الطلبية) خذ دقيقة واحدة
وقول للمندوب ينساه.. شكراً لك.''',
                style: TextStyle(color: Color(0xFF666666), height: 1.6, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
            const Spacer(),
            // Illustration (simple)
            SizedBox(
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F8),
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  const Icon(Icons.shopping_bag_outlined, size: 92, color: Colors.black),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.orders),
                  child: const Text(
                    'انتهت المهمة !',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
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
