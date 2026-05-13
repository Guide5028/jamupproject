// Shared validation logic for file uploads (avatar + portfolio).
// Pure Dart — no Flutter, no Supabase, no dart:io — fully unit-testable.

const _avatarExtensions = ['jpg', 'jpeg', 'png'];
const _portfolioImageExtensions = ['jpg', 'jpeg', 'png', 'webp'];
const _portfolioVideoExtensions = ['mp4', 'mov', 'avi', 'mkv'];

/// Extracts the lowercase file extension from a full file path.
/// e.g. "/tmp/photo.JPG" → "jpg"
String extractExtension(String filePath) {
  return filePath.split('.').last.toLowerCase();
}

/// Returns true if the extension is allowed for avatar uploads.
/// Only still-image formats — no videos, no WebP.
bool isValidAvatarExtension(String ext) {
  return _avatarExtensions.contains(ext);
}

/// Returns true if the extension is allowed for portfolio uploads.
/// Includes both image and video formats.
bool isValidPortfolioExtension(String ext) {
  return _portfolioImageExtensions.contains(ext) ||
      _portfolioVideoExtensions.contains(ext);
}

/// Returns true if the extension is a video format.
bool isVideoExtension(String ext) {
  return _portfolioVideoExtensions.contains(ext);
}

/// Maps a file extension to its MIME type string.
/// Used as the contentType in Supabase Storage uploads.
String mimeType(String ext) {
  switch (ext) {
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
      return 'image/jpeg';
  }
}
