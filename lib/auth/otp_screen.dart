import 'package:flutter/material.dart';

import '../app_routes.dart';
import 'auth_widgets.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otp = TextEditingController();
  bool _loading = false;

  static const String fixedOtp = '1234'; // ✅ OTP ثابت

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  Future<void> _verify(String phone, String mode) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final entered = _otp.text.trim();

      // ✅ تحقق ثابت: 1234 فقط
      if (entered != fixedOtp) {
        showAuthErrorSnack(context, 'الكود غير صحيح');
        return;
      }

      if (!mounted) return;

      // ✅ نسيان كلمة السر -> تغيير كلمة المرور
      if (mode == 'reset') {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.resetPassword,
          arguments: phone,
        );
        return;
      }

      // ✅ إنشاء حساب -> دخول للهوم مباشرة
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? const {};
    final phone = (args['phone'] ?? '') as String;
    final mode = (args['mode'] ?? 'register') as String;

    return AuthScaffold(
      showBack: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),
            const AuthHeader(
              title: 'كود التحقق',
              subtitle: 'اكتب الكود (1234) للمتابعة',
            ),
            const SizedBox(height: 24),
            AuthInputField(
              controller: _otp,
              hintText: 'الكود (1234)',
              keyboardType: TextInputType.number,
              left: const Icon(Icons.lock_outline, size: 20),
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.isEmpty) return 'أدخل الكود';
                if (s.length < 4) return 'الكود غير صحيح';
                return null;
              },
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'تأكيد',
              isLoading: _loading,
              onPressed: () => _verify(phone, mode),
            ),
          ],
        ),
      ),
    );
  }
}
