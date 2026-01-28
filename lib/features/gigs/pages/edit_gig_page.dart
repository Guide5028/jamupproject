import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../models/gig.dart';
import '../data/gig_repository.dart';

class EditGigPage extends StatefulWidget {
  final Gig gig;
  const EditGigPage({super.key, required this.gig});

  @override
  State<EditGigPage> createState() => _EditGigPageState();
}

class _EditGigPageState extends State<EditGigPage> {
  final repo = GigRepository();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _title;
  late TextEditingController _location;
  late TextEditingController _desc;
  late TextEditingController _genres;
  late TextEditingController _imageUrl;

  DateTime? _date;
  bool saving = false;
  bool deleting = false;

  @override
  void initState() {
    super.initState();
    final g = widget.gig;

    _title = TextEditingController(text: g.title);
    _location = TextEditingController(text: g.location);
    _desc = TextEditingController(text: g.description);
    _genres = TextEditingController(text: g.genres.join(", "));
    _imageUrl = TextEditingController(text: g.imageUrl);
    _date = g.date;
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _desc.dispose();
    _genres.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _date ?? now.add(const Duration(days: 3));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) setState(() => _date = picked);
  }

  String _dateLabel() {
    if (_date == null) return "Pick Date";
    final d = _date!;
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return "Date: ${d.year}-$mm-$dd";
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please pick a date")),
      );
      return;
    }

    setState(() => saving = true);

    try {
      final genres = _genres.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      await repo.updateGig(
        gigId: widget.gig.id,
        title: _title.text.trim(),
        description: _desc.text.trim(),
        date: _date!,
        location: _location.text.trim(),
        genres: genres,
        imageUrl: _imageUrl.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context, true); // ✅ return "changed"
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gig updated ✅")),
      );
      await Future.delayed(const Duration(milliseconds: 300));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed: $e")),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Delete gig?"),
          content: const Text("This will permanently delete this gig."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text("Delete", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    setState(() => deleting = true);

    try {
      await repo.deleteGig(widget.gig.id);

      if (!mounted) return;
      Navigator.pop(context, true); // ✅ return "changed"
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gig deleted ✅")),
      );
      await Future.delayed(const Duration(milliseconds: 300));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn’t delete gig $e")),
      );
    } finally {
      if (mounted) setState(() => deleting = false);
    }
  }

  InputDecoration _dec(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Edit Gig"),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkBrown),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // ===== BASIC INFO =====
                Text("Basic Info", style: AppFonts.textTheme.headlineMedium),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _title,
                  decoration: _dec("Title"),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? "Title required" : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _location,
                  decoration: _dec("Location"),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? "Location required"
                      : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _desc,
                  maxLines: 4,
                  decoration:
                      _dec("Description", hint: "Describe the event..."),
                ),
                const SizedBox(height: 18),

                // ===== DATE =====
                Text("Schedule", style: AppFonts.textTheme.headlineMedium),
                const SizedBox(height: 10),

                OutlinedButton.icon(
                  onPressed: saving || deleting ? null : _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label:
                      Text(_dateLabel(), style: AppFonts.textTheme.bodyLarge),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: AppColors.accentBrown),
                    foregroundColor: AppColors.darkBrown,
                  ),
                ),
                const SizedBox(height: 18),

                // ===== DETAILS =====
                Text("Details", style: AppFonts.textTheme.headlineMedium),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _genres,
                  decoration:
                      _dec("Genres (comma separated)", hint: "Jazz, EDM"),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _imageUrl,
                  decoration: _dec("Image URL (optional)"),
                ),
                const SizedBox(height: 22),

                // ===== ACTIONS =====
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: (saving || deleting) ? null : _save,
                    child: saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Save Changes",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                // Professional delete area
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Danger Zone",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Deleting a gig cannot be undone.",
                        style: AppFonts.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: (saving || deleting) ? null : _delete,
                          icon: deleting
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.red,
                                  ),
                                )
                              : const Icon(Icons.delete_outline),
                          label: Text(deleting ? "Deleting..." : "Delete Gig"),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
