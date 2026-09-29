/// Catalog of veterinary clinic services offered for appointments.
/// Shared by the appointment form, dashboards, and reports so the list
/// stays consistent across the system.
class VetServices {
  VetServices._();

  /// All services the clinic offers (display label == stored value).
  static const List<String> all = [
    'General Consultation',
    'Vaccination',
    'Deworming',
    'Grooming & Bath',
    'Dental Cleaning',
    'Spay/Neuter Surgery',
    'Laboratory Tests',
    'X-Ray / Ultrasound',
    'Allergy Testing',
    'Microchipping',
    'Nail & Ear Care',
    'Nutritional Counseling',
    'Behavioral Consultation',
    'Pet Boarding / Daycare',
    'Emergency Care',
    'Follow-up Checkup',
    'Other Service',
  ];

  /// Services that typically require a follow-up visit.
  static const List<String> requiresFollowUp = [
    'Vaccination',
    'Deworming',
    'Spay/Neuter Surgery',
    'Dental Cleaning',
  ];
}
