import 'package:flutter/foundation.dart';

@immutable
class FavoriteItem {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final double price;

  const FavoriteItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.price,
  });

  FavoriteItem copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    double? price,
  }) {
    return FavoriteItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'price': price,
      };

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
    );
  }
}
