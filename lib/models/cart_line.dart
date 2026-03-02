import 'package:flutter/foundation.dart';

@immutable
class CartLine {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final double price;
  final int qty;

  const CartLine({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.qty,
  });

  CartLine copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    double? price,
    int? qty,
  }) {
    return CartLine(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      qty: qty ?? this.qty,
    );
  }
}
