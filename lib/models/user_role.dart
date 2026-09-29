enum UserRole {
  admin,
  customer,
  staff,
  veterinarian,
}

extension UserRoleX on UserRole {
  String get value {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.customer:
        return 'customer';
      case UserRole.staff:
        return 'staff';
      case UserRole.veterinarian:
        return 'veterinarian';
    }
  }

  static UserRole? fromValue(String? value) {
    if (value == null) return null;

    final normalized = value.trim().toLowerCase();

    switch (normalized) {
      case 'admin':
      case 'administrator':
        return UserRole.admin;

      // Support both spec format and common variants.
      case 'customer':
      case 'pet_owner':
      case 'petowner':
      case 'pet-owner':
        return UserRole.customer;

      case 'staff':
        return UserRole.staff;

      case 'veterinarian':
      case 'vet':
      case 'veterninarian': // tolerate common misspell
        return UserRole.veterinarian;

      default:
        return null;
    }
  }
}
