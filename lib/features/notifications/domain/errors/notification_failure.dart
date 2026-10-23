import 'package:equatable/equatable.dart';

/// A failure raised by the notification data layer.
class NotificationFailure extends Equatable implements Exception {
  const NotificationFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'NotificationFailure($message)';
}
