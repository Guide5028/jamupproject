import 'package:flutter/material.dart';
import 'package:jamup_app/features/booking/data/booking_repository.dart';
import 'package:jamup_app/models/gig.dart';

import '../controllers/booking_controller.dart';
import '../../../core/constants/app_colors.dart';

class CreateBookingPage extends StatefulWidget {
  final Gig gig;

  const CreateBookingPage({super.key, required this.gig});

  @override
  State<CreateBookingPage> createState() => _CreateBookingPageState();
}

class _CreateBookingPageState extends State<CreateBookingPage> {
  DateTime? selectedDate;

  final _controller = BookingController(BookingRepository());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Request Booking"),
        backgroundColor: AppColors.background,
      ),
      body: Padding(
  padding: const EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Request Booking",
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 12),

      Text("Gig"),
      Text(widget.gig.title, style: const TextStyle(fontWeight: FontWeight.bold)),

      const SizedBox(height: 8),
      Text("Date"),
      Text(widget.gig.date.toLocal().toString()),

      const SizedBox(height: 8),
      Text("Location"),
      Text(widget.gig.location),

      const Spacer(),

      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            // Same capture-before-await pattern as elsewhere — grab the
            // Navigator now so we don't touch `context` after the gap.
            final navigator = Navigator.of(context);
            await _controller.createBookingForGig(
              gigId: widget.gig.id,
              venueId: widget.gig.venueId,
              startTime: widget.gig.date,
              endTime: widget.gig.date.add(const Duration(hours: 2)),
            );
            if (!mounted) return;
            navigator.pop();
          },
          child: const Text("Send Booking Request"),
        ),
      ),
    ],
  ),
),

    );
  }
}