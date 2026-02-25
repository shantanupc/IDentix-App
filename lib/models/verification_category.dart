import 'package:flutter/material.dart';

enum VerificationCategory {
  fullIdentity,
  ageVerification,
  branchVerification,
  yearVerification,
  aadharVerification,
}

extension VerificationCategoryExtension on VerificationCategory {
  String get displayName {
    switch (this) {
      case VerificationCategory.fullIdentity:
        return 'Full Identity';
      case VerificationCategory.ageVerification:
        return 'Age Verification';
      case VerificationCategory.branchVerification:
        return 'Branch Verification';
      case VerificationCategory.yearVerification:
        return 'Year Verification';
      case VerificationCategory.aadharVerification:
        return 'Aadhar Verification';
    }
  }

  String get description {
    switch (this) {
      case VerificationCategory.fullIdentity:
        return 'Verify all identity details';
      case VerificationCategory.ageVerification:
        return 'Verify user is above 18 years';
      case VerificationCategory.branchVerification:
        return 'Verify user\'s branch/department';
      case VerificationCategory.yearVerification:
        return 'Verify user\'s academic year';
      case VerificationCategory.aadharVerification:
        return 'Verify Aadhar details';
    }
  }

  IconData get icon {
    switch (this) {
      case VerificationCategory.fullIdentity:
        return Icons.verified_user;
      case VerificationCategory.ageVerification:
        return Icons.calendar_today;
      case VerificationCategory.branchVerification:
        return Icons.school;
      case VerificationCategory.yearVerification:
        return Icons.date_range;
      case VerificationCategory.aadharVerification:
        return Icons.credit_card;
    }
  }

  String get successMessage {
    switch (this) {
      case VerificationCategory.fullIdentity:
        return 'All identity details verified successfully.';
      case VerificationCategory.ageVerification:
        return 'User is above 18 years of age.';
      case VerificationCategory.branchVerification:
        return 'User belongs to the specified branch.';
      case VerificationCategory.yearVerification:
        return 'User\'s academic year verified.';
      case VerificationCategory.aadharVerification:
        return 'Aadhar details verified successfully.';
    }
  }
}

enum UseCase {
  collegeVerification,
  hotelCheckIn,
}

extension UseCaseExtension on UseCase {
  String get displayName {
    switch (this) {
      case UseCase.collegeVerification:
        return 'College Verification';
      case UseCase.hotelCheckIn:
        return 'Hotel Check-in';
    }
  }

  String get description {
    switch (this) {
      case UseCase.collegeVerification:
        return 'Verify student identity for college purposes';
      case UseCase.hotelCheckIn:
        return 'Verify guest identity for hotel check-in';
    }
  }

  IconData get icon {
    switch (this) {
      case UseCase.collegeVerification:
        return Icons.school;
      case UseCase.hotelCheckIn:
        return Icons.hotel;
    }
  }

  List<VerificationCategory> get availableCategories {
    switch (this) {
      case UseCase.collegeVerification:
        return [
          VerificationCategory.fullIdentity,
          VerificationCategory.ageVerification,
          VerificationCategory.branchVerification,
          VerificationCategory.yearVerification,
          VerificationCategory.aadharVerification,
        ];
      case UseCase.hotelCheckIn:
        return [
          VerificationCategory.fullIdentity,
          VerificationCategory.ageVerification,
        ];
    }
  }
}
