import 'package:loqta/features/chat/domain/entities/conversation.dart';
import 'package:loqta/features/listings/domain/entities/listing.dart';

/// Maps a row of the `my_conversations()` RPC onto [Conversation].
///
/// The RPC already resolves the *other* participant and the listing summary for
/// the signed-in user, so this only has to unpack the columns.
class ConversationModel {
  const ConversationModel._();

  static Conversation fromRow(Map<String, dynamic> row) {
    final listingTitle = row['listing_title'] as String?;

    return Conversation(
      id: row['id'] as String? ?? '',
      listingId: row['listing_id'] as String? ?? '',
      buyerId: row['buyer_id'] as String? ?? '',
      sellerId: row['seller_id'] as String? ?? '',
      lastMessageAt:
          DateTime.tryParse(row['last_message_at'] as String? ?? '')
              ?.toLocal() ??
          DateTime.now(),
      unreadCount: _toInt(row['unread_count']) ?? 0,
      latestMessagePreview: row['latest_message_preview'] as String?,
      otherParticipantId: row['other_participant_id'] as String?,
      otherParticipantName: row['other_participant_name'] as String?,
      otherParticipantAvatarUrl: row['other_participant_avatar_url'] as String?,
      listing: listingTitle == null
          ? null
          : Listing(
              id: row['listing_id'] as String? ?? '',
              sellerId: row['seller_id'] as String? ?? '',
              title: listingTitle,
              description: '',
              category: '',
              condition: row['listing_condition'] as String? ?? '',
              type: ListingType.fromValue(row['listing_type'] as String?),
              price: _toDouble(row['listing_price']),
              imageUrls: [
                if ((row['listing_image_url'] as String?)?.isNotEmpty ?? false)
                  row['listing_image_url'] as String,
              ],
              governorate: row['listing_governorate'] as String? ?? '',
              area: row['listing_area'] as String? ?? '',
              status: ListingStatus.fromValue(row['listing_status'] as String?),
              createdAt:
                  DateTime.tryParse(row['listing_created_at'] as String? ?? '')
                      ?.toLocal() ??
                  DateTime.now(),
            ),
    );
  }

  static List<Conversation> fromRows(List<dynamic> rows) => rows
      .whereType<Map>()
      .map((row) => fromRow(Map<String, dynamic>.from(row)))
      .toList();

  static int? _toInt(Object? value) => switch (value) {
    num number => number.toInt(),
    String text => int.tryParse(text),
    _ => null,
  };

  static double? _toDouble(Object? value) => switch (value) {
    num number => number.toDouble(),
    String text => double.tryParse(text),
    _ => null,
  };
}
