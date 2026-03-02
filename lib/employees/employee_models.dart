// lib/employees/employee_models.dart
class EmployeeModel {
  final String? uid;
  final String name;
  final String phone;
  final String role;

  const EmployeeModel({
    this.uid,
    required this.name,
    required this.phone,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'phone': phone,
        'role': role,
      };

  factory EmployeeModel.fromJson(Map<String, dynamic> m) => EmployeeModel(
        uid: (m['uid'] as String?),
        name: (m['name'] ?? '') as String,
        phone: (m['phone'] ?? '') as String,
        role: (m['role'] ?? 'employee') as String,
      );

  factory EmployeeModel.fromFirestore(String id, Map<String, dynamic> d) => EmployeeModel(
        uid: id,
        name: (d['name'] ?? '') as String,
        phone: (d['phone'] ?? '') as String,
        role: (d['role'] ?? 'employee') as String,
      );
}
