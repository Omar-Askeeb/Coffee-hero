import 'package:flutter/material.dart';

import '../app_routes.dart';
import 'auth_service.dart';
import 'auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await AuthService.instance.signUpOwner(
        cafeName: _name.text,
        phone: _phone.text,
        password: _pass.text,
      );

      if (!mounted) return;

      /// 🔥 بعد إنشاء الحساب نفتح صفحة تحديد الموقع
      final addedLocation =
          await Navigator.of(context).pushNamed(AppRoutes.mapPicker);

      /// بعد ما المستخدم يحدد موقعه يدخل للتطبيق
      if (addedLocation == true) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      }
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
            const SizedBox(height: 28),
            const AuthHeader(
              title: 'إنشاء حساب',
              subtitle: 'أدخل بياناتك لإنشاء حساب جديد',
            ),
            const SizedBox(height: 22),

            AuthInputField(
              controller: _name,
              hintText: 'اسم المقهى',
              keyboardType: TextInputType.text,
              left: const Icon(Icons.storefront_outlined, size: 20),
              validator: (v) {
                if ((v ?? '').trim().isEmpty) return 'أدخل اسم المقهى';
                return null;
              },
            ),
            const SizedBox(height: 12),

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
            const SizedBox(height: 12),

            AuthInputField(
              controller: _pass,
              hintText: 'كلمة المرور',
              keyboardType: TextInputType.visiblePassword,
              obscureText: true,
              left: const Icon(Icons.lock_outline, size: 20),
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.isEmpty) return 'أدخل كلمة المرور';
                if (s.length < 6) return 'كلمة المرور قصيرة';
                return null;
              },
            ),

            const SizedBox(height: 12),

            AuthInputField(
              controller: _pass2,
              hintText: 'تأكيد كلمة المرور',
              keyboardType: TextInputType.visiblePassword,
              obscureText: true,
              left: const Icon(Icons.lock_outline, size: 20),
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.isEmpty) return 'أكد كلمة المرور';
                if (s != _pass.text.trim()) return 'كلمتا المرور غير متطابقتين';
                return null;
              },
            ),

            const SizedBox(height: 18),
            PrimaryButton(
              label: 'إنشاء الحساب',
              isLoading: _loading,
              onPressed: _register,
            ),

            const SizedBox(height: 12),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed(AppRoutes.login),
                child: const Text('لديك حساب؟ تسجيل الدخول'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
