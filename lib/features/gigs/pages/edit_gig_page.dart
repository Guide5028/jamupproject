// ============================================================================
// edit_gig_page.dart   —   Venue edits one of their own gigs
// ============================================================================
// Teacher notes for Guide:
//  • Mirrors create_gig_page.dart on purpose. Consistent UI = less surprise
//    for the user, and shared muscle memory for us when we maintain it.
//  • The incoming `Gig` already has title / date / genres / image_url, so
//    we pre-fill every control in initState from widget.gig.
//  • Danger Zone stays at the bottom because destructive actions should
//    never be the thing you accidentally tap on the primary focus area.
// ============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../models/gig.dart';
import '../data/gig_repository.dart';

class EditGigPage extends StatefulWidget {
  final Gig gig;
  final GigRepository? repo;
  const EditGigPage({super.key, required this.gig, this.repo});

  @override
  State<EditGigPage> createState() => _EditGigPageState();
}

class _EditGigPageState extends State<EditGigPage> {
  late final GigRepository _repo;
  SupabaseClient get _supabase => Supabase.instance.client;
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _title;
  late TextEditingController _desc;
  late TextEditingController _location;
  late TextEditingController _payment;
  late TextEditingController _slots;

  DateTime? _date;
  double? _latitude;
  double? _longitude;
  String? _existingImageUrl; // URL already stored on the gig row
  File? _newCoverImage;      // new file picked this session
  String _roleNeeded = 'Any';
  String _paymentUnit = 'fixed';

  static const _allGenres = <String>[
    'Jazz', 'Rock', 'Pop', 'EDM', 'Hip-Hop',
    'Classical', 'Acoustic', 'R&B', 'Folk', 'Blues',
  ];
  final Set<String> _selectedGenres = {};

  bool _saving = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _repo = widget.repo ?? GigRepository();
    final g = widget.gig;

    _title    = TextEditingController(text: g.title);
    _desc     = TextEditingController(text: g.description);
    _location = TextEditingController(text: g.location);
    _payment  = TextEditingController(
        text: g.payment != null ? g.payment!.toStringAsFixed(0) : '');
    _slots    = TextEditingController(text: g.slots.toString());

