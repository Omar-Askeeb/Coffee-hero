import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineGate extends StatefulWidget {
  final Widget child;
  const OfflineGate({super.key, required this.child});

  @override
  State<OfflineGate> createState() => _OfflineGateState();
}

class _OfflineGateState extends State<OfflineGate> {
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _checkInternet();
    _sub = Connectivity()
        .onConnectivityChanged
        .listen((_) => _checkInternet());
  }

  Future<void> _checkInternet() async {
    final hasNet = await _hasInternet();
    if (!mounted) return;
    setState(() => _offline = !hasNet);
  }

  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('example.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_offline) return const OfflineScreen();
    return widget.child;
  }
}

class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key});

  static const Color orange = Color(0xFFF5A623);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                // 🔶 أيقونة داخل دائرة
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: orange.withOpacity(.12),
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    size: 50,
                    color: orange,
                  ),
                ),

                const SizedBox(height: 28),

                // 🔥 العنوان
                const Text(
                  "لا يوجد اتصال بالإنترنت",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo',
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "تأكد من اتصالك بالشبكة وحاول مرة أخرى.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontFamily: 'Cairo',
                  ),
                ),

                const SizedBox(height: 30),

                // 🟧 زر إعادة المحاولة
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      // فقط يعيد بناء الشاشة
                      (context as Element).markNeedsBuild();
                    },
                    child: const Text(
                      "إعادة المحاولة",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Cairo',
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // 🟠 مؤشر بسيط
                const Text(
                  "سيتم إعادة الاتصال تلقائيًا عند توفر الشبكة",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black38,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}