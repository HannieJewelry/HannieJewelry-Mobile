
import '../../checkout/models/order_model.dart';

enum ReturnExchangeType { return_item, exchange_item }
enum ReturnExchangeStatus { pending, processing, approved, rejected, completed }

class ReturnExchangeModel {
  final String id;
  final String orderId;
  final List<OrderItem> items;
  final ReturnExchangeType type;
  final ReturnExchangeStatus status;
  final String reason;
  final String? additionalInfo;
  final List<String>? images;
  final DateTime createdAt;

  ReturnExchangeModel({
    required this.id,
    required this.orderId,
    required this.items,
    required this.type,
    required this.status,
    required this.reason,
    this.additionalInfo,
    this.images,
    required this.createdAt,
  });
}