import 'package:flutter_test/flutter_test.dart';
import 'package:loqta/features/listings/domain/entities/reservation.dart';
import 'package:loqta/features/listings/domain/entities/transaction.dart';
import 'package:loqta/features/listings/domain/repositories/transaction_repository.dart';

class FakeTransactionRepository implements TransactionRepository {
  List<Reservation> reservations = [];
  List<Transaction> transactions = [];
  List<Map<String, dynamic>> reports = [];
  List<Map<String, dynamic>> ratings = [];

  @override
  Future<List<Reservation>> fetchIncomingRequests() async => reservations;
  
  @override
  Future<List<Transaction>> fetchActiveTransactions() async => transactions.where((t) => t.status == TransactionStatus.active).toList();
  
  @override
  Future<List<Transaction>> fetchTransactionHistory() async => transactions.where((t) => t.status == TransactionStatus.completed).toList();
  
  @override
  Future<void> acceptReservation(String reservationId) async {
    reservations = reservations.map((r) => r.id == reservationId ? Reservation(id: r.id, listingId: r.listingId, buyerId: r.buyerId, status: ReservationStatus.accepted, createdAt: r.createdAt) : r).toList();
  }

  @override
  Future<void> rejectReservation(String reservationId) async {
    reservations = reservations.map((r) => r.id == reservationId ? Reservation(id: r.id, listingId: r.listingId, buyerId: r.buyerId, status: ReservationStatus.rejected, createdAt: r.createdAt) : r).toList();
  }

  @override
  Future<void> cancelReservation(String reservationId) async {}
  
  @override
  Future<void> completeTransaction(String transactionId) async {
    transactions = transactions.map((t) => t.id == transactionId ? Transaction(id: t.id, listingId: t.listingId, buyerId: t.buyerId, sellerId: t.sellerId, status: TransactionStatus.completed, createdAt: t.createdAt) : t).toList();
  }

  Future<void> submitReport(String listingId, String reason, String details) async {
    reports.add({'listingId': listingId, 'reason': reason, 'details': details});
  }

  Future<void> submitRating(String transactionId, int value, String comment) async {
    // Basic check for duplicate
    if (ratings.any((r) => r['transactionId'] == transactionId)) throw Exception('Duplicate rating');
    ratings.add({'transactionId': transactionId, 'value': value, 'comment': comment});
  }
}
