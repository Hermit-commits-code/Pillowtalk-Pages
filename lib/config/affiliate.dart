// filepath: lib/config/affiliate.dart

/// Affiliate configuration and helpers for Amazon links.
///
/// Set `kAmazonAffiliateTag` to your Associates tag (e.g. `yourtag-20`) when ready.
const String? kAmazonAffiliateTag =
    null; // <-- Set your affiliate tag here when ready

const String kAffiliateDisclosure =
    'Spicy Reads participates in the Amazon Services LLC Associates Program and may earn from qualifying purchases.';

/// Build a search URL on Amazon for title + author, optionally including the affiliate tag.
Uri buildAmazonSearchUrl(String title, String author, String? tag) {
  final query = '${title.trim()} ${author.trim()}'.trim();
  final params = <String, String>{'k': query};
  if (tag != null && tag.isNotEmpty) params['tag'] = tag;
  return Uri.https('www.amazon.com', '/s', params);
}

/// Build a direct product URL on Amazon using ASIN, optionally including the affiliate tag.
Uri buildAmazonProductUrl(String asin, String? tag) {
  final params = <String, String>{};
  if (tag != null && tag.isNotEmpty) params['tag'] = tag;
  return Uri.https(
    'www.amazon.com',
    '/dp/$asin',
    params.isNotEmpty ? params : null,
  );
}
