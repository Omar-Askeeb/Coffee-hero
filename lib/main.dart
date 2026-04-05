// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

// ✅ NEW: Offline Gate
import 'offline/offline_gate.dart';
import 'firebase_options.dart';

import 'app_routes.dart';
import 'cart_screen.dart';
import 'delivered_screen.dart';
import 'employees_screen.dart';
import 'home_screen.dart';
import 'orders_store.dart';
import 'profile_screen.dart';
import 'invoice_screen.dart';
import 'map_picker_screen.dart';
import 'locations_screen.dart';
import 'purchases_screen.dart';
import 'wallet_screen.dart';
import 'favorites_screen.dart';
import 'auth/auth_service.dart';
import 'favorites_store.dart';
import 'search_screen.dart';
import 'track_order_screen.dart';
import 'support_screen.dart';
import 'chat_screen.dart';

// ✅ طلبات المستخدم
import 'orders_screen.dart';

// Dashboard orders
import 'package:app_for_me/dashboard/orders/ordersd_screen.dart';
import 'package:app_for_me/dashboard/orders/order_details_screen.dart';

// Auth / Onboarding
import 'welcome/welcome_screen.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'auth/forgot_phone_screen.dart';
import 'auth/reset_password_screen.dart';

// Employees
import 'employees/employee_register_screen.dart';
import 'employees/employee_pending_orders_screen.dart';

/// ✅ Debug: طباعة FCM Token في الكونسل
Future<void> debugPrintFcmToken() async {
  try {
    // iOS: عرض الإشعارات في الـ Foreground
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await FirebaseMessaging.instance.getToken();
    debugPrint('FCM TOKEN => $token');
  } catch (e) {
    debugPrint('FCM TOKEN ERROR => $e');
  }
}

