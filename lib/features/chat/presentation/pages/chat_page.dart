import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:loqta/core/theme/app_theme.dart';
import 'package:loqta/core/widgets/loqta_app_bar.dart';
import 'package:loqta/features/chat/domain/entities/message.dart';
import 'package:loqta/features/chat/domain/repositories/chat_repository.dart';
import 'package:loqta/features/chat/domain/services/image_picker_service.dart';
import 'package:loqta/features/chat/domain/usecases/mark_conversation_read_usecase.dart';
import 'package:loqta/features/chat/domain/usecases/send_message_usecase.dart';
import 'package:loqta/features/chat/domain/usecases/watch_messages_usecase.dart';
import 'package:loqta/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:loqta/features/chat/presentation/widgets/chat_thread_widgets.dart';
import 'package:loqta/features/chat/presentation/pages/image_viewer_page.dart';
import 'package:loqta/features/chat/presentation/widgets/message_bubble.dart';

/// Screen 14 — Chat.
///
/// Loads the conversation's history, then subscribes to Supabase Realtime so
/// new messages appear without reopening the screen. Ordering is
/// (created_at, id) and ids are de-duplicated, so a message never shows twice
/// when the insert response and the realtime event both arrive.
class ChatPage extends StatelessWidget {
  const ChatPage({
    super.key,
    required this.conversationId,
    this.otherParticipantName = '',
    this.otherParticipantAvatarUrl,
    this.listingTitle,
  });

  final String conversationId;

  /// Optional fallback only. The header resolves the real participant from the
  /// server when the screen opens, so a caller that does not know the name is
  /// still correct once the conversation loads.
  final String otherParticipantName;
  final String? otherParticipantAvatarUrl;
  final String? listingTitle;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatBloc>(
      create: (context) {
        final repository = context.read<ChatRepository>();
        return ChatBloc(
          watchMessages: WatchMessagesUseCase(repository),
          sendMessage: SendMessageUseCase(repository),
          sendImageMessage: SendImageMessageUseCase(repository),
          markRead: MarkConversationReadUseCase(repository),
          getConversation: GetConversationUseCase(repository),
          conversation: null,
        )..add(ChatStarted(conversationId));
      },
      child: ChatView(
        conversationId: conversationId,
        otherParticipantName: otherParticipantName,
        otherParticipantAvatarUrl: otherParticipantAvatarUrl,
        listingTitle: listingTitle,
      ),
    );
  }
}

class ChatView extends StatefulWidget {
  const ChatView({
    super.key,
    required this.conversationId,
    required this.otherParticipantName,
    this.otherParticipantAvatarUrl,
    this.listingTitle,
  });

  final String conversationId;
  final String otherParticipantName;
  final String? otherParticipantAvatarUrl;
  final String? listingTitle;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<ChatBloc>().add(ChatMessageSent(text));
    _controller.clear();
  }

  /// Opens the Image Viewer for the tapped attachment.
  ///
  /// Pushed onto the current route, so Back returns to this exact conversation.
  void _openImage(Message message, List<Message> all) {
    final url = message.attachmentUrl;

    // The bubble says "Tap to open", so a tap has to answer even when the
    // signed URL could not be resolved — silently doing nothing would read as
    // a broken screen.
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('This photo is no longer available.')),
        );
      return;
    }

    final attachments = all
        .where((item) => item.hasAttachment && item.attachmentUrl != null)
        .toList();
    final index = attachments.indexWhere((item) => item.id == message.id);

    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => ImageViewerPage(
              imageUrl: url,
              position: index < 0 ? 1 : index + 1,
              itemCount: attachments.length,
              // The viewer swipes through the conversation's attachments, so it
              // needs every URL the bloc already resolved rather than just this one.
              imageUrls: [
                for (final item in attachments)
                  if (item.attachmentUrl != null) item.attachmentUrl!,
              ],
            ),
          ),
        )
        .then((_) {
          // Coming back from the viewer, re-read history so a message that arrived
          // meanwhile is not missed.
          if (mounted) {
            context.read<ChatBloc>().add(const ChatHistoryReloaded());
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoqtaColors.background,
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<ChatBloc, ChatState>(
          listenWhen: (previous, current) =>
              current is ChatSuccess &&
              current.transientError != null &&
              (previous is! ChatSuccess ||
                  previous.transientError != current.transientError),
          listener: (context, state) {
            if (state is ChatSuccess && state.transientError != null) {
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(SnackBar(content: Text(state.transientError!)));
            }
          },
          builder: (context, state) {
            // The server's view of the thread wins over whatever the opening
            // screen passed in; the caller's own values are the fallback for a
            // conversation that could not be read back.
            final conversation = state is ChatSuccess
                ? state.conversation
                : null;
            final listing = conversation?.listing;
            final resolvedName = conversation?.otherParticipantName?.trim();
            final name = (resolvedName == null || resolvedName.isEmpty)
                ? widget.otherParticipantName
                : resolvedName;
            final messages = state is ChatSuccess
                ? state.messages
                : const <Message>[];

            return Column(
              children: [
                _ChatHeader(
                  name: name,
                  avatarUrl:
                      conversation?.otherParticipantAvatarUrl ??
                      widget.otherParticipantAvatarUrl,
                  listingTitle: listing?.title ?? widget.listingTitle,
                  listingImageUrl: listing?.imageUrls.firstOrNull,
                  listingPriceLabel: listing == null
                      ? null
                      : (listing.formattedPrice == null
                            ? 'Free'
                            : '${listing.formattedPrice} SYP'),
                  listingLocationLabel: listing?.locationLabel,
                ),
                Expanded(
                  child: switch (state) {
                    ChatInProgress() => const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          LoqtaColors.primary,
                        ),
                      ),
                    ),
                    ChatLoadFailure(:final message) => _ChatError(
                      message: message,
                      onRetry: () => context.read<ChatBloc>().add(
                        ChatStarted(widget.conversationId),
                      ),
                    ),
                    ChatSuccess() =>
                      messages.isEmpty
                          ? const _EmptyThread()
                          : _MessageList(
                              messages: messages,
                              controller: _scrollController,
                              senderName: name,
                              onImageTap: (message) =>
                                  _openImage(message, messages),
                            ),
                  },
                ),
                ChatPickupBar(locationLabel: listing?.locationLabel ?? ''),
                _Composer(
                  controller: _controller,
                  focusNode: _focusNode,
                  onSend: _send,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The failure state for a conversation that could not be opened, with the
/// retry the screen needs to be recoverable.
class _ChatError extends StatelessWidget {
  const _ChatError({required this.message, required this.onRetry});

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
              Icons.cloud_off_rounded,
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

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.name,
    this.avatarUrl,
    this.listingTitle,
    this.listingImageUrl,
    this.listingPriceLabel,
    this.listingLocationLabel,
  });

  final String name;
  final String? avatarUrl;
  final String? listingTitle;
  final String? listingImageUrl;
  final String? listingPriceLabel;
  final String? listingLocationLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LoqtaAppBar(
          // The other participant's name is the thread's identity, so it is the
          // title rather than a generic "Chat".
          title: name.trim().isEmpty ? 'Chat' : name.trim(),
          // Popping returns to whichever screen opened the chat — Listing
          // Details or the Chat List — and never opens a new conversation.
          onBack: () => Navigator.of(context).maybePop(),
          trailing: Padding(
            padding: const EdgeInsets.only(right: 2),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: LoqtaColors.primary,
              backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                  ? NetworkImage(avatarUrl!)
                  : null,
              child: (avatarUrl == null || avatarUrl!.isEmpty)
                  ? Text(
                      name.trim().isEmpty
                          ? 'L'
                          : name.trim().characters.first.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFamily: LoqtaText.family,
                      ),
                    )
                  : null,
            ),
          ),
        ),
        _ListingContextCard(
          title: listingTitle,
          imageUrl: listingImageUrl,
          priceLabel: listingPriceLabel,
          locationLabel: listingLocationLabel,
        ),
      ],
    );
  }
}

/// The listing the thread is about, shown as a compact card under the app bar:
/// thumbnail, title, price and the public location.
class _ListingContextCard extends StatelessWidget {
  const _ListingContextCard({
    this.title,
    this.imageUrl,
    this.priceLabel,
    this.locationLabel,
  });

  final String? title;
  final String? imageUrl;
  final String? priceLabel;
  final String? locationLabel;

