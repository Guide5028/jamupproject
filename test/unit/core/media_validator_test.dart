import 'package:flutter_test/flutter_test.dart';
import 'package:jamup_app/core/utils/media_validator.dart';

void main() {
  // ── extractExtension ────────────────────────────────────────────────
  group('extractExtension', () {
    test('returns lowercase extension from a simple path', () {
      expect(extractExtension('/tmp/photo.jpg'), 'jpg');
    });

    test('converts uppercase to lowercase', () {
      // Users pick files from their camera roll — file names are often
      // uppercase on iOS (e.g. IMG_0001.JPG). The validator must still
      // accept them without the user knowing anything went wrong.
      expect(extractExtension('/storage/IMG_001.JPG'), 'jpg');
    });

    test('handles paths with multiple dots', () {
      // A path like "my.photo.backup.png" — only the LAST segment matters.
      expect(extractExtension('/tmp/my.photo.backup.png'), 'png');
    });
  });

  // ── isValidAvatarExtension ─────────────────────────────────────────
  group('isValidAvatarExtension', () {
    test('accepts jpg', () => expect(isValidAvatarExtension('jpg'), isTrue));
    test('accepts jpeg', () => expect(isValidAvatarExtension('jpeg'), isTrue));
    test('accepts png', () => expect(isValidAvatarExtension('png'), isTrue));

    test('rejects webp', () {
      // WebP is great for the web but not universally supported by Supabase
      // avatar rendering pipelines. Keep it blocked for avatars.
      expect(isValidAvatarExtension('webp'), isFalse);
    });

    test('rejects mp4', () => expect(isValidAvatarExtension('mp4'), isFalse));
    test('rejects gif', () => expect(isValidAvatarExtension('gif'), isFalse));
    test('rejects pdf', () => expect(isValidAvatarExtension('pdf'), isFalse));
  });

  // ── isValidPortfolioExtension ──────────────────────────────────────
  group('isValidPortfolioExtension', () {
    // Portfolio accepts both images and videos so musicians can show
    // photos AND performance clips.
    test('accepts jpg', () => expect(isValidPortfolioExtension('jpg'), isTrue));
    test('accepts png', () => expect(isValidPortfolioExtension('png'), isTrue));
    test('accepts webp', () => expect(isValidPortfolioExtension('webp'), isTrue));
    test('accepts mp4', () => expect(isValidPortfolioExtension('mp4'), isTrue));
    test('accepts mov', () => expect(isValidPortfolioExtension('mov'), isTrue));
    test('accepts avi', () => expect(isValidPortfolioExtension('avi'), isTrue));
    test('accepts mkv', () => expect(isValidPortfolioExtension('mkv'), isTrue));

    test('rejects pdf', () => expect(isValidPortfolioExtension('pdf'), isFalse));
    test('rejects exe', () => expect(isValidPortfolioExtension('exe'), isFalse));
    test('rejects unknown extension', () {
      expect(isValidPortfolioExtension('xyz'), isFalse);
    });
  });

  // ── isVideoExtension ──────────────────────────────────────────────
  group('isVideoExtension', () {
    test('mp4 is video', () => expect(isVideoExtension('mp4'), isTrue));
    test('mov is video', () => expect(isVideoExtension('mov'), isTrue));
    test('jpg is NOT video', () => expect(isVideoExtension('jpg'), isFalse));
    test('png is NOT video', () => expect(isVideoExtension('png'), isFalse));
  });

  // ── mimeType ──────────────────────────────────────────────────────
  group('mimeType', () {
    // mimeType() is critical: if it returns the wrong string, Supabase
    // Storage stores the file with the wrong Content-Type header. That
    // causes browsers/apps to try to render a video as an image (or
    // vice versa) — a silent but very visible bug.
    test('jpg → image/jpeg', () => expect(mimeType('jpg'), 'image/jpeg'));
    test('jpeg → image/jpeg', () => expect(mimeType('jpeg'), 'image/jpeg'));
    test('png → image/png', () => expect(mimeType('png'), 'image/png'));
    test('webp → image/webp', () => expect(mimeType('webp'), 'image/webp'));
    test('mp4 → video/mp4', () => expect(mimeType('mp4'), 'video/mp4'));
    test('mov → video/quicktime', () {
      expect(mimeType('mov'), 'video/quicktime');
    });
    test('unknown extension falls back to image/jpeg', () {
      // The fallback is a safe default — better to upload with a wrong
      // MIME type than to crash the upload entirely.
      expect(mimeType('xyz'), 'image/jpeg');
    });
  });
}
