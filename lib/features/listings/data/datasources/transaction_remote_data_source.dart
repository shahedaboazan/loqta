import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionRemoteDataSource {
  TransactionRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchIncomingRequests() async {
    final response = await _client
        .from('reservations')
        .select('*, listings(*)')
        .eq('status', 'pending');
    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<void> acceptReservation(String reservationId) async {
    await _client.rpc('accept_reservation', params: {'p_reservation_id': reservationId});
  }

  Future<void> rejectReservation(String reservationId) async {
    await _client.from('reservations').update({'status': 'rejected'}).eq('id', reservationId);
  }

  Future<void> cancelReservation(String reservationId) async {
     await _client.from('reservations').update({'status': 'cancelled'}).eq('id', reservationId);
  }

  Future<void> completeTransaction(String transactionId) async {
     await _client.from('transactions').update({'status': 'completed'}).eq('id', transactionId);
  }

  Future<List<Map<String, dynamic>>> fetchActiveTransactions() async {
     final response = await _client
        .from('transactions')
        .select('*, listings(*)')
        .eq('status', 'active');
     return (response as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchTransactionHistory() async {
     final response = await _client
        .from('transactions')
        .select('*, listings(*)')
        .eq('status', 'completed');
     return (response as List).cast<Map<String, dynamic>>();
  }
}
