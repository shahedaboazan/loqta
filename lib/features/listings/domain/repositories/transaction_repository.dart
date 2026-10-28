import 'package:loqta/features/listings/domain/entities/reservation.dart';
import 'package:loqta/features/listings/domain/entities/transaction.dart';

abstract class TransactionRepository {
  Future<List<Reservation>> fetchIncomingRequests();
  Future<List<Transaction>> fetchActiveTransactions();
  Future<List<Transaction>> fetchTransactionHistory();
  Future<void> acceptReservation(String reservationId);
  Future<void> rejectReservation(String reservationId);
  Future<void> cancelReservation(String reservationId);
  Future<void> completeTransaction(String transactionId);
}
