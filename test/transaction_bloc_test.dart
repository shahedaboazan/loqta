import 'package:flutter_test/flutter_test.dart';
import 'package:loqta/features/listings/domain/entities/reservation.dart';
import 'package:loqta/features/listings/presentation/bloc/transaction_bloc.dart';
import 'support/fake_transaction_repository.dart';

void main() {
  late FakeTransactionRepository repository;
  late TransactionBloc bloc;

  setUp(() {
    repository = FakeTransactionRepository();
    bloc = TransactionBloc(repository);
  });

  test('LoadTransactions emits TransactionLoaded with empty lists initially', () async {
    expect(bloc.stream, emitsInOrder([
      isA<TransactionLoading>(),
      isA<TransactionLoaded>(),
    ]));
    bloc.add(LoadTransactions());
  });

  test('Accept reservation changes status', () async {
    final res = Reservation(id: 'r1', listingId: 'l1', buyerId: 'b1', status: ReservationStatus.pending, createdAt: DateTime.now());
    repository.reservations = [res];
    
    await repository.acceptReservation('r1');
    expect(repository.reservations.first.status, ReservationStatus.accepted);
  });
}
