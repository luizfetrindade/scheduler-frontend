import 'package:flutter/services.dart';

/// Aplica máscara brasileira de telefone:
/// - 10 dígitos → (XX) XXXX-XXXX (fixo)
/// - 11 dígitos → (XX) XXXXX-XXXX (celular)
class PhoneInputFormatter extends TextInputFormatter {
  static String format(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    final capped = digits.length > 11 ? digits.substring(0, 11) : digits;
    final isMobile = capped.length > 10;
    final buf = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      if (i == 0) buf.write('(');
      if (i == 2) buf.write(') ');
      if (isMobile && i == 7) buf.write('-');
      if (!isMobile && i == 6) buf.write('-');
      buf.write(capped[i]);
    }
    return buf.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = format(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
