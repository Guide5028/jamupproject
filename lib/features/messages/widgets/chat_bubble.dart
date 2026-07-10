import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/pay_label.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final String time;
  final bool isRead;
  final String? readAt;
  final bool showSeen;

  /// Price-offer fields — only set when this bubble represents a
  /// structured negotiation message (rendered as a distinct card instead
  /// of a plain text bubble). [onAccept]/[onDecline] are only wired up
  /// for the recipient of a still-pending offer.
  final double? offerAmount;
  final String? offerUnit;
  final String? offerStatus;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.time,
    required this.isRead,
    required this.readAt,
    required this.showSeen,
    this.offerAmount,
    this.offerUnit,
    this.offerStatus,
    this.onAccept,
    this.onDecline,
  });

  bool get _isOffer => offerAmount != null;

  @override
  Widget build(BuildContext context) {
    if (_isOffer) return _buildOfferBubble();
    return Align(
      alignment:
          isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            constraints: const BoxConstraints(maxWidth: 280),
            decoration: BoxDecoration(
              color: isMe
                  ? AppColors.primaryGold
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft:
                    isMe ? const Radius.circular(18) : Radius.zero,
                bottomRight:
                    isMe ? Radius.zero : const Radius.circular(18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color:
                        isMe ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe
                            ? Colors.white70
                            : Colors.black45,
                      ),
                    ),
                    if (isMe) const SizedBox(width: 4),
                    if (isMe)
                      Icon(
                        isRead
                            ? Icons.done_all
                            : Icons.done,
                        size: 14,
                        color: isRead
                            ? Colors.blueAccent
                            : Colors.white70,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // 🔥 Seen text outside bubble
          if (showSeen && readAt != null) ...[
            const SizedBox(height: 2),
            Text(
              "Seen ${_formatSeenTime(readAt)}",
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatSeenTime(String? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.tryParse(timestamp);
    if (date == null) return '';

    final hour = date.hour.toString().padLeft(2, '0');
    final minute =
        date.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  // ==========================================================================
  // PRICE OFFER CARD
  // ==========================================================================

  Widget _buildOfferBubble() {
    final status = offerStatus ?? 'pending';
    final Color statusColor = switch (status) {
      'accepted' => Colors.green,
      'declined' => Colors.red,
      _ => Colors.orange,
    };
    final String statusLabel = switch (status) {
      'accepted' => 'Accepted',
      'declined' => 'Declined',
      _ => 'Pending',
    };

    final canRespond = !isMe && status == 'pending';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryGold.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.sell_outlined,
                    size: 16, color: AppColors.primaryGold),
                const SizedBox(width: 6),
                const Text(
                  'Price Offer',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkBrown,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              payLabel(offerAmount, offerUnit),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBrown,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                const Spacer(),
                Text(time,
                    style: const TextStyle(fontSize: 10, color: Colors.black45)),
              ],
            ),
            if (canRespond) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDecline,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}