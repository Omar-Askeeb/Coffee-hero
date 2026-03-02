// lib/app_routes.dart
class AppRoutes {
  const AppRoutes._();

  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';

  static const String forgotPhone = '/forgot-phone';
  static const String resetPassword = '/reset-password';

  static const String home = '/home';
  static const String orders = '/orders';
  static const String employees = '/employees';
  static const String search = '/search';
  static const String profile = '/profile';

  static const String favorites = '/favorites';
  static const String wallet = '/wallet';
  static const String purchases = '/purchases';
  static const String locations = '/locations';
  static const String mapPicker = '/map_picker';
  static const String invoice = '/invoice';

  static const String orderDetails = '/order_details';
  static const String trackOrder = '/track_order';
  static const String delivered = '/delivered';

  static const String support = '/support';
  static const String chat = '/chat';

  // =========================
  // Employees (NEW)
  // =========================
  static const String employeeRegister = '/employee-register';
  static const String employeePendingOrders = '/employee-pending-orders';

  static String forIndex(int index) {
    switch (index) {
      case 0:
        return home;
      case 1:
        return orders;
      case 2:
        return employees;
      case 3:
        return search;
      case 4:
        return profile;
      default:
        return home;
    }
  }
}
