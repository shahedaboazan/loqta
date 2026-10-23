import 'package:equatable/equatable.dart';

/// A failure raised by the chat data layer.
class ChatFailure extends Equatable implements Exception {
  const ChatFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'ChatFailure($message)';
}
