import 'package:equatable/equatable.dart';

enum ReservationStatus {
  pending,
  accepted,
  rejected,
  cancelled;

  static ReservationStatus fromValue(String? value) => switch (value) {
    'accepted' => ReservationStatus.accepted,
    'rejected' => ReservationStatus.rejected,
    'cancelled' => ReservationStatus.cancelled,
    _ => ReservationStatus.pending,
  };
}

class Reservation extends Equatable {
  const Reservation({
    required this.id,
    required this.listingId,
    required this.buyerId,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String listingId;
  final String buyerId;
  final ReservationStatus status;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, listingId, buyerId, status, createdAt];
}
