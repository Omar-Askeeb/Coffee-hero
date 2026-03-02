import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'employee_models.dart';

class EmployeeStore {
  EmployeeStore._();
  static final EmployeeStore instance = EmployeeStore._();

  static const _kEmployeeKey = 'employee_saved_v1';

  Future<void> saveEmployee(EmployeeModel employee) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(employee.toJson());
    await prefs.setString(_kEmployeeKey, jsonStr);
  }

  Future<EmployeeModel?> loadEmployee() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_kEmployeeKey);
    if (jsonStr == null || jsonStr.isEmpty) return null;

    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return EmployeeModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearEmployee() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kEmployeeKey);
  }
}