Future<void> _initOneSignal() async {
  // ✅ مهم: فعّل logs في وضع التطوير
  if (kDebugMode) {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  }

  // 🔴 حط App ID الحقيقي من OneSignal
  OneSignal.initialize("ONESIGNAL_APP_ID");

  // ✅ Listener: لو وصل إشعار والتطبيق مفتوح
  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    // نخلي الإشعار يظهر عادي
    event.notification.display();
  });

  // ✅ Listener: لما المستخدم يضغط على الإشعار
  OneSignal.Notifications.addClickListener((event) {
    final data = event.notification.additionalData;
    debugPrint('OneSignal CLICK => data: $data');
  });

  // ✅ طلب صلاحية الإشعارات
  final accepted = await OneSignal.Notifications.requestPermission(true);
  debugPrint('OneSignal Permission accepted? => $accepted');

  // ✅ اطبع معلومات الاشتراك (لو الجهاز تسجّل)
  try {
    final subId = OneSignal.User.pushSubscription.id; // subscription/player id
    final token = OneSignal.User.pushSubscription.token; // push token
    debugPrint('OneSignal Subscription ID => $subId');
    debugPrint('OneSignal Push Token => $token');
  } catch (e) {
    debugPrint('OneSignal Subscription read ERROR => $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // ✅ اطبع FCM Token (للتأكد إن FCM شغال)
    await debugPrintFcmToken();
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  // ✅ OneSignal
  try {
    await _initOneSignal();
  } catch (e) {
    debugPrint('OneSignal initialization error: $e');
  }

  await CartStore.instance.restore();
  await AuthService.instance.restore();
  await FavoritesStore.instance.restore();
  await OrdersStore.instance.restore();

  runApp(const MyApp());
}

/// ✅ هذا Widget صغير يربط OneSignal بالزبون تلقائيًا
/// - لو user مسجل: OneSignal.login(phone)
/// - لو guest/خارج: OneSignal.logout()
class OneSignalIdentityBinder extends StatefulWidget {
  final Widget child;
  const OneSignalIdentityBinder({super.key, required this.child});

  @override
  State<OneSignalIdentityBinder> createState() => _OneSignalIdentityBinderState();
}

class _OneSignalIdentityBinderState extends State<OneSignalIdentityBinder> {
  String _lastExternalId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  void _sync() {
    try {
      final isGuest = AuthService.instance.isGuest;
      final user = AuthService.instance.currentUser;

      // ✅ external_id = phone
      final phone = (user == null) ? '' : (user.phone ?? '').toString().trim();

      if (isGuest || phone.isEmpty) {
        if (_lastExternalId.isNotEmpty) {
          OneSignal.logout();
          _lastExternalId = '';
          debugPrint('OneSignal logout (guest)');
        }
        return;
      }

      if (phone != _lastExternalId) {
        OneSignal.login(phone);
        _lastExternalId = phone;
        debugPrint('OneSignal login => external_id: $phone');
      }
    } catch (e) {
      debugPrint('OneSignal sync ERROR => $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthService.instance,
      builder: (context, _) {
        _sync();
        return widget.child;
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static PageRoute<T> _instantRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  static PageRoute<T> _authSlideRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (_, animation, __, child) {
        final inTween = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeIn));

        final outTween = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(1, 0),
        ).chain(CurveTween(curve: Curves.easeIn));

        final position = animation.status == AnimationStatus.reverse
            ? animation.drive(outTween)
            : animation.drive(inTween);

        return SlideTransition(position: position, child: child);
      },
    );
  }

  static bool _isAuthRoute(String name) {
    return name == AppRoutes.welcome ||
        name == AppRoutes.login ||
        name == AppRoutes.register ||
        name == AppRoutes.forgotPhone ||
        name == AppRoutes.resetPassword;
  }

  @override
  Widget build(BuildContext context) {
    final startRoute =
        (AuthService.instance.currentUser != null || AuthService.instance.isGuest)
            ? AppRoutes.home
            : AppRoutes.welcome;

    return OneSignalIdentityBinder(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Cairo',
          scaffoldBackgroundColor: Colors.white,
          useMaterial3: false,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
              fontSize: 18,
            ),
            iconTheme: IconThemeData(color: Colors.black),
          ),
        ),
        builder: (context, child) {
          final mq = MediaQuery.of(context);

          // ✅ Directionality + MediaQuery موجودين دائمًا قبل OfflineGate
          // ✅ OfflineGate الآن داخل MaterialApp لتفادي خطأ Directionality نهائيًا
          return MediaQuery(
            data: mq.copyWith(textScaleFactor: 1.0),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: OfflineGate(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          );
        },
        initialRoute: startRoute,
        onGenerateRoute: (settings) {
          final name = settings.name ?? AppRoutes.home;

          PageRoute<T> r<T>(Widget page) {
            return _isAuthRoute(name)
                ? _authSlideRoute<T>(page)
                : _instantRoute<T>(page);
          }

          switch (name) {
            case AppRoutes.welcome:
              return r<void>(const WelcomeScreen());

            case AppRoutes.login:
              return r<void>(const LoginScreen());

            case AppRoutes.register:
              return r<void>(const RegisterScreen());

            case AppRoutes.forgotPhone:
              return r<void>(const ForgotPhoneScreen());

            case AppRoutes.resetPassword:
              return r<void>(const ResetPasswordScreen());

            case AppRoutes.home:
              return r<void>(const HomeScreen());

            case AppRoutes.orders:
              return r<void>(const OrdersScreen());

            case AppRoutes.employees:
              return r<void>(const EmployeesScreen());

            case AppRoutes.employeeRegister:
              return r<void>(const EmployeeRegisterScreen());

            case AppRoutes.employeePendingOrders:
              final arg = settings.arguments;
              if (arg is Map<String, dynamic>) {
                final uid = (arg['employeeUid'] ?? '').toString();
                final n = (arg['employeeName'] ?? '').toString();
                if (uid.isNotEmpty) {
                  return r<void>(EmployeePendingOrdersScreen(
                    employeeUid: uid,
                    employeeName: n.isEmpty ? 'موظف' : n,
                  ));
                }
              }
              return r<void>(
                const Scaffold(
                  body: Center(child: Text('بيانات الموظف غير موجودة')),
                ),
              );

            case AppRoutes.search:
              return r<void>(const SearchScreen());

            case AppRoutes.profile:
              return r<void>(const ProfileScreen());

            case AppRoutes.orderDetails:
              final arg = settings.arguments;
              final order = (arg is Map<String, dynamic>)
                  ? arg
                  : <String, dynamic>{
                      'id': (arg is String) ? arg : '—',
                      'date': '',
                      'store': '—',
                      'customer': '—',
                      'phone': '—',
                      'email': '—',
                      'address': '—',
                      'items': [
                        {'name': 'لا توجد عناصر', 'qty': 0, 'unitPrice': 0.0},
                      ],
                      'discount': 0.0,
                      'coupon': 0.0,
                      'vat': 0.0,
                      'deliveryFee': 0.0,
                    };
              return r<void>(OrderDetailsScreen(order: order));

            case AppRoutes.trackOrder:
              final orderId = settings.arguments as String?;
              return r<void>(TrackOrderScreen(orderId: orderId ?? ''));

            case AppRoutes.delivered:
              final orderId = settings.arguments as String?;
              return r<void>(DeliveredScreen(orderId: orderId ?? ''));

            case AppRoutes.support:
              return r<void>(const SupportScreen());

            case AppRoutes.chat:
              return r<void>(const ChatScreen());

            case AppRoutes.favorites:
              return r<void>(const FavoritesScreen());

            case AppRoutes.wallet:
              return r<void>(const WalletScreen());

            case AppRoutes.purchases:
              return r<void>(const PurchasesScreen());

            case AppRoutes.locations:
              return r<void>(const LocationsScreen());

            case AppRoutes.mapPicker:
              return r<void>(const MapPickerScreen());

            case AppRoutes.invoice:
              final orderId = settings.arguments as String?;
              return r<void>(InvoiceScreen(orderId: orderId ?? ''));

            default:
              return r<void>(const HomeScreen());
          }
        },
      ),
    );
  }
}