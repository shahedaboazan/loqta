import 'package:equatable/equatable.dart';

import 'package:loqta/features/listings/domain/entities/listing.dart';

/// A two-party chat thread about one listing.
///
/// [buyerId] and [sellerId] mirror the database columns, and [otherParticipantId]
/// / [otherParticipantName] are resolved for whichever account is signed in, so
/// the Chat List and Chat header never have to branch on "am I the buyer?".
class Conversation extends Equatable {
  const Conversation({
    required this.id,
    required this.listingId,
    required this.buyerId,
    required this.sellerId,
    required this.lastMessageAt,
    required this.unreadCount,
    this.listing,
    this.otherParticipantId,
    this.otherParticipantName,
    this.otherParticipantAvatarUrl,
    this.latestMessagePreview,
  });

  final String id;
  final String listingId;
  final String buyerId;
  final String sellerId;
  final DateTime lastMessageAt;

  /// Messages from the other participant after this user's read cursor.
  final int unreadCount;

  /// The listing under discussion. Null when the listing was deleted or the
  /// caller lost read access to it.
  final Listing? listing;

  final String? otherParticipantId;
  final String? otherParticipantName;
  final String? otherParticipantAvatarUrl;

  /// Preview text of the most recent message, including a marker for an image
  /// attachment.
  final String? latestMessagePreview;

  bool get isUnread => unreadCount > 0;

  /// "Modern Fabric Sofa - 1,500,000 SYP", the Chat List's listing sub-line.
  String? get listingSubtitle {
    final subject = listing;
    if (subject == null) return null;
    final price = subject.formattedPrice;
    return price == null ? subject.title : '${subject.title} - $price SYP';
  }

  @override
  List<Object?> get props => [
    id,
    lastMessageAt,
    unreadCount,
    latestMessagePreview,
  ];
}
