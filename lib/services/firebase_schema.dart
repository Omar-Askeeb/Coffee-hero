/// lib/services/firebase_schema.dart
///
/// هذا الملف يعرّف أسماء الـ collections والمسارات اللي بنستخدموها
/// لما نربط الحسابات (أصحاب المقاهي + الموظفين) على Firebase.
///
/// ملاحظة: هذا مجرد “ثوابت مسارات” — ما فيهش منطق ربط فعلي.
class FirebaseSchema {
  FirebaseSchema._();

  /// أصحاب المقاهي (Customers = Owners)
  static const String customers = 'customers';

  /// تحت كل صاحب مقهى: الموظفين
  static const String employees = 'employees';

  /// تحت كل صاحب مقهى: مسودات/طلبات مجهزة من الموظف
  static const String draftOrders = 'draftOrders';

  /// تحت كل صاحب مقهى: الطلبات الرسمية
  static const String orders = 'orders';

  /// ملف تعريف الموظف (للدخول بسرعة ومعرفة ownerUid)
  /// employeeProfiles/{employeeUid}
  static const String employeeProfiles = 'employeeProfiles';

  static String customerDoc(String customerUid) => '$customers/$customerUid';

  static String employeeDoc(String customerUid, String employeeUid) =>
      '$customers/$customerUid/$employees/$employeeUid';

  static String employeeProfileDoc(String employeeUid) =>
      '$employeeProfiles/$employeeUid';

  static String draftOrderDoc(String customerUid, String draftId) =>
      '$customers/$customerUid/$draftOrders/$draftId';

  static String orderDoc(String customerUid, String orderId) =>
      '$customers/$customerUid/$orders/$orderId';
}
