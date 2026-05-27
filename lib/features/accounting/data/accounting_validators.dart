class AccountingValidationResult {
  const AccountingValidationResult({required this.ok, this.message});

  final bool ok;
  final String? message;

  static const success = AccountingValidationResult(ok: true);

  static AccountingValidationResult fail(String message) {
    return AccountingValidationResult(ok: false, message: message);
  }
}

class AccountingMoneyParser {
  const AccountingMoneyParser._();

  static int parseKurus(String input) {
    final normalized = input.trim().replaceAll('.', '').replaceAll(',', '.');
    final value = double.tryParse(normalized);
    if (value == null) return 0;
    return (value * 100).round();
  }

  static String formatTl(int kurus) {
    final value = (kurus / 100).toStringAsFixed(2).replaceAll('.', ',');
    return '$value TL';
  }

  static int remaining({
    required int totalKurus,
    required int paidKurus,
    required bool closeAtCollectedAmount,
    required bool hasDueDate,
  }) {
    if (closeAtCollectedAmount && !hasDueDate) return 0;

    final value = totalKurus - paidKurus;
    return value > 0 ? value : 0;
  }
}

class AccountingPhoneNormalizer {
  const AccountingPhoneNormalizer._();

  static String normalizeTr(String input) {
    var digits = input.replaceAll(RegExp('[^0-9]'), '');

    if (digits.startsWith('0090')) {
      digits = digits.substring(4);
    } else if (digits.startsWith('90') && digits.length == 12) {
      digits = digits.substring(2);
    } else if (digits.startsWith('0') && digits.length == 11) {
      digits = digits.substring(1);
    }

    if (digits.length == 10 && digits.startsWith('5')) {
      return '+90$digits';
    }

    return input.trim();
  }

  static bool looksLikeTrMobile(String input) {
    final normalized = normalizeTr(input);
    return RegExp(r'^\+905[0-9]{9}$').hasMatch(normalized);
  }
}

class AccountingDraftValidator {
  const AccountingDraftValidator._();

  static AccountingValidationResult validateManualSale({
    required String saleType,
    required String customerType,
    required String customerName,
    required String customerPhone,
    required String itemName,
    required int totalKurus,
    required int paidKurus,
    required bool hasDueDate,
    required bool isInstallment,
    required bool closeAtCollectedAmount,
  }) {
    if (saleType.trim().isEmpty) {
      return AccountingValidationResult.fail('Satış tipi seçilmelidir.');
    }

    if (customerType == 'registered' &&
        !AccountingPhoneNormalizer.looksLikeTrMobile(customerPhone)) {
      return AccountingValidationResult.fail(
        'Kayıtlı bireysel kullanıcı eşleştirmesi için geçerli telefon gerekir.',
      );
    }

    if (customerType != 'registered' &&
        customerName.trim().isEmpty &&
        customerPhone.trim().isEmpty) {
      return AccountingValidationResult.fail(
        'Misafir işlemde müşteri adı veya telefon bilgisinden en az biri girilmelidir.',
      );
    }

    if (itemName.trim().isEmpty) {
      return AccountingValidationResult.fail('Satış kalemi boş bırakılamaz.');
    }

    if (totalKurus <= 0) {
      return AccountingValidationResult.fail(
        'Satış tutarı sıfırdan büyük olmalıdır.',
      );
    }

    if (paidKurus < 0) {
      return AccountingValidationResult.fail('Ödenen tutar negatif olamaz.');
    }

    if (paidKurus > totalKurus && !closeAtCollectedAmount) {
      return AccountingValidationResult.fail(
        'Ödenen tutar satış tutarından büyük olamaz.',
      );
    }

    if (isInstallment && !hasDueDate) {
      return AccountingValidationResult.fail(
        'Taksitli satışta ilk vade tarihi seçilmelidir.',
      );
    }

    return AccountingValidationResult.success;
  }

  static AccountingValidationResult validateExpense({
    required String category,
    required String title,
    required int amountKurus,
    required bool recurring,
    required String recurrencePeriod,
  }) {
    if (category.trim().isEmpty) {
      return AccountingValidationResult.fail('Gider kategorisi seçilmelidir.');
    }

    if (title.trim().isEmpty) {
      return AccountingValidationResult.fail('Gider başlığı girilmelidir.');
    }

    if (amountKurus <= 0) {
      return AccountingValidationResult.fail(
        'Gider tutarı sıfırdan büyük olmalıdır.',
      );
    }

    if (recurring && recurrencePeriod.trim().isEmpty) {
      return AccountingValidationResult.fail(
        'Tekrarlayan gider periyodu seçilmelidir.',
      );
    }

    return AccountingValidationResult.success;
  }
}
