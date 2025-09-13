import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../messages/pages/chat_page.dart';

class MyGigsPage extends StatefulWidget {
  const MyGigsPage({super.key});

  @override
  State<MyGigsPage> createState() => _MyGigsPageState();
}

class _MyGigsPageState extends State<MyGigsPage> {
  final supabase = Supabase.instance.client;
  bool loading = false;
  List<Map<String, dynamic>> gigs = [];

  @override
  void initState() {
    super.initState();
    _loadGigs();
  }

  Future<void> _loadGigs() async {
    setState(() => loading = true);

    try {
      // TODO: Replace with logged-in venueId
      const venueId = "mock-venue-id";

      final response = await supabase
          .from('gigs')
          .select('id, title, date, bookings(id, status, musician_id, musicians(name, avatar_url))')
          .eq('venue_id', venueId);

      setState(() {
        gigs = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint("Error loading gigs: $e");
    }

    setState(() => loading = false);
  }

  Future<void> _updateBookingStatus(
      String bookingId, String chatId, String status, String musicianName, String avatar) async {
    try {
      await supabase
          .from('bookings')
          .update({'status': status})
          .eq('id', bookingId);

      // Insert system message in chat
      await supabase.from('messages').insert({
        'chat_id': chatId,
        'text': status == "confirmed"
            ? "✅ Booking confirmed"
            : "❌ Booking declined",
        'type': 'system',
      });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(
            name: musicianName,
            avatar: avatar,
            initialStatus: status,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error updating booking: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update booking: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("My Gigs"),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkBrown),
      ),
      body: gigs.isEmpty
          ? const Center(child: Text("No gigs found"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: gigs.length,
              itemBuilder: (context, i) {
                final gig = gigs[i];
                final requests = List<Map<String, dynamic>>.from(gig['bookings'] ?? []);

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(gig["title"], style: AppFonts.textTheme.headlineMedium),
                        const SizedBox(height: 4),
                        Text(gig["date"], style: AppFonts.textTheme.bodyMedium),
                        const Divider(height: 20),

                        // Booking requests
                        ...requests.map((req) {
                          final musician = req['musicians'];
                          final musicianName = musician?['name'] ?? "Unknown";
                          final avatar = musician?['avatar_url'] ?? "https://via.placeholder.com/150";
                          final status = req['status'] ?? "pending";

                          return ListTile(
                            leading: CircleAvatar(backgroundImage: NetworkImage(avatar)),
                            title: Text(musicianName, style: AppFonts.textTheme.bodyLarge),
                            subtitle: Text("Status: $status", style: AppFonts.textTheme.bodyMedium),
                            trailing: status == "pending"
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check_circle, color: Colors.green),
                                        onPressed: () => _updateBookingStatus(
                                          req['id'],
                                          req['id'], // 👈 bookingId == chatId if you link them
                                          "confirmed",
                                          musicianName,
                                          avatar,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.cancel, color: Colors.red),
                                        onPressed: () => _updateBookingStatus(
                                          req['id'],
                                          req['id'],
                                          "declined",
                                          musicianName,
                                          avatar,
                                        ),
                                      ),
                                    ],
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.chat, color: AppColors.accentBrown),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ChatPage(
                                            name: musicianName,
                                            avatar: avatar,
                                            initialStatus: status,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
