/// Admin, Staff, and Veterinarian verification configuration.
///
/// DEVELOPMENT:
/// Uses the hardcoded codes below if no --dart-define values are provided.
///
/// PRODUCTION:
/// Pass the codes using:
///
/// flutter run --dart-define=ADMIN_VERIFICATION_CODE=your_admin_code \
///             --dart-define=STAFF_VERIFICATION_CODE=your_staff_code \
///             --dart-define=VETERINARIAN_CODE=your_vet_code
///
/// or load them from Firebase Remote Config.

library;

// ================================
// Default Development Codes
// ================================

const String kAdminVerificationCode = 'admin_code123';
const String kStaffVerificationCode = 'staff_code123';
const String kVeterinarianVerificationCode = 'vet_code123';

// ================================
// Verification Code Getters
// ================================

String get adminVerificationCode {
  return const String.fromEnvironment(
    'ADMIN_VERIFICATION_CODE',
    defaultValue: kAdminVerificationCode,
  );
}

String get staffVerificationCode {
  return const String.fromEnvironment(
    'STAFF_VERIFICATION_CODE',
    defaultValue: kStaffVerificationCode,
  );
}

String get veterinarianVerificationCode {
  return const String.fromEnvironment(
    'VETERINARIAN_CODE',
    defaultValue: kVeterinarianVerificationCode,
  );
}
