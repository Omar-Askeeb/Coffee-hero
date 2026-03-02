import 'package:flutter/material.dart';

import '../app_routes.dart';
import 'auth_service.dart';
import 'auth_widgets.dart';

class ForgotPhoneScreen extends StatefulWidget {
  const ForgotPhoneScreen({super.key});

  @override
  State<ForgotPhoneScreen> createState() => _ForgotPhoneScreenState();
}

class _ForgotPhoneScreenState extends State<ForgotPhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phone.text.trim();

    setState(() => _loading = true);
    try {
      if (!mounted) return;

      // ✅ بدون OTP: ننقل مباشرة لصفحة تغيير كلمة المرور
      showAuthErrorSnack(context, 'اتصل بالدعم لكي تتمكن من استرجاع كلمه المرور');
    } on AuthException catch (e) {
      if (!mounted) return;
      showAuthErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBack: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),
            const AuthHeader(
              title: 'استرجاع كلمة المرور',
              subtitle: 'اكتب رقم الهاتف وغيّر كلمة المرور مباشرة',
            ),
            const SizedBox(height: 24),
            AuthInputField(
              controller: _phone,
              hintText: 'رقم الهاتف',
              keyboardType: TextInputType.phone,
              left: const Icon(Icons.smartphone, size: 20),
              rightText: '+218',
              validator: (v) {
                final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                if (digits.isEmpty) return 'أدخل رقم الهاتف';
                if (digits.length < 8) return 'رقم الهاتف غير صحيح';
                return null;
              },
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'متابعة',
              isLoading: _loading,
              onPressed: _send,
            ),
          ],
        ),
      ),
    );
  }
}
