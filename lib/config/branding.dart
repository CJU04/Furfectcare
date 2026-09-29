/// Centralized branding and design tokens for Furfectcare.
///
/// Keep every user-visible product label here so the app name stays
/// consistent across login, registration, notifications, dialogs, and
/// page titles without hunting for one-off strings.
library;

class AppBranding {
  AppBranding._();

  /// Public-facing product name used everywhere in the UI.
  static const String appName = 'Furfectcare';

  /// Short-form used where space is tight (drawer header, notification text).
  static const String appShortName = 'Furfectcare';

  /// Tagline shown on auth/splash surfaces.
  static const String tagline = 'Caring for the pets you love';

  /// Notification channel / local-notification display name.
  static const String notificationsChannelName = 'Furfectcare Notifications';

  /// Roles (kept in sync with UserRole enum values) used in labels.
  static const String roleAdmin = 'Admin';
  static const String roleStaff = 'Staff';
  static const String roleVeterinarian = 'Veterinarian';
  static const String roleCustomer = 'Pet Owner';
}
