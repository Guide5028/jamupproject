// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/pay_label.dart';
import '../widgets/chat_bubble.dart';
import '../../booking/data/booking_repository.dart';
import '../data/messages_repository.dart';

class ChatPage extends StatefulWidget {
  final String name;
  final String avatar;
  final String initialStatus;

  final String? chatId;
  final String? bookingId;
  final String otherUserId;
  final bool isVenue;

  /// The gig's posted rate, shown as context while musician and venue
  /// negotiate in chat (e.g. "Posted rate: ฿2,500/day"). Null when the
  /// caller doesn't have it handy or the gig has no fixed rate yet.
  final double? gigPayment;
  final String? gigPaymentUnit;

  final BookingRepository? bookingRepository;
  final MessagesRepository? messagesRepository;

  const ChatPage({
    super.key,
    required this.name,
    required this.avatar,
    this.initialStatus = "pending",
    this.chatId,
    this.bookingId,
    required this.otherUserId,
    this.isVenue = false,
    this.gigPayment,
    this.gigPaymentUnit,
    this.bookingRepository,
    this.messagesRepository,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // A getter (not a field) so this page can be pumped in widget tests
  // before/without Supabase.initialize() — same reasoning as the
  // `supabase` getter on BookingRepository/MessagesRepository.
  SupabaseClient get _supabase => Supabase.instance.client;
  final _controller = TextEditingController();
  final _offerAmountController = TextEditingController();
  final _scrollController = ScrollController();

  late final BookingRepository bookingRepo =
      widget.bookingRepository ?? BookingRepository();
  late final MessagesRepository messagesRepo =
      widget.messagesRepository ?? MessagesRepository();

  late String bookingStatus;
  List<Map<String, dynamic>> _messages = [];
  String _receiverId = ''; // resolved at init — used for notifications

  StreamSubscription? _messageSubscription;

  /// Guarded read of the current auth user. Wrapped in try/catch so a test
  /// environment without a live Supabase session degrades to "no user"
  /// instead of crashing — the real app always has Supabase initialized
  /// in main.dart, so this is a no-op there.
  User? get _authUser {
    try {
      return _supabase.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  String? get currentUserId => _authUser?.id;

  /// Returns the role of the currently logged-in user.
  /// We read it straight from Supabase auth metadata — same place it was
  /// written during sign-up (see auth_service.dart line 40: 'role': role).
  /// No extra network call needed; the metadata is already in memory.
  String get _currentUserRole =>
      (_authUser?.userMetadata?['role'] ?? '')
          .toString()
          .toLowerCase();

  // ==============================
  // INIT
  // ==============================

  @override
  void initState() {
    super.initState();
    bookingStatus = widget.initialStatus;
    _receiverId = widget.otherUserId;

    if (widget.chatId != null) {
      _markMessagesAsRead(); // 🔥 mark once when entering
      _startMessageListener();
      // If the caller didn't supply the other user's ID, resolve it from
      // the booking so notifications have a valid receiverId.
      if (_receiverId.isEmpty && widget.bookingId != null) {
        _resolveReceiverId();
      }
    } else {
      _loadDemoMessages();
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _controller.dispose();
    _offerAmountController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ==============================
  // MESSAGE LOGIC
  // ==============================
  Future<void> _markMessagesAsRead() async {
    // No signed-in user (or no live chat yet) — nothing to mark.
    if (widget.chatId == null || currentUserId == null) return;
    await messagesRepo.markAsRead(chatId: widget.chatId!);
  }

  /// Looks up musician_id / venue_id from the booking and picks
  /// whichever one is NOT the current user. Called once on init when
  /// the caller didn't pass otherUserId.
  Future<void> _resolveReceiverId() async {
    final resolved = await messagesRepo.resolveReceiverId(
      bookingId: widget.bookingId!,
      myUserId: currentUserId,
    );
    if (resolved != null) _receiverId = resolved;
  }

  void _loadDemoMessages() {
    _messages = [
      {"type": "system", "text": "⏳ Booking request sent"},
      {
        "sender_id": "other",
        "text": "Hi, are you available this Friday?",
        "type": "user"
      },
      {
        "sender_id": "me",
        "text": "Yes! What time is the show?",
        "type": "user"
      },
    ];
  }

  void _startMessageListener() {
    _messageSubscription =
        messagesRepo.messageStream(chatId: widget.chatId!).listen((data) async {
      final messages = List<Map<String, dynamic>>.from(data);

      // 🔧 Sort messages by time
      messages.sort((a, b) => DateTime.parse(a['created_at'])
          .compareTo(DateTime.parse(b['created_at'])));

      setState(() {
        _messages = messages;
      });

      // 🔥 only check unread messages — skip entirely if we don't know
      // who "we" are (e.g. no live session), matching the guard that
      // used to gate the whole listener before it was moved here.
      final myId = currentUserId;
      if (myId != null) {
        final unread = messages
            .where((msg) => msg['sender_id'] != myId && msg['read_at'] == null);

        if (unread.isNotEmpty) {
          await messagesRepo.markAsRead(chatId: widget.chatId!);
        }
      }

      _scrollToBottom();
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final user = _authUser;
    if (user == null) return;

    _controller.clear();

    if (widget.chatId == null) {
      setState(() {
        _messages.add({
          "sender_id": user.id,
          "text": text,
          "type": "user",
        });
      });
      _scrollToBottom();
      return;
    }

    try {
      await messagesRepo.sendMessage(chatId: widget.chatId!, text: text);
      await _notifyOtherParty(
        title: 'New message from ${_senderDisplayName(user)}',
        body: text,
        type: 'message',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  // ==============================
  // PRICE OFFER — structured money negotiation, not just free text.
  // ==============================

  Future<void> _sendOffer(double amount, String unit) async {
    final user = _authUser;

    final offerMsg = {
      "sender_id": user?.id ?? "me",
      "text": 'Price offer: ${payLabel(amount, unit)}',
      "type": "offer",
      "offer_amount": amount,
      "offer_unit": unit,
      "offer_status": "pending",
      "created_at": DateTime.now().toIso8601String(),
    };

    setState(() => _messages.add(offerMsg));
    _scrollToBottom();

    if (widget.chatId == null) return;

    try {
      await messagesRepo.sendPriceOffer(
        chatId: widget.chatId!,
        amount: amount,
        unit: unit,
      );
      await _notifyOtherParty(
        title: 'New price offer from ${_senderDisplayName(user)}',
        body: payLabel(amount, unit),
        type: 'price_offer',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send offer: $e')),
        );
      }
    }
  }

  /// Recipient taps Accept or Decline on an offer bubble.
  Future<void> _respondToOffer(dynamic messageId, String status) async {
    setState(() {
      final idx = _messages.indexWhere((m) => m['id'] == messageId);
      if (idx != -1) _messages[idx]['offer_status'] = status;
    });

    if (widget.chatId == null || messageId == null) return;

    try {
      await messagesRepo.respondToPriceOffer(
        messageId: messageId.toString(),
        status: status,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to respond to offer: $e')),
        );
      }
    }
  }

  Future<void> _notifyOtherParty({
    required String title,
    required String body,
    required String type,
  }) async {
    if (_receiverId.isEmpty) return;
    await messagesRepo.sendNotification(
      receiverId: _receiverId,
      title: title,
      body: body,
      type: type,
      data: {
        'chatId': widget.chatId,
        'bookingId': widget.bookingId,
      },
    );
  }

  String _senderDisplayName(User? user) {
    final name = user?.userMetadata?['name'] as String?;
    if (name != null && name.isNotEmpty) return name;
    return user?.email ?? 'Someone';
  }

  void _showOfferSheet() {
    _offerAmountController.clear();
    String selectedUnit = 'fixed';
    String? errorText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Send a Price Offer',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Propose a rate — the other side can accept or decline it.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('offer_amount_field'),
                    controller: _offerAmountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      prefixText: '฿ ',
                      hintText: 'Amount',
                      border: const OutlineInputBorder(),
                      errorText: errorText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: ['fixed', 'per_hour', 'per_day'].map((unit) {
                      return ChoiceChip(
                        label: Text(offerUnitLabel(unit)),
                        selected: selectedUnit == unit,
                        onSelected: (_) =>
                            setSheetState(() => selectedUnit = unit),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      key: const Key('confirm_offer_button'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        final amount =
                            parseOfferAmount(_offerAmountController.text);
                        if (amount == null) {
                          setSheetState(
                              () => errorText = 'Enter a valid amount');
                          return;
                        }
                        Navigator.of(sheetContext).pop();
                        _sendOffer(amount, selectedUnit);
                      },
                      child: const Text('Send Offer',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ==============================
  // STATUS BANNER
  // ==============================

  Widget _buildStatusBanner() {
    if (widget.bookingId == null) return const SizedBox();

    Color color;
    String text;

    switch (bookingStatus) {
      case "confirmed":
        color = Colors.green;
        text = "Booking Confirmed";
        break;
      case "declined":
        color = Colors.red;
        text = "Booking Declined";
        break;
      default:
        color = Colors.orange;
        text = "Waiting for confirmation";
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Shows the gig's posted rate as context while the two sides negotiate
  /// — without this, a musician has to leave the chat to re-check the gig
  /// page to remember what was originally offered.
  Widget _buildGigRateBanner() {
    if (widget.gigPayment == null) return const SizedBox();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sell_outlined,
              size: 16, color: AppColors.darkBrown),
          const SizedBox(width: 6),
          Text(
            'Posted rate: ${payLabel(widget.gigPayment, widget.gigPaymentUnit)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.darkBrown,
            ),
          ),
        ],
      ),
    );
  }

  // ==============================
  // UI
  // ==============================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F2),
      appBar: AppBar(
        backgroundColor: AppColors.primaryGold,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage:
                  widget.avatar.isNotEmpty ? NetworkImage(widget.avatar) : null,
              child: widget.avatar.isEmpty
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const Text("Online",
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildStatusBanner(),
          _buildGigRateBanner(),
          _buildBookingActions(),
          Expanded(
            child: ListView.builder(
              reverse: false,
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _messages.length,
              itemBuilder: (_, index) {
                final msg = _messages[index];
                final isLast = index == _messages.length - 1;

                if (msg['type'] == 'system') {
                  return _buildSystemMessage(msg['text']);
                }

                final isMe = msg['sender_id'] == currentUserId ||
                    msg['sender_id'] == "me";

                final isRead = msg['read_at'] != null;

                if (msg['type'] == 'offer') {
                  return ChatBubble(
                    message: msg['text'] ?? '',
                    isMe: isMe,
                    time: _formatTime(msg['created_at']),
                    isRead: isRead,
                    readAt: msg['read_at'],
                    showSeen: isMe && isLast && isRead,
                    offerAmount: (msg['offer_amount'] as num?)?.toDouble(),
                    offerUnit: msg['offer_unit'] as String?,
                    offerStatus: msg['offer_status'] as String? ?? 'pending',
                    onAccept: !isMe
                        ? () => _respondToOffer(msg['id'], 'accepted')
                        : null,
                    onDecline: !isMe
                        ? () => _respondToOffer(msg['id'], 'declined')
                        : null,
                  );
                }

                return ChatBubble(
                  message: msg['text'] ?? '',
                  isMe: isMe,
                  time: _formatTime(msg['created_at']),
                  isRead: isRead,
                  readAt: msg['read_at'],
                  showSeen: isMe && isLast && isRead,
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade400)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    if (bookingStatus == "declined") {
      return const SizedBox();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          IconButton(
            key: const Key('send_offer_button'),
            tooltip: 'Send a price offer',
            onPressed: _showOfferSheet,
            icon: const Icon(Icons.sell_outlined, color: AppColors.primaryGold),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: "Type your message...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.primaryGold,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBookingActions() {
    if (widget.bookingId == null) return const SizedBox();

    if (!widget.isVenue) return const SizedBox();

    if (bookingStatus != "pending") return const SizedBox();

    // ✅ ROLE GUARD — only the venue owner can accept or decline a booking.
    // A musician sent this request; they should not see these action buttons.
    // This mirrors the same check in booking_detail_page.dart (line 96):
    //   if (status == 'pending' && role == 'venue')
    if (_currentUserRole != 'venue') return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              onPressed: () async {
                await bookingRepo.respondToBooking(
                  bookingId: widget.bookingId!,
                  status: "confirmed",
                );

                setState(() {
                  bookingStatus = "confirmed";
                });
              },
              child: const Text("Accept"),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () async {
                await bookingRepo.respondToBooking(
                  bookingId: widget.bookingId!,
                  status: "declined",
                );

                setState(() {
                  bookingStatus = "declined";
                });
              },
              child: const Text("Decline"),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp)
          .toLocal(); // also convert to local timezone!
      return "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return '';
    }
  }
}