  @override
  Widget build(BuildContext context) {
    if (title == null || title!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final image = imageUrl?.trim();
    final price = priceLabel?.trim();
    final location = locationLabel?.trim();

    return Container(
      margin: const EdgeInsets.fromLTRB(
        LoqtaSpacing.gutter,
        0,
        LoqtaSpacing.gutter,
        8,
      ),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: LoqtaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LoqtaColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 40,
              height: 40,
              child: (image == null || image.isEmpty)
                  ? Container(
                      color: LoqtaColors.fieldFill,
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        size: 18,
                        color: LoqtaColors.textTertiary,
                      ),
                    )
                  : Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: LoqtaColors.fieldFill,
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          size: 18,
                          color: LoqtaColors.textTertiary,
                        ),
                      ),
                      loadingBuilder: (context, child, progress) =>
                          progress == null
                          ? child
                          : Container(color: LoqtaColors.fieldFill),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title!.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: LoqtaColors.headingPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: LoqtaText.family,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (price != null && price.isNotEmpty) price,
                    if (location != null && location.isNotEmpty) location,
                  ].join(' · '),
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
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageList extends StatefulWidget {
  const _MessageList({
    required this.messages,
    required this.controller,
    required this.senderName,
    required this.onImageTap,
  });

  final List<Message> messages;
  final ScrollController controller;
  final String senderName;
  final ValueChanged<Message> onImageTap;

  @override
  State<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<_MessageList> {
  /// The newest message currently on screen.
  ///
  /// The list only scrolls when this changes. Scrolling on every build would
  /// yank the user back down whenever anything rebuilt — including every
  /// keystroke in the composer — making the history unreadable.
  String? _lastMessageId;

  /// True while the user is already at the bottom, so an arriving message only
  /// scrolls when it would not steal their place.
  bool _isNearBottom = true;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
    _lastMessageId = _newestId;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  String? get _newestId =>
      widget.messages.isEmpty ? null : widget.messages.last.id;

  void _onScroll() {
    if (!widget.controller.hasClients) return;
    final position = widget.controller.position;
    _isNearBottom = position.pixels >= position.maxScrollExtent - 48;
  }

  @override
  void didUpdateWidget(_MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newest = _newestId;
    if (newest == _lastMessageId) return;
    _lastMessageId = newest;

    // A message arrived while the user was reading further up: leave them
    // where they are.
    if (!_isNearBottom) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.controller.hasClients) return;
      widget.controller.jumpTo(widget.controller.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.messages;

    return ListView.builder(
      controller: widget.controller,
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      // One extra leading row for the fixed safety notice.
      itemCount: messages.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return const ChatSafetyNotice();

        final position = index - 1;
        final message = messages[position];
        final previous = position == 0 ? null : messages[position - 1];

        // A day separator goes above the first message of each day, and a sender
        // name on the first message of each run.
        final startsNewDay =
            previous == null ||
            !_sameDay(previous.createdAt, message.createdAt);
        final startsRun =
            previous == null || previous.senderId != message.senderId;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (startsNewDay) ChatDaySeparator(message.createdAt),
            MessageBubble(
              message: message,
              senderName: widget.senderName,
              showSenderName: startsRun,
              onImageTap: () => widget.onImageTap(message),
            ),
          ],
        );
      },
    );
  }

  static bool _sameDay(DateTime a, DateTime b) {
    final localA = a.toLocal();
    final localB = b.toLocal();
    return localA.year == localB.year &&
        localA.month == localB.month &&
        localA.day == localB.day;
  }
}

class _Composer extends StatefulWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  /// True from the tap until the picker answers, so repeated taps cannot open
  /// several pickers or queue duplicate uploads.
  bool _isPicking = false;

  bool get _canSend => widget.controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    // Rebuild so the send button enables and disables with the field.
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final uploading = context.select<ChatBloc, bool>(
      (bloc) =>
          bloc.state is ChatSuccess && (bloc.state as ChatSuccess).isUploading,
    );

    return Container(
      decoration: const BoxDecoration(
        color: LoqtaColors.surface,
        border: Border(top: BorderSide(color: LoqtaColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            LoqtaSpacing.gutter,
            10,
            LoqtaSpacing.gutter,
            10,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _AttachButton(
                uploading: uploading || _isPicking,
                onPick: _explainPickerGap,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'Write a message...',
                    hintStyle: LoqtaText.fieldHint,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: _canSend ? LoqtaColors.primary : LoqtaColors.fieldFill,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: _canSend ? widget.onSend : null,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.send_rounded,
                      size: 18,
                      color: _canSend ? Colors.white : LoqtaColors.textTertiary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The image pipeline (upload to Storage, record the path, render the bubble,
  /// open the Image Viewer) belongs to [ChatBloc]. This only obtains the bytes
  /// and hands them over, so a platform failure never reaches the repository
  /// looking like a failed send.
  void _explainPickerGap() {
    _pickAndAttach();
  }

  void _pickAndAttach() {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    _runPick();
  }

  Future<void> _runPick() async {
    try {
      final picked = await context.read<ImagePickerService>().pickImage();
      if (picked == null) return;

      if (!mounted) return;
      context.read<ChatBloc>().add(
        ChatImageAttached(bytes: picked.bytes, fileName: picked.fileName),
      );
    } on ImagePickException catch (failure) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(failure.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('That photo could not be selected.')),
        );
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }
}

class _AttachButton extends StatelessWidget {
  const _AttachButton({required this.uploading, required this.onPick});

  final bool uploading;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LoqtaColors.fieldFill,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: uploading ? null : onPick,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 40,
          height: 40,
          child: uploading
              ? const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        LoqtaColors.primary,
                      ),
                    ),
                  ),
                )
              : const Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 19,
                  color: LoqtaColors.textSecondary,
                ),
        ),
      ),
    );
  }
}

class _EmptyThread extends StatelessWidget {
  const _EmptyThread();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(LoqtaSpacing.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 40,
              color: LoqtaColors.textTertiary,
            ),
            SizedBox(height: 12),
            Text(
              'No messages yet',
              style: TextStyle(
                color: LoqtaColors.headingPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                fontFamily: LoqtaText.family,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Say hello and ask about the item.',
              textAlign: TextAlign.center,
              style: LoqtaText.subtitle,
            ),
          ],
        ),
      ),
    );
  }
}
