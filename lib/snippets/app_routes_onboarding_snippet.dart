// انسخ/ادمج هذا داخل app_routes.dart عندك
// 1) أضف routes:
class AppRoutes {
  static const splash = '/splash';
  static const welcome = '/welcome';

  static const login = '/login';
  static const register = '/register';

  // عدّل home حسب مشروعك
  static const home = '/home';
}

// 2) داخل onGenerateRoute أضف:
// case AppRoutes.splash:
//   return MaterialPageRoute(builder: (_) => const SplashScreen());
// case AppRoutes.welcome:
//   return MaterialPageRoute(builder: (_) => const WelcomeScreen());
