import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/media_validator.dart';


class PortfolioService {

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<void> uploadPortfolioItem({
    required File file,
    required String userId,
    String? description,
  }) async {

    final extension = extractExtension(file.path);
    if (!isValidPortfolioExtension(extension)) {
      throw Exception('Unsupported file type: .$extension');
    }
    final mediaType = isVideoExtension(extension) ? 'video' : 'image';
    final mime = mimeType(extension);

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
    final storagePath = '$userId/$fileName';

    // Step 1: Upload file to the 'portfolio' bucket
    await _supabase.storage.from('portfolio').upload(
          storagePath,
          file,
          fileOptions: FileOptions(
            contentType: mime,
            upsert: false,
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

}