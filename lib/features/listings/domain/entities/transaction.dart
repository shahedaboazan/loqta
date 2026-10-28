import 'package:equatable/equatable.dart';

enum TransactionStatus {
  active,
  completed,
  cancelled;

  static TransactionStatus fromValue(String? value) => switch (value) {
    'completed' => TransactionStatus.completed,
    'cancelled' => TransactionStatus.cancelled,
    _ => TransactionStatus.active,
  };
}

class Transaction extends Equatable {
  const Transaction({
    required this.id,
    required this.listingId,
    required this.buyerId,
    required this.sellerId,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String listingId;
  final String buyerId;
  final String sellerId;
  final TransactionStatus status;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, listingId, buyerId, sellerId, status, createdAt];
}
