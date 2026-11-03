import 'package:flutter_test/flutter_test.dart';
import 'package:collection_agent/core/constants/app_strings.dart';
import 'package:collection_agent/core/utils/validators.dart';

void main() {
  group('Validators.validatePhone Tests', () {
    test('Empty and null values return phoneRequiredError', () {
      expect(Validators.validatePhone(null), AppStrings.phoneRequiredError);
      expect(Validators.validatePhone(''), AppStrings.phoneRequiredError);
      expect(Validators.validatePhone('   '), AppStrings.phoneRequiredError);
    });

    test('Less than 10 digits return phoneInvalidError', () {
      expect(Validators.validatePhone('98765'), AppStrings.phoneInvalidError);
      expect(Validators.validatePhone('987654321'), AppStrings.phoneInvalidError);
    });

    test('More than 10 digits return phoneInvalidError (The reported bug)', () {
      expect(Validators.validatePhone('98765432101'), AppStrings.phoneInvalidError);
      expect(Validators.validatePhone('919876543210'), AppStrings.phoneInvalidError);
      expect(Validators.validatePhone('987654321012345'), AppStrings.phoneInvalidError);
    });

    test('10 digits starting with invalid carrier digits (< 6) return phoneInvalidError', () {
      expect(Validators.validatePhone('1234567890'), AppStrings.phoneInvalidError);
      expect(Validators.validatePhone('0987654321'), AppStrings.phoneInvalidError);
      expect(Validators.validatePhone('5555555555'), AppStrings.phoneInvalidError);
    });

    test('Valid 10-digit mobile numbers return null', () {
      expect(Validators.validatePhone('9876543210'), isNull);
      expect(Validators.validatePhone('8876543210'), isNull);
      expect(Validators.validatePhone('7876543210'), isNull);
      expect(Validators.validatePhone('6876543210'), isNull);
    });
  });

  group('Validators.validateAmount Tests', () {
    test('Empty and null values return paymentInvalidAmount', () {
      expect(Validators.validateAmount(null, 6000.0), AppStrings.paymentInvalidAmount);
      expect(Validators.validateAmount('', 6000.0), AppStrings.paymentInvalidAmount);
      expect(Validators.validateAmount('   ', 6000.0), AppStrings.paymentInvalidAmount);
    });

    test('Zero and negative values return paymentInvalidAmount', () {
      expect(Validators.validateAmount('0', 6000.0), AppStrings.paymentInvalidAmount);
      expect(Validators.validateAmount('-100', 6000.0), AppStrings.paymentInvalidAmount);
    });

    test('Exact full payment returns null (No false positive)', () {
      expect(Validators.validateAmount('6000', 6000.0), isNull);
      expect(Validators.validateAmount('4000', 4000.0), isNull);
    });

    test('Amount within 0.01 currency epsilon returns null', () {
      expect(Validators.validateAmount('6000', 5999.995), isNull);
    });

    test('Valid partial payment strictly less than due returns null', () {
      expect(Validators.validateAmount('2000', 6000.0), isNull);
      expect(Validators.validateAmount('3500.50', 4000.0), isNull);
    });

    test('Amount exceeding due amount returns paymentExceedsDue', () {
      expect(Validators.validateAmount('6001', 6000.0), AppStrings.paymentExceedsDue);
      expect(Validators.validateAmount('6000', 4000.0), AppStrings.paymentExceedsDue);
      expect(Validators.validateAmount('4001', 4000.0), AppStrings.paymentExceedsDue);
    });
  });
}
