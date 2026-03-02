import 'package:flutter/material.dart';

class GuestRestrictedScreen extends StatelessWidget {
  const GuestRestrictedScreen({
    super.key,
    this.featureName = 'هذه الميزة',
  });

  final String featureName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مقيد للزائر')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 90),
              const SizedBox(height: 16),
              Text(
                '$featureName متاحة للمسجلين فقط',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              const Text(
                'سجّل الدخول أو أنشئ حسابًا للاستفادة من جميع المميزات.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamed('/login'),
                  child: const Text('تسجيل الدخول'),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('رجوع'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
