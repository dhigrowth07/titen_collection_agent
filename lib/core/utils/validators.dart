import 'package:collection_agent/core/constants/app_strings.dart';

/// Centralized Validators
class Validators {
  Validators._();

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.phoneRequiredError;
    }
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned)) {
      return AppStrings.phoneInvalidError;
    }
    return null;
  }

  static String? validateAmount(String? value, double amountDue) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.paymentInvalidAmount;
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return AppStrings.paymentInvalidAmount;
    }
    // Currency precision: normalize both parsed and due to 2 decimal places (paise)
    final normalizedParsed = double.parse(parsed.toStringAsFixed(2));
    final normalizedDue = double.parse(amountDue.toStringAsFixed(2));
    // Also allow integer ceiling / rounding if amount has fractional paisa
    final roundedDue = amountDue.roundToDouble();

    if (normalizedParsed > (normalizedDue + 0.01) &&
        normalizedParsed > (roundedDue + 0.01)) {
      return AppStrings.paymentExceedsDue;
    }
    return null;
  }

  static String? validatePasscode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.passcodeRequiredError;
    }
    if (value.trim().length != 4) {
      return AppStrings.passcodeInvalidError;
    }
    return null;
  }
}
