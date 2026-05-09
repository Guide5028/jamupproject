// ============================================================================
// create_gig_page.dart   —   Venue creates a new gig
// ============================================================================
// Teacher notes for Guide:
//  • Form is broken into clear SECTIONS (Basics, When, Details, Cover Image,
//    Budget). Long forms without sections feel overwhelming.
//  • We keep ALL state local to this page (`_title`, `_date`, etc.) and
//    only call repo.createGig(...) at the very end. One DB write = one
//    success snackbar = easy to reason about.
//  • Image upload happens BEFORE the row is inserted, so the row gets
//    the final public URL. If the upload fails we abort and never insert
//    a half-broken gig with an empty image field.
// ============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../data/gig_repository.dart';

class CreateGigPage extends StatefulWidget {
  const CreateGigPage({super.key});

  @override
  State<CreateGigPage> createState() => _CreateGigPageState();
}

class _CreateGigPageState extends State<CreateGigPage> {
  final _repo = GigRepository();
  SupabaseClient get _supabase => Supabase.instance.client;
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  // ── text controllers ───────────────────────────────────────────────
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _location = TextEditingController();
  final _payment = TextEditingController();
  final _slots = TextEditingController(text: '1');

  // ── picked-from-UI state ───────────────────────────────────────────
  DateTime? _date;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  double? _latitude;
  double? _longitude;
  File? _coverImage;
  String _roleNeeded = 'Any';
  String _paymentUnit = 'fixed'; // 'per_hour' | 'per_day' | 'fixed'

  // Curated genre list — matches the filter chips on the gigs page.
  // We keep it small so the chip row stays scannable.
  static const _allGenres = <String>[
    'Jazz', 'Rock', 'Pop', 'EDM', 'Hip-Hop',
    'Classical', 'Acoustic', 'R&B', 'Folk', 'Blues',
  ];
  final Set<String> _selectedGenres = {};

