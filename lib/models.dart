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


  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'price': price,
        'qty': qty,
      };

  factory CartLine.fromJson(Map<String, dynamic> json) {
    return CartLine(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      qty: (json['qty'] as num).toInt(),
    );
  }

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
