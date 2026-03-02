import 'package:flutter/material.dart';
import 'employee_models.dart';

class EmployeeCardWidget extends StatelessWidget {
  final EmployeeModel employee;
  final VoidCallback onTap;

  const EmployeeCardWidget({
    super.key,
    required this.employee,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0F0F0)),
            boxShadow: const [
              BoxShadow(
                blurRadius: 12,
                offset: Offset(0, 6),
                color: Color(0x11000000),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8C7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFFF5A623),
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      employee.phone,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        employee.role,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFF5A623),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: Colors.black45),
            ],
          ),
        ),
      ),
    );
  }
}
