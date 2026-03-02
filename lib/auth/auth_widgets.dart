import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../welcome/welcome_screen.dart';

/// Auth UI helpers only (no auth logic).
class AuthTheme {
  const AuthTheme._();

  static const Color primary = Color(0xFFFFA403);
  static const Color border = Color(0xFFE6E6E6);
  static const Color hint = Color(0xFF9E9E9E);
  static const Color fieldBg = Colors.white; // ✅ أبيض
  static const Color subText = Color(0xFF6A6A6A);
  static const Color softGreyButton = Color(0xFFEFEFF5);
}

TextStyle _cairo(TextStyle base) => base.copyWith(fontFamily: 'Cairo');

/// Page shell that matches the provided auth designs.
///
/// - White background
/// - Back arrow at top-right
/// - Centered content with generous whitespace
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.child,
    this.showBack = true,
    this.onBack,
  });

  final Widget child;
  final bool showBack;
  final VoidCallback? onBack;

  void _defaultBack(BuildContext context) {
    // ✅ دايمًا يرجع لـ Welcome وبدون أنميشن
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const WelcomeScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Stack(
            children: [
              // ✅ نزّلنا المحتوى لتحت عشان ما يغطي السهم
              Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 70, 24, 24),
                  child: child,
                ),
              ),

              // ✅ السهم بمنطقة لمس كبيرة
              if (showBack)
                PositionedDirectional(
                  top: 6,
                  end: 6,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: onBack ?? () => _defaultBack(context),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.arrow_forward_ios, size: 20),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    this.assetPath,
    this.leading,
    required this.title,
    this.subtitle,
  });

  final String? assetPath;
  final Widget? leading;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (assetPath != null) ...[
          Image.asset(assetPath!, width: 86, height: 86),
          const SizedBox(height: 14),
        ] else if (leading != null) ...[
          SizedBox(width: 86, height: 86, child: Center(child: leading)),
          const SizedBox(height: 14),
        ],
        Text(
          title,
          style: _cairo(
            const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: _cairo(
              const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AuthTheme.subText,
                fontWeight: FontWeight.w700,
              ),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AuthTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: _cairo(
            const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AuthTheme.softGreyButton,
          foregroundColor: Colors.black,
          elevation: 0,
          textStyle: _cairo(
            const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

class AuthInputField extends StatefulWidget {
  const AuthInputField({
    super.key,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.left,
    this.onLeftTap,
    this.rightText,
    this.validator,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? left;
  final VoidCallback? onLeftTap;
  final String? rightText;
  final String? Function(String?)? validator;

  @override
  State<AuthInputField> createState() => _AuthInputFieldState();
}

class _AuthInputFieldState extends State<AuthInputField> {
  late final FocusNode _focus;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode();
    _focus.addListener(() {
      if (!mounted) return;
      setState(() => _focused = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Stroke رمادي، وعند الفوكس برتقالي
    final borderColor = _focused ? AuthTheme.primary : const Color(0xFFD9D9D9);

    return Directionality(
      // Keep icon on the left & country code on the right.
      textDirection: TextDirection.ltr,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        height: 52,
        decoration: BoxDecoration(
          color: AuthTheme.fieldBg, // ✅ أبيض
          border: Border.all(color: borderColor, width: 1.2),
          borderRadius: BorderRadius.circular(14), // ✅ شكل أقرب لتصميمك
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 14),
            if (widget.left != null) ...[
              SizedBox(
                width: 22,
                height: 22,
                child: Center(
                  child: widget.onLeftTap == null
                      ? widget.left
                      : InkWell(onTap: widget.onLeftTap, child: widget.left),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: TextFormField(
                  focusNode: _focus,
                  controller: widget.controller,
                  keyboardType: widget.keyboardType,
                  obscureText: widget.obscureText,
                  validator: widget.validator,
                  textAlign: TextAlign.right,
                  textAlignVertical: TextAlignVertical.center, // ✅ يصلّح مشكلة ارتفاع النص
                  maxLines: 1,
                  cursorColor: AuthTheme.primary,
                  style: _cairo(
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true, // ✅ يخلي الحقل متوازن داخل Container
                    // ✅ Padding ثابت يضمن أن النص والحينت يكونوا في النص
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 0,
                    ),
                    hintText: widget.hintText,
                    hintStyle: _cairo(
                      const TextStyle(
                        color: AuthTheme.hint,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.rightText != null) ...[
              Container(width: 1, height: 28, color: const Color(0xFFD9D9D9)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  widget.rightText!,
                  style: _cairo(const TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class InlineLink extends StatelessWidget {
  const InlineLink({
    super.key,
    required this.label,
    required this.onTap,
    this.color = const Color(0xFFE53935),
    this.underline = true,
    this.fontWeight = FontWeight.w800,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool underline;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(
        label,
        style: _cairo(
          TextStyle(
            color: color,
            decoration: underline ? TextDecoration.underline : TextDecoration.none,
            fontWeight: fontWeight,
          ),
        ),
      ),
    );
  }
}

/// OTP input that looks like the provided designs (5 separated boxes).
class AuthOtpField extends StatefulWidget {
  const AuthOtpField({
    super.key,
    required this.controller,
    this.length = 5,
    this.validator,
  });

  final TextEditingController controller;
  final int length;
  final String? Function(String?)? validator;

  @override
  State<AuthOtpField> createState() => _AuthOtpFieldState();
}

class _AuthOtpFieldState extends State<AuthOtpField> {
  late final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onText);
  }

  @override
  void didUpdateWidget(covariant AuthOtpField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onText);
      widget.controller.addListener(_onText);
    }
  }

  void _onText() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final digits = widget.controller.text.replaceAll(RegExp(r'[^0-9]'), '');

    return Stack(
      children: [
        GestureDetector(
          onTap: () => FocusScope.of(context).requestFocus(_focus),
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD9D9D9), width: 1.2),
            ),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: List.generate(widget.length, (i) {
                  final ch = i < digits.length ? digits[i] : '';
                  return Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Center(
                            child: Text(
                              ch,
                              style: _cairo(
                                const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                        ),
                        if (i != widget.length - 1)
                          Container(width: 1, height: 26, color: const Color(0xFFD7D7DD)),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
        Opacity(
          opacity: 0,
          child: TextFormField(
            focusNode: _focus,
            controller: widget.controller,
            keyboardType: TextInputType.number,
            maxLength: widget.length,
            validator: widget.validator,
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}

void showAuthErrorSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        textDirection: TextDirection.rtl,
        style: _cairo(const TextStyle()),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
