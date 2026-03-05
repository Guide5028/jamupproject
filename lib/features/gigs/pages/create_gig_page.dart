import 'package:flutter/material.dart';
import 'package:google_places_flutter/google_places_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';

import '../data/gig_repository.dart';

class CreateGigPage extends StatefulWidget {
  const CreateGigPage({super.key});

  @override
  State<CreateGigPage> createState() => _CreateGigPageState();
}

class _CreateGigPageState extends State<CreateGigPage> {
  final repo = GigRepository();
  final _formKey = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _location = TextEditingController();
  final _genres = TextEditingController();
  final _imageUrl = TextEditingController();

  double? _latitude;
  double? _longitude;

  DateTime? _date;
  bool saving = false;

  @override
void initState() {
  super.initState();

  _location.addListener(() {
    _latitude = null;
    _longitude = null;
  });
}

@override
void dispose() {
  _title.dispose();
  _desc.dispose();
  _location.dispose();
  _genres.dispose();
  _imageUrl.dispose();
  super.dispose();
}


  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 3)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a location from suggestions"),
        ),
      );
      return;
    }

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

      await repo.createGig(
        title: _title.text.trim(),
        description: _desc.text.trim(),
        date: _date!,
        location: _location.text.trim(),
        genres: genres,
        imageUrl: _imageUrl.text.trim(),
        latitude: _latitude!, // already from Google Places
        longitude: _longitude!, // already from Google Places
      );

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gig created ✅")),
      );

      await Future.delayed(const Duration(milliseconds: 300));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn’t create gig $e")),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Create Gig"),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(
                    labelText: "Title", border: OutlineInputBorder()),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? "Title required" : null,
              ),
              const SizedBox(height: 12),
              GooglePlaceAutoCompleteTextField(
                textEditingController: _location,
                googleAPIKey: "AIzaSyDiiHfZ8hCCWOmzSde6K02wZktjI53wesw",
                inputDecoration: const InputDecoration(
                  labelText: "Search Location",
                  border: OutlineInputBorder(),
                ),
                debounceTime: 800,
                countries: ["th"],
                isLatLngRequired: true,
                getPlaceDetailWithLatLng: (prediction) {
                  if (prediction.lat != null && prediction.lng != null) {
                    _latitude = double.tryParse(prediction.lat!);
                    _longitude = double.tryParse(prediction.lng!);
                  }
                },
                itemClick: (prediction) {
                  _location.text = prediction.description!;
                  _location.selection = TextSelection.fromPosition(
                    TextPosition(offset: prediction.description!.length),
                  );
                },
                
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _desc,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: "Description", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _pickDate,
                child: Text(
                    _date == null
                        ? "Pick Date"
                        : "Date: ${_date!.toString().substring(0, 10)}",
                    style: AppFonts.textTheme.bodyLarge),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _genres,
                decoration: const InputDecoration(
                  labelText: "Genres (comma separated)",
                  hintText: "Jazz, EDM",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageUrl,
                decoration: const InputDecoration(
                  labelText: "Image URL (optional)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: saving ? null : _save,
                  child: saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text("Create",
                          style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
