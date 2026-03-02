// lib/welcome/welcome_screen.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../auth/auth_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  Timer? _timer;

  static const _slides = <_Slide>[
    _Slide(
      imagePath:
          'assets/icons/bn.png',
      title: 'وفر وقتك',
      subtitle: 'بضاعتك توصل وانت في خدمتك',
    ),
    _Slide(
      imagePath: 'assets/icons/coffe.png',
      title: 'من ضغطت زر',
      subtitle: 'توصلك جميع المواد وانت في مكانك',
    ),
    _Slide(
      imagePath:
          'assets/icons/dish.png',
      title: 'مستلزماتك سهلت الوصول',
      subtitle: 'كل بضاعتك في جيبك ومن تلفونك',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      if (!_controller.hasClients) return;

      final next = (_index + 1) % _slides.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: PageView.builder(
                          controller: _controller,
                          onPageChanged: _onChanged,
                          itemCount: _slides.length,
                          itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _Dots(count: _slides.length, index: _index),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _PrimaryButton(
                  label: 'لدي حساب من قبل',
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.login),
                ),
                const SizedBox(height: 12),
                _SecondaryButton(
                  label: 'إنشاء حساب',
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.register),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () async {
                    await AuthService.instance.signInAsGuest();
                    if (!context.mounted) return;
                    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
                  },
                  child: const Text(
                    'الدخول كزائر',
                    style: TextStyle(
                      color: Color(0xFFF5A623),
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Cairo',
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

@immutable
class _Slide {
  const _Slide({
    required this.imagePath,
    required this.title,
    required this.subtitle,
  });

  final String imagePath;
  final String title;
  final String subtitle;
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final isNetwork = slide.imagePath.startsWith('http');

    final image = isNetwork
        ? Image.network(
            slide.imagePath,
            fit: BoxFit.cover, // ✅ يملأ كامل الودجت
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
            },
            errorBuilder: (context, error, stack) {
              return const Center(child: Icon(Icons.image_not_supported_outlined));
            },
          )
        : Image.asset(
            slide.imagePath,
            fit: BoxFit.cover, // ✅ يملأ كامل الودجت
          );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFFF5F7FB),
      ),
      clipBehavior: Clip.antiAlias, // ✅ يقص الصورة مع الحواف الدائرية
      child: Stack(
        children: [
          // ✅ الصورة تملأ كامل المساحة
          Positioned.fill(child: image),

          // ✅ طبقة تظليل خفيفة للنص
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  colors: [
                    Color(0xAA000000),
                    Color(0x00000000),
                  ],
                ),
              ),
            ),
          ),

          // ✅ النص فوق الصورة
          Positioned(
            left: 14,
            right: 14,
            bottom: 16,
            child: Column(
              children: [
                Text(
                  slide.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo',
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  slide.subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Cairo',
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  static const Color _orange = Color(0xFFFFA403);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 18 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: active ? _orange : const Color(0xFFCFD8DC),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  static const Color _orange = Color(0xFFFFA403);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _orange,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            fontFamily: 'Cairo',
          ),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  static const Color _greyButton = Color(0xFFEFEFF5);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _greyButton,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            fontFamily: 'Cairo',
          ),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
