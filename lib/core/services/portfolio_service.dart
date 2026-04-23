import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';


class PortfolioService {

  final _supabase = Supabase.instance.client;

  Future<void> uploadPortfolioItem({
    required File file,
    required String userId,
    String? description,
  }) async {

    final extension = file.path.split('.').last.toLowerCase();
    final isVideo = ['mp4', 'mov', 'avi', 'mkv'].contains(extension);
    final mediaType = isVideo ? 'video' : 'image';

    final mimeType = _mimeType(extension);

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
    final storagePath = '$userId/$fileName';

    // Step 1: Upload file to the 'portfolio' bucket
    await _supabase.storage.from('portfolio').upload(
          storagePath,
          file,
          fileOptions: FileOptions(
            contentType: mimeType,
            upsert: false, // don't silently overwrite if path already exists
          ),
        );

    // Step 2: Get the permanent public URL for the uploaded file
    final publicUrl =
        _supabase.storage.from('portfolio').getPublicUrl(storagePath);

    // Step 3: Save metadata to the portfolio table
    await _supabase.from('portfolio').insert({
      'user_id': userId,
      'media_url': publicUrl,
      'media_type': mediaType,
      'description': description,
    });
  }

  Future<List<Map<String, dynamic>>> fetchPortfolio(String userId) async {
    final response = await _supabase
        .from('portfolio')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    // Supabase returns List<dynamic> — we cast to the correct type.
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> deletePortfolioItem({
    required String portfolioId,
    required String mediaUrl,
    required String userId,
  }) async {
    
    final uri = Uri.parse(mediaUrl);
    final segments = uri.pathSegments;

    // Find 'portfolio' in the path segments, then take everything after it.
    final bucketIndex = segments.indexOf('portfolio');
    final storagePath = segments.sublist(bucketIndex + 1).join('/');

    // Step 1: Remove file from Storage
    await _supabase.storage.from('portfolio').remove([storagePath]);

    // Step 2: Remove row from the portfolio table
    await _supabase
        .from('portfolio')
        .delete()
        .eq('id', portfolioId)
        .eq('user_id', userId); // extra safety: only delete your own rows
  }

  String _mimeType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      default:
        return 'image/jpeg'; // safe fallback
    }
  }
}