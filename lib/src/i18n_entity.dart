import 'package:intl_converter/intl_converter.dart';

class I18nEntity {
  Locale locale;
  String xmlFilePath;
  final bool isDevLanguage;

  I18nEntity(this.locale, this.xmlFilePath, this.isDevLanguage);

  String makeArbFileName(String prefix) {
    return locale.joinToFileName(prefix, '_') + '.arb';
  }
}
