// lib/orders_repository.dart
import 'order_models.dart';

abstract class OrdersRepository {
  Future<List<Order>> loadAll();
  Future<void> saveAll(List<Order> orders);
}
