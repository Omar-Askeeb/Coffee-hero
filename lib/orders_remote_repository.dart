/// lib/orders_remote_repository.dart
///
/// Remote backend implementation (stub for now).
///
/// When backend is ready:
/// - Inject a Dio/Http client
/// - Implement loadAll() and saveAll() (or replace saveAll with API calls)
///
/// Recommended future API:
/// - POST /orders (create)
/// - GET /orders (list)
/// - GET /orders/{id} (details)
/// - POST /orders/{id}/cancel (cancel)

import 'order_models.dart';
import 'orders_repository.dart';

class RemoteOrdersRepository implements OrdersRepository {
  const RemoteOrdersRepository();

  @override
  Future<List<Order>> loadAll() async {
    throw UnimplementedError('Connect to backend and implement loadAll()');
  }

  @override
  Future<void> saveAll(List<Order> orders) async {
    throw UnimplementedError('Connect to backend and implement saveAll()');
  }
}
