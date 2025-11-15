// lib/config/admin.dart
// Lightweight admin config for small local admin controls.
// Set `kRestrictAnalyticsToOwners` to true to only allow analytics events
// for the listed owner UIDs or emails. Keep false for normal operation.

// By default restrict analytics to owners. Set to `true` to allow analytics
// only for the owner accounts listed below. Set to `false` to allow normal
// per-user analytics behavior.
const bool kRestrictAnalyticsToOwners = true;

/// If restricting analytics, list the owner UIDs here (preferred).
const List<String> kOwnerAnalyticsUids = [
  // Add your Firebase Auth UID here, e.g. 'abcdef123456...'
];

/// Optionally list owner emails (used as fallback if UID unknown).
const List<String> kOwnerAnalyticsEmails = ['hotcupofjoe2013@gmail.com'];
