import 'package:loqta/features/listings/data/datasources/transaction_remote_data_source.dart';
import 'package:loqta/features/listings/domain/entities/reservation.dart';
import 'package:loqta/features/listings/domain/entities/transaction.dart';
import 'package:loqta/features/listings/domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl(this._dataSource);

  final TransactionRemoteDataSource _dataSource;

  @override
  Future<List<Reservation>> fetchIncomingRequests() async {
    final data = await _dataSource.fetchIncomingRequests();
    return data.map((e) => Reservation(
        id: e['id'],
        listingId: e['listing_id'],
        buyerId: e['buyer_id'],
        status: ReservationStatus.fromValue(e['status']),
        createdAt: DateTime.parse(e['created_at']))).toList();
  }

  @override
  Future<List<Transaction>> fetchActiveTransactions() async {
    final data = await _dataSource.fetchActiveTransactions();
    return data.map((e) => Transaction(
        id: e['id'],
        listingId: e['listing_id'],
        buyerId: e['buyer_id'],
        sellerId: e['seller_id'],
        status: TransactionStatus.fromValue(e['status']),
        createdAt: DateTime.parse(e['created_at']))).toList();
  }

  @override
  Future<List<Transaction>> fetchTransactionHistory() async {
    final data = await _dataSource.fetchTransactionHistory();
    return data.map((e) => Transaction(
        id: e['id'],
        listingId: e['listing_id'],
        buyerId: e['buyer_id'],
        sellerId: e['seller_id'],
        status: TransactionStatus.fromValue(e['status']),
        createdAt: DateTime.parse(e['created_at']))).toList();
  }

  @override
  Future<void> acceptReservation(String reservationId) async {
    await _dataSource.acceptReservation(reservationId);
  }

  @override
  Future<void> rejectReservation(String reservationId) async {
    await _dataSource.rejectReservation(reservationId);
  }

  @override
  Future<void> cancelReservation(String reservationId) async {
    await _dataSource.cancelReservation(reservationId);
  }

  @override
  Future<void> completeTransaction(String transactionId) async {
    await _dataSource.completeTransaction(transactionId);
  }
}