  // ── flags ──────────────────────────────────────────────────────────
  bool _saving = false;
  bool _locationError = false;
  bool _dateError = false;
  bool _genresError = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _location.dispose();
    _payment.dispose();
    _slots.dispose();
    super.dispose();
  }

  // ── date + time pickers ────────────────────────────────────────────
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 3)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? _startTime ?? const TimeOfDay(hour: 20, minute: 0)
          : _endTime ?? const TimeOfDay(hour: 23, minute: 0),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  // ── image picking + upload ─────────────────────────────────────────
  Future<void> _pickCoverImage() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85, // compress — saves storage + bandwidth
    );
    if (x != null) setState(() => _coverImage = File(x.path));
  }

  /// Uploads to the `gig_images` bucket under `<user_id>/<timestamp>.<ext>`
  /// so the storage RLS policy matches (folder name = auth.uid()).
  Future<String?> _uploadCoverIfPicked() async {
    if (_coverImage == null) return null;
    final user = _supabase.auth.currentUser!;
    final ext = _coverImage!.path.split('.').last.toLowerCase();
    final path = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _supabase.storage.from('gig_images').upload(
          path,
          _coverImage!,
          fileOptions: const FileOptions(upsert: false),
        );
    return _supabase.storage.from('gig_images').getPublicUrl(path);
  }

  // ── submit ─────────────────────────────────────────────────────────
  Future<void> _save() async {
    // one-pass validation — set ALL errors at once so the user sees
    // everything that's missing on their first tap, not one at a time.
    setState(() {
      _locationError = _latitude == null || _longitude == null;
      _dateError = _date == null;
      _genresError = _selectedGenres.isEmpty;
    });

    if (!_formKey.currentState!.validate()) return;
    if (_locationError || _dateError || _genresError) return;

    setState(() => _saving = true);

    try {
      // Upload cover first; if this throws, we never touch the DB row.
      final imageUrl = await _uploadCoverIfPicked();

      // Combine date + start/end time into full timestamps if present.
      DateTime? startTs;
      DateTime? endTs;
      if (_startTime != null) {
        startTs = DateTime(_date!.year, _date!.month, _date!.day,
            _startTime!.hour, _startTime!.minute);
      }
      if (_endTime != null) {
        endTs = DateTime(_date!.year, _date!.month, _date!.day,
            _endTime!.hour, _endTime!.minute);
      }

      await _repo.createGig(
        title: _title.text.trim(),
        description: _desc.text.trim(),
        date: startTs ?? _date!,
        location: _location.text.trim(),
        genres: _selectedGenres.toList(),
        imageUrl: imageUrl ?? '',
        latitude: _latitude!,
        longitude: _longitude!,
        payment: double.tryParse(_payment.text.trim()),
        paymentUnit: _paymentUnit,
        roleNeeded: _roleNeeded == 'Any' ? null : _roleNeeded,
        slots: int.tryParse(_slots.text.trim()) ?? 1,
        startTime: startTs,
        endTime: endTs,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gig created ✅')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't create gig: $e")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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

  String _fmtTime(TimeOfDay t) =>
      "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

  // ── Build ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Create Gig"),
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
                // ── COVER ─────────────────────────────────────────
                _buildCoverPicker(),

                _sectionHeader('Basics'),
                TextFormField(
                  controller: _title,
                  decoration: _dec('Title', hint: 'e.g. Friday Jazz Night'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Title required' : null,
                ),
                const SizedBox(height: 12),

                GooglePlaceAutoCompleteTextField(
                  textEditingController: _location,
                  googleAPIKey: 'AIzaSyDiiHfZ8hCCWOmzSde6K02wZktjI53wesw',
                  inputDecoration: _dec('Search Location',
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
                if (_locationError)
                  const Padding(
                    padding: EdgeInsets.only(left: 12, top: 4),
                    child: Text(
                      'Pick a location from the suggestions',
                      style: TextStyle(color: Color(0xFFE24B4A), fontSize: 12),
                    ),
                  ),

                const SizedBox(height: 12),
                TextFormField(
                  controller: _desc,
                  maxLines: 4,
                  decoration: _dec('Description',
                      hint: 'Tell musicians what the vibe is...'),
                ),

                // ── WHEN ──────────────────────────────────────────
                _sectionHeader('When'),
                _datePickerTile(),
                if (_dateError)
                  const Padding(
                    padding: EdgeInsets.only(left: 12, top: 4),
                    child: Text(
                      'Pick a date',
                      style: TextStyle(color: Color(0xFFE24B4A), fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _timePickerTile(
                            label: 'Start', time: _startTime, isStart: true)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _timePickerTile(
                            label: 'End', time: _endTime, isStart: false)),
                  ],
                ),

                // ── DETAILS ───────────────────────────────────────
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
                          _genresError = false;
                        });
                      },
                      selectedColor:
                          AppColors.primaryGold.withOpacity(0.25),
                      checkmarkColor: AppColors.darkBrown,
                    );
                  }).toList(),
                ),
                if (_genresError)
                  const Padding(
                    padding: EdgeInsets.only(left: 12, top: 4),
                    child: Text(
                      'Pick at least one genre',
                      style: TextStyle(color: Color(0xFFE24B4A), fontSize: 12),
                    ),
                  ),

                _sectionHeader('Role Needed'),
                DropdownButtonFormField<String>(
                  value: _roleNeeded,
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

                // ── BUDGET ────────────────────────────────────────
                _sectionHeader('Budget'),
                TextFormField(
                  controller: _payment,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: _dec('Pay for musician (฿)',
                      hint: 'e.g. 3000',
                      prefix: const Icon(Icons.payments_outlined)),
                ),
                const SizedBox(height: 10),
                // Rate unit — makes it clear musicians see ฿X/hr or ฿X/day
                _buildPaymentUnitToggle(),

                const SizedBox(height: 24),
                _buildSaveButton(),
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

  Widget _buildCoverPicker() {
    return GestureDetector(
      onTap: _pickCoverImage,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.primaryGold.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.accentBrown.withOpacity(0.3), width: 1),
          image: _coverImage != null
              ? DecorationImage(
                  image: FileImage(_coverImage!), fit: BoxFit.cover)
              : null,
        ),
        child: _coverImage == null
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
                      icon: const Icon(Icons.close,
                          size: 16, color: Colors.white),
                      onPressed: () => setState(() => _coverImage = null),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _datePickerTile() {
    return OutlinedButton.icon(
      icon: const Icon(Icons.calendar_today, size: 18),
      label: Text(
        _date == null ? 'Pick a date' : 'Date: ${_fmtDate(_date!)}',
        style: AppFonts.textTheme.bodyLarge,
      ),
      onPressed: _pickDate,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(
            color: _dateError
                ? const Color(0xFFE24B4A)
                : AppColors.accentBrown),
        foregroundColor: AppColors.darkBrown,
      ),
    );
  }

  Widget _timePickerTile({
    required String label,
    required TimeOfDay? time,
    required bool isStart,
  }) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.access_time, size: 18),
      label: Text(
        time == null ? label : '$label: ${_fmtTime(time)}',
        style: AppFonts.textTheme.bodyMedium,
      ),
      onPressed: () => _pickTime(isStart: isStart),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: AppColors.accentBrown),
        foregroundColor: AppColors.darkBrown,
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGold,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _saving
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Text('Create Gig',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
      ),
    );
  }
}
