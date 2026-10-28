import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loqta/features/listings/domain/entities/reservation.dart';
import 'package:loqta/features/listings/domain/entities/transaction.dart';
import 'package:loqta/features/listings/domain/repositories/transaction_repository.dart';

abstract class TransactionEvent {}
class LoadTransactions extends TransactionEvent {}

abstract class TransactionState {}
class TransactionInitial extends TransactionState {}
class TransactionLoading extends TransactionState {}
class TransactionLoaded extends TransactionState {
  final List<Reservation> incoming;
  final List<Transaction> active;
  final List<Transaction> history;
  TransactionLoaded(this.incoming, this.active, this.history);
}

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository repository;
  
  TransactionBloc(this.repository) : super(TransactionInitial()) {
    on<LoadTransactions>((event, emit) async {
      emit(TransactionLoading());
      final incoming = await repository.fetchIncomingRequests();
      final active = await repository.fetchActiveTransactions();
      final history = await repository.fetchTransactionHistory();
      emit(TransactionLoaded(incoming, active, history));
    });
  }
}