    _date            = g.date;
    _latitude        = g.latitude;
    _longitude       = g.longitude;
    _existingImageUrl = g.imageUrl.isNotEmpty ? g.imageUrl : null;
    _selectedGenres.addAll(g.genres);
    _roleNeeded      = g.roleNeeded.isNotEmpty ? g.roleNeeded : 'Any';
    _paymentUnit     = g.paymentUnit ?? 'fixed';
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _location.dispose();
    _payment.dispose();
    _slots.dispose();
    super.dispose();
  }

  // ── pickers ────────────────────────────────────────────────────────
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

  Future<void> _pickCover() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x != null) setState(() => _newCoverImage = File(x.path));
  }

  Future<String?> _uploadNewCoverIfPicked() async {
    if (_newCoverImage == null) return null;
    final user = _supabase.auth.currentUser!;
    final ext = _newCoverImage!.path.split('.').last.toLowerCase();
    final path = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _supabase.storage.from('gig_images').upload(
          path,
          _newCoverImage!,
          fileOptions: const FileOptions(upsert: false),
        );
    return _supabase.storage.from('gig_images').getPublicUrl(path);
  }

  // ── save ──────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null) {
      _snack('Please pick a date');
      return;
    }
    if (_selectedGenres.isEmpty) {
      _snack('Pick at least one genre');
      return;
    }

    setState(() => _saving = true);

    try {
      final newLocation = _location.text.trim();
      double? newLat = _latitude;
      double? newLng = _longitude;

      if (newLocation != widget.gig.location) {
        try {
          final results = await locationFromAddress(newLocation);
          if (results.isNotEmpty) {
            newLat = results.first.latitude;
            newLng = results.first.longitude;
          }
        } catch (_) {
          // geocoding failed — keep original coordinates
        }
      }

      final newUrl = await _uploadNewCoverIfPicked();
      final finalImageUrl = newUrl ?? _existingImageUrl ?? '';

      await _repo.updateGig(
        gigId: widget.gig.id,
        title: _title.text.trim(),
        description: _desc.text.trim(),
        date: _date!,
        location: newLocation,
        genres: _selectedGenres.toList(),
        imageUrl: finalImageUrl,
        latitude: newLat,
        longitude: newLng,
        payment: double.tryParse(_payment.text.trim()),
        paymentUnit: _paymentUnit,
        roleNeeded: _roleNeeded == 'Any' ? null : _roleNeeded,
        slots: int.tryParse(_slots.text.trim()),
      );

      if (!mounted) return;
      _snack('Gig updated ✅');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _snack('Update failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── delete ─────────────────────────────────────────────────────────
  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Delete gig?'),
          content:
              const Text('This will permanently delete this gig.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE24B4A)),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    setState(() => _deleting = true);
    try {
      await _repo.deleteGig(widget.gig.id);
      if (!mounted) return;
      _snack('Gig deleted ✅');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _snack("Couldn't delete gig: $e");
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }

  // ── UI helpers ─────────────────────────────────────────────────────
  InputDecoration _dec(String label, {String? hint, Widget? prefix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _sectionHeader(String text) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 10),
        child: Text(text, style: AppFonts.textTheme.headlineMedium),
      );

  String _fmtDate(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  // ── Build ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Gig'),
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
                _buildCover(),

                _sectionHeader('Basics'),
                TextFormField(
                  controller: _title,
                  decoration: _dec('Title'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Title required'
                      : null,
                ),
                const SizedBox(height: 12),

                // We show a Google Places field so the venue can RE-pick a
                // location (re-setting _latitude/_longitude). The current
                // text value comes from the existing gig.
                GooglePlaceAutoCompleteTextField(
                  textEditingController: _location,
                  googleAPIKey: 'AIzaSyDiiHfZ8hCCWOmzSde6K02wZktjI53wesw',
                  inputDecoration: _dec('Location',
                      prefix: const Icon(Icons.location_on_outlined)),
                  debounceTime: 800,
                  countries: const ['th'],
                  isLatLngRequired: true,
                  getPlaceDetailWithLatLng: (p) {
                    if (p.lat != null && p.lng != null) {
                      _latitude = double.tryParse(p.lat!);
                      _longitude = double.tryParse(p.lng!);
                    }
                  },
                  itemClick: (p) {
                    _location.text = p.description ?? '';
                    _location.selection = TextSelection.fromPosition(
                      TextPosition(offset: (p.description ?? '').length),
                    );
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _desc,
                  maxLines: 4,
                  decoration: _dec('Description'),
                ),

                _sectionHeader('When'),
                OutlinedButton.icon(
                  onPressed: _saving || _deleting ? null : _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    _date == null ? 'Pick a date' : 'Date: ${_fmtDate(_date!)}',
                    style: AppFonts.textTheme.bodyLarge,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: AppColors.accentBrown),
                    foregroundColor: AppColors.darkBrown,
                  ),
                ),

                _sectionHeader('Genres'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _allGenres.map((g) {
                    final selected = _selectedGenres.contains(g);
                    return FilterChip(
                      label: Text(g),
                      selected: selected,
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedGenres.add(g);
                          } else {
                            _selectedGenres.remove(g);
                          }
                        });
                      },
                      selectedColor:
                          AppColors.primaryGold.withOpacity(0.25),
                      checkmarkColor: AppColors.darkBrown,
                    );
                  }).toList(),
                ),

                _sectionHeader('Role Needed'),
                DropdownButtonFormField<String>(
                  value: ['Any', 'Singer', 'Guitarist', 'Pianist',
                          'Drummer', 'DJ', 'Band']
                      .contains(_roleNeeded)
                      ? _roleNeeded
                      : 'Any',
                  decoration: _dec('Looking for'),
                  items: const [
                    DropdownMenuItem(value: 'Any', child: Text('Any musician')),
                    DropdownMenuItem(value: 'Singer', child: Text('Singer')),
                    DropdownMenuItem(value: 'Guitarist', child: Text('Guitarist')),
                    DropdownMenuItem(value: 'Pianist', child: Text('Pianist')),
                    DropdownMenuItem(value: 'Drummer', child: Text('Drummer')),
                    DropdownMenuItem(value: 'DJ', child: Text('DJ')),
                    DropdownMenuItem(value: 'Band', child: Text('Full band')),
                  ],
                  onChanged: (v) => setState(() => _roleNeeded = v ?? 'Any'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _slots,
                  keyboardType: TextInputType.number,
                  decoration: _dec('Slots available',
                      prefix: const Icon(Icons.group_outlined)),
                ),

                _sectionHeader('Budget'),
                TextFormField(
                  controller: _payment,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: _dec('Pay for musician (฿)',
                      prefix: const Icon(Icons.payments_outlined)),
                ),
                const SizedBox(height: 10),
                _buildPaymentUnitToggle(),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const Key('save_gig_button'),
                    onPressed: (_saving || _deleting) ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save Changes',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                  ),
                ),

                const SizedBox(height: 16),
                _buildDangerZone(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentUnitToggle() {
    const units = [
      ('fixed',    'Fixed total'),
      ('per_hour', 'Per hour'),
      ('per_day',  'Per day'),
    ];
    return Row(
      children: units.map((u) {
        final isSelected = _paymentUnit == u.$1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => setState(() => _paymentUnit = u.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryGold
                      : AppColors.primaryGold.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryGold
                        : AppColors.accentBrown.withOpacity(0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    u.$2,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.darkBrown,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCover() {
    final hasNew = _newCoverImage != null;
    final hasOld = _existingImageUrl != null && _existingImageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: _pickCover,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.primaryGold.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.accentBrown.withOpacity(0.3), width: 1),
          image: hasNew
              ? DecorationImage(
                  image: FileImage(_newCoverImage!), fit: BoxFit.cover)
              : hasOld
                  ? DecorationImage(
                      image: NetworkImage(_existingImageUrl!),
                      fit: BoxFit.cover)
                  : null,
        ),
        child: (!hasNew && !hasOld)
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_photo_alternate_outlined,
                      size: 40, color: AppColors.primaryGold),
                  const SizedBox(height: 6),
                  Text('Tap to add cover image',
                      style: AppFonts.textTheme.bodyMedium),
                ],
              )
            : Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.black45,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.edit,
                          size: 16, color: Colors.white),
                      onPressed: _pickCover,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildDangerZone() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE24B4A).withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE24B4A).withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Danger Zone',
              style: AppFonts.textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFFE24B4A),
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Deleting a gig cannot be undone.',
              style: AppFonts.textTheme.bodyMedium),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE24B4A),
                side: const BorderSide(color: Color(0xFFE24B4A)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: (_saving || _deleting) ? null : _delete,
              icon: _deleting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFFE24B4A)),
                    )
                  : const Icon(Icons.delete_outline),
              label: Text(_deleting ? 'Deleting...' : 'Delete Gig'),
            ),
          ),
        ],
      ),
    );
  }
}
