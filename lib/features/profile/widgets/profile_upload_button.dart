import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jamup_app/core/constants/app_colors.dart';
import 'package:jamup_app/core/services/portfolio_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// This widget lives in features/profile/widgets/ because ONLY
// your own profile page needs an upload button.
// The musician_detail_page (viewed by venues) is read-only.

class PortfolioUploadButton extends StatefulWidget {
  final VoidCallback onUploadComplete;

  const PortfolioUploadButton({super.key, required this.onUploadComplete});

  @override
  State<PortfolioUploadButton> createState() => _PortfolioUploadButtonState();
}

class _PortfolioUploadButtonState extends State<PortfolioUploadButton> {
  final _picker = ImagePicker();
  final _service = PortfolioService();
  bool _isUploading = false;

  Future<void> _pickAndUpload(bool isVideo) async {
    // Pick image or video from gallery
    final XFile? picked = isVideo
        ? await _picker.pickVideo(source: ImageSource.gallery)
        : await _picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 85, // compress to save storage
          );

    if (picked == null) return; // user cancelled picker

    setState(() => _isUploading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      await _service.uploadPortfolioItem(
        file: File(picked.path),
        userId: userId,
      );

      widget.onUploadComplete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Portfolio item uploaded!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.photo_outlined, color: AppColors.darkBrown),
              title: const Text('Upload photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUpload(false);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.videocam_outlined, color: AppColors.darkBrown),
              title: const Text('Upload video'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUpload(true);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isUploading) {
      return const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return OutlinedButton.icon(
      onPressed: _showOptions,
      icon: const Icon(Icons.add, color: AppColors.primaryGold),
      label: const Text(
        'Add to Portfolio',
        style: TextStyle(color: AppColors.darkBrown),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.primaryGold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }
}