// lib/order_models.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'services/firestore_orders.dart' as fs;

@immutable
class OrderLine {
  final String id;
  final String title;
  final String imageUrl;
  final double price;
  final int qty;

  const OrderLine({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.qty,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'imageUrl': imageUrl,
        'price': price,
        'qty': qty,
      };

  factory OrderLine.fromJson(Map<String, dynamic> json) {
    return OrderLine(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
      qty: (json['qty'] is num) ? (json['qty'] as num).toInt() : 1,
    );
  }
}

enum OrderStatus {
  pendingCompanyAccept,
  preparing,
  onTheWay,
  delivered,
  cancelled,
}

extension OrderStatusX on OrderStatus {
  String label({required bool compact}) {
    switch (this) {
      case OrderStatus.pendingCompanyAccept:
        // في نسخة Firestore نستخدمها كـ "قبول" (accepted) كبداية
        return compact ? 'قبول' : 'تم قبول الطلب';
      case OrderStatus.preparing:
        return compact ? 'تجهيز' : 'يتم تجهيز طلبك';
      case OrderStatus.onTheWay:
        return compact ? 'في الطريق' : 'المندوب في الطريق';
      case OrderStatus.delivered:
        return compact ? 'منتهي' : 'تم التسليم';
      case OrderStatus.cancelled:
        return compact ? 'ملغي' : 'تم الإلغاء';
    }
  }

  bool get isActive =>
      this != OrderStatus.delivered && this != OrderStatus.cancelled;

  String toJson() => name;

  static OrderStatus fromJson(String raw) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => OrderStatus.pendingCompanyAccept,
    );
  }
}

@immutable
class Order {
  final String id;
  final DateTime createdAt;
  final DateTime statusUpdatedAt;
  final OrderStatus status;

  final String storeName;
  final String storeArea;
  final String address;

  final double deliveryFee;
  final double serviceFee;
  final String paymentMethod;

  final List<OrderLine> lines;

  const Order({
    required this.id,
    required this.createdAt,
    required this.statusUpdatedAt,
    required this.status,
    required this.storeName,
    required this.storeArea,
    required this.address,
    required this.deliveryFee,
    required this.serviceFee,
    required this.paymentMethod,
    required this.lines,
  });

  double get itemsSubtotal =>
      lines.fold<double>(0, (a, b) => a + (b.price * b.qty));

  double get total => itemsSubtotal + deliveryFee + serviceFee;

  int get itemsCount => lines.fold<int>(0, (a, b) => a + b.qty);

  Order copyWith({
    DateTime? statusUpdatedAt,
    OrderStatus? status,
  }) {
    return Order(
      id: id,
      createdAt: createdAt,
      statusUpdatedAt: statusUpdatedAt ?? this.statusUpdatedAt,
      status: status ?? this.status,
      storeName: storeName,
      storeArea: storeArea,
      address: address,
      deliveryFee: deliveryFee,
      serviceFee: serviceFee,
      paymentMethod: paymentMethod,
      lines: lines,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'statusUpdatedAt': statusUpdatedAt.toIso8601String(),
        'status': status.toJson(),
        'storeName': storeName,
        'storeArea': storeArea,
        'address': address,
        'deliveryFee': deliveryFee,
        'serviceFee': serviceFee,
        'paymentMethod': paymentMethod,
        'lines': lines.map((e) => e.toJson()).toList(growable: false),
      };

  factory Order.fromJson(Map<String, dynamic> json) {
    DateTime parseDt(Object? v) {
      if (v is String) {
        return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
      }
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    final linesRaw = json['lines'];
    final parsedLines = <OrderLine>[];
    if (linesRaw is List) {
      for (final e in linesRaw) {
        if (e is Map) {
          parsedLines.add(OrderLine.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }

    return Order(
      id: (json['id'] ?? '').toString(),
      createdAt: parseDt(json['createdAt']),
      statusUpdatedAt: parseDt(json['statusUpdatedAt']),
      status: OrderStatusX.fromJson((json['status'] ?? '').toString()),
      storeName: (json['storeName'] ?? '').toString(),
      storeArea: (json['storeArea'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      deliveryFee: (json['deliveryFee'] is num)
          ? (json['deliveryFee'] as num).toDouble()
          : 0.0,
      serviceFee: (json['serviceFee'] is num)
          ? (json['serviceFee'] as num).toDouble()
          : 0.0,
      paymentMethod: (json['paymentMethod'] ?? '').toString(),
      lines: parsedLines,
    );
  }

  /// Build Order from Firestore document (orders collection)
  factory Order.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    DateTime tsToDt(Object? v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    final createdAt = tsToDt(data['createdAt']);
    final updatedAt = tsToDt(data['updatedAt']);

    OrderStatus mapStatus(String raw) {
      switch (raw) {
        case fs.OrderStatus.accepted:
          return OrderStatus.pendingCompanyAccept;
        case fs.OrderStatus.preparing:
          return OrderStatus.preparing;
        case fs.OrderStatus.onTheWay:
          return OrderStatus.onTheWay;
        case fs.OrderStatus.delivered:
          return OrderStatus.delivered;
        case fs.OrderStatus.cancelled:
          return OrderStatus.cancelled;
        default:
          return OrderStatus.pendingCompanyAccept;
      }
    }

    final itemsRaw = data['items'];
    final lines = <OrderLine>[];
    if (itemsRaw is List) {
      for (final e in itemsRaw) {
        if (e is Map) {
          final m = Map<String, dynamic>.from(e);
          lines.add(
            OrderLine(
              id: (m['id'] ?? '').toString(),
              title: (m['title'] ?? m['name'] ?? '').toString(),
              imageUrl: (m['imageUrl'] ?? '').toString(),
              price: (m['price'] is num) ? (m['price'] as num).toDouble() : 0.0,
              qty: (m['qty'] is num) ? (m['qty'] as num).toInt() : 1,
            ),
          );
        }
      }
    }

    final statusRaw = (data['status'] ?? fs.OrderStatus.accepted).toString();

    return Order(
      id: doc.id,
      createdAt: createdAt == DateTime.fromMillisecondsSinceEpoch(0) ? DateTime.now() : createdAt,
      statusUpdatedAt: updatedAt == DateTime.fromMillisecondsSinceEpoch(0) ? DateTime.now() : updatedAt,
      status: mapStatus(statusRaw),
      storeName: (data['storeName'] ?? 'طلبية').toString(),
      storeArea: (data['storeArea'] ?? '').toString(),
      address: (data['addressText'] ?? '').toString(),
      deliveryFee: (data['deliveryFee'] is num) ? (data['deliveryFee'] as num).toDouble() : 5.0,
      serviceFee: (data['serviceFee'] is num) ? (data['serviceFee'] as num).toDouble() : 0.0,
      paymentMethod: (data['paymentMethod'] ?? 'cash').toString(),
      lines: lines,
    );
  }
}
