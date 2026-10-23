import 'package:equatable/equatable.dart';

/// A failure raised by the marketplace data layer.
///
/// Presentation code shows [message] directly, so the copy lives with the
/// mapper rather than in every widget.
class ListingFailure extends Equatable implements Exception {
  const ListingFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'ListingFailure($message)';
}
