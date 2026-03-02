// lib/employees/pending_employee_order.dart

class PendingEmployeeOrder {
  final String id;
  final String title;
  final String status; // مثال: "في انتظار الموافقة"
  final List<PendingOrderItem> items;

  const PendingEmployeeOrder({
    required this.id,
    required this.title,
    required this.status,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'status': status,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory PendingEmployeeOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List? ?? const []);
    return PendingEmployeeOrder(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      status: (json['status'] ?? 'في انتظار الموافقة').toString(),
      items: rawItems
          .map((e) =>
              PendingOrderItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

class PendingOrderItem {
  final String productId;
  final String name;
  final double price;
  final int qty;

  const PendingOrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.qty,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'price': price,
        'qty': qty,
      };

  factory PendingOrderItem.fromJson(Map<String, dynamic> json) {
    return PendingOrderItem(
      productId: (json['productId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
      qty: (json['qty'] is num) ? (json['qty'] as num).toInt() : 1,
    );
  }
}
