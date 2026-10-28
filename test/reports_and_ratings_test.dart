import 'package:flutter_test/flutter_test.dart';
import 'support/fake_transaction_repository.dart';

void main() {
  late FakeTransactionRepository repository;

  setUp(() {
    repository = FakeTransactionRepository();
  });

  test('Reports are stored successfully', () async {
    await repository.submitReport('l1', 'Fraud', 'Suspicious activity');
    expect(repository.reports.length, 1);
    expect(repository.reports.first['reason'], 'Fraud');
  });

  test('Duplicate ratings are prevented', () async {
    await repository.submitRating('t1', 5, 'Great');
    expect(repository.ratings.length, 1);
    expect(() => repository.submitRating('t1', 4, 'Again'), throwsException);
  });
}
