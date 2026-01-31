enum UserRole {
  stationMaster,
  fieldOfficer,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.stationMaster:
        return 'Station Master';
      case UserRole.fieldOfficer:
        return 'Field Officer';
    }
  }

  String get value {
    switch (this) {
      case UserRole.stationMaster:
        return 'station_master';
      case UserRole.fieldOfficer:
        return 'field_officer';
    }
  }

  static UserRole fromString(String role) {
    switch (role) {
      case 'station_master':
        return UserRole.stationMaster;
      case 'field_officer':
        return UserRole.fieldOfficer;
      default:
        return UserRole.fieldOfficer;
    }
  }

  static UserRole determineRoleFromEmail(String email) {
    if (email.toLowerCase() == 'stationmaster@gmail.com') {
      return UserRole.stationMaster;
    } else if (email.toLowerCase() == 'fieldofficer@gmail.com') {
      return UserRole.fieldOfficer;
    } else {
      // Default to field officer for any other email
      return UserRole.fieldOfficer;
    }
  }
}
