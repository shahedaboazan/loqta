import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:loqta/core/theme/app_theme.dart';
import 'package:loqta/core/widgets/loqta_app_bar.dart';
import 'package:loqta/features/chat/domain/entities/conversation.dart';
import 'package:loqta/features/chat/domain/repositories/chat_repository.dart';
import 'package:loqta/features/chat/domain/usecases/get_conversations_usecase.dart';
import 'package:loqta/features/chat/presentation/bloc/conversations_bloc.dart';
import 'package:loqta/features/chat/presentation/pages/chat_page.dart';

/// Screen 16 — Chat List.
///
/// The WhatsApp-like conversation list: avatar, participant, the listing being
/// discussed, the latest message preview, a timestamp and an unread badge.
///
/// Opening a row only navigates to that existing conversation; nothing here
/// creates one.
class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key, this.listingId});

  final String? listingId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ConversationsBloc>(
      create: (context) {
        final repository = context.read<ChatRepository>();
        return ConversationsBloc(
          getConversations: GetConversationsUseCase(repository),
          chatRepository: repository,
        )..add(
            listingId != null
                ? ConversationsRequested(listingId: listingId)
                : const ConversationsRequested(),
          );
      },
      child: const ChatListView(),
    );
  }
}

class ChatListView extends StatelessWidget {
  const ChatListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoqtaColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            LoqtaAppBar(
              title: 'Chat Messages',
              // On the shell's tab there is no route to pop; hide the chevron
              // so it cannot exit the app. It returns when pushed as a route.
              showBack: Navigator.of(context).canPop(),
            ),
            const _SecurityBanner(),
            Expanded(
              child: BlocBuilder<ConversationsBloc, ConversationsState>(
                builder: (context, state) => switch (state) {
                  ConversationsInProgress() => const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        LoqtaColors.primary,
                      ),
                    ),
                  ),
                  ConversationsFailure(:final message) => _ListError(
                    message: message,
                    onRetry: () => context.read<ConversationsBloc>().add(
                      const ConversationsRequested(),
                    ),
                  ),
                  ConversationsSuccess(:final conversations) =>
                    conversations.isEmpty
                        ? const _EmptyChats()
                        : _ConversationList(conversations: conversations),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The fixed reassurance line the approved design puts under the title.
///
/// It states the product rule rather than anything derived per conversation, so
/// it cannot report a status the database does not actually hold.
class _SecurityBanner extends StatelessWidget {
  const _SecurityBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        LoqtaSpacing.gutter,
        0,
        LoqtaSpacing.gutter,
        10,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: LoqtaColors.surfaceMint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD3EEDD)),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 16,
            color: LoqtaColors.primary,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Direct & secure peer-to-peer chats',
              style: TextStyle(
                color: LoqtaColors.headingPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                fontFamily: LoqtaText.family,
              ),
            ),
          ),
          Text(
            'Verified',
            style: TextStyle(
              color: LoqtaColors.primary,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              fontFamily: LoqtaText.family,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationList extends StatelessWidget {
  const _ConversationList({required this.conversations});

  final List<Conversation> conversations;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: LoqtaColors.primary,
      onRefresh: () async =>
          context.read<ConversationsBloc>().add(const ConversationsRequested()),
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: conversations.length,
        separatorBuilder: (_, _) => const Divider(indent: 78, height: 1),
        itemBuilder: (context, index) {
          final conversation = conversations[index];
          return _ConversationRow(
            conversation: conversation,
            onTap: () => _open(context, conversation),
          );
        },
      ),
    );
  }

  /// Opens the conversation that already exists. No conversation is created
  /// here — creation only ever happens from "Contact Seller".
  void _open(BuildContext context, Conversation conversation) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatPage(
          conversationId: conversation.id,
          otherParticipantName:
              conversation.otherParticipantName ?? 'Loqta member',
          otherParticipantAvatarUrl: conversation.otherParticipantAvatarUrl,
          listingTitle: conversation.listing?.title,
        ),
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.conversation, required this.onTap});

  final Conversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = conversation.otherParticipantName ?? 'Loqta member';
    final avatarUrl = conversation.otherParticipantAvatarUrl;
    final preview = conversation.latestMessagePreview;
    final hasPreview = preview != null && preview.trim().isNotEmpty;
    final subtitle = conversation.listingSubtitle;
    final thumbnail = conversation.listing?.imageUrls.isNotEmpty ?? false
        ? conversation.listing!.imageUrls.first
        : null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LoqtaSpacing.gutter,
          vertical: 12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (avatarUrl != null && avatarUrl.isNotEmpty)
              CircleAvatar(radius: 22, backgroundImage: NetworkImage(avatarUrl))
            else
              CircleAvatar(
                radius: 22,
                backgroundColor: LoqtaColors.primary,
                child: Text(
                  name.trim().isEmpty
                      ? 'L'
                      : name.trim().characters.first.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: LoqtaText.family,
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: LoqtaColors.headingPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            fontFamily: LoqtaText.family,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTimestamp(conversation.lastMessageAt),
                        style: const TextStyle(
                          color: LoqtaColors.textTertiary,
                          fontSize: 9.5,
                          fontFamily: LoqtaText.family,
                        ),
                      ),
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: LoqtaColors.primary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        fontFamily: LoqtaText.family,
                      ),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          hasPreview ? preview : 'No messages yet',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: hasPreview
                                ? LoqtaColors.textSecondary
                                : LoqtaColors.textTertiary,
                            fontSize: 11.5,
                            fontFamily: LoqtaText.family,
                          ),
                        ),
                      ),
                      if (conversation.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(minWidth: 18),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: const BoxDecoration(
                            color: LoqtaColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            conversation.unreadCount > 99
                                ? '99+'
                                : '${conversation.unreadCount}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              fontFamily: LoqtaText.family,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (thumbnail != null) ...[
              const SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  thumbnail,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 44,
                    height: 44,
                    color: LoqtaColors.fieldFill,
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      size: 18,
                      color: LoqtaColors.textTertiary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatTimestamp(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return 'now';
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inDays < 1) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';

    final local = time.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}';
  }
}

class _EmptyChats extends StatelessWidget {
  const _EmptyChats();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        LoqtaSpacing.gutter,
        30,
        LoqtaSpacing.gutter,
        24,
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: LoqtaColors.surfaceMint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 30,
              color: LoqtaColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No other messages',
            style: TextStyle(
              color: LoqtaColors.headingPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: LoqtaText.family,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your conversations about listings will appear here. Safe and '
            'confidential coordination with local buyers & sellers.',
            textAlign: TextAlign.center,
            style: LoqtaText.subtitle,
          ),
        ],
      ),
    );
  }
}

class _ListError extends StatelessWidget {
  const _ListError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LoqtaSpacing.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 40,
              color: LoqtaColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: LoqtaText.subtitle,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 44,
              child: OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: LoqtaColors.primary,
                  side: const BorderSide(color: LoqtaColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      LoqtaSpacing.radiusButton,
                    ),
                  ),
                ),
                child: const Text(
                  'Try again',
                  style: TextStyle(
                    color: LoqtaColors.primary,
                    fontWeight: FontWeight.w600,
                    fontFamily: LoqtaText.family,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
