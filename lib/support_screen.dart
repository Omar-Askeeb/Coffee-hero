// lib/support_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_routes.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const Color orange = Color(0xFFF5A623);
  static const String driverPhone = '0921511510';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black), // ✅ قلبنا السهم
          onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.profile),
        ),
        title: const Text(
          'دعم السائق',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F8),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  // Left side icons (visual only)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.phone, color: Colors.black),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        Text('الرقم', style: TextStyle(fontWeight: FontWeight.w900)),
                        SizedBox(height: 4),
                        Text(driverPhone, style: TextStyle(color: Color(0xFF666666))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _CopyButton(textToCopy: driverPhone),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.support_agent, size: 110, color: Colors.black),
                    SizedBox(height: 14),
                    Text('دعم السائق', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    SizedBox(height: 8),
                    Text(
                      'نحن دائماً في خدمتك، لا تتردد بالتواصل معنا',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF666666)),
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

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.textToCopy});
  final String textToCopy;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: textToCopy));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم نسخ الرقم')),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'COPY',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
