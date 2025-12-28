import 'package:bla_bla_car/api_service/app_constocter.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../service/translations.dart';

class TranslateProvider with ChangeNotifier {
  static const _boxName = 'settings';
  static const _localeKey = 'locale';

  String _locale = App_Constructor().istestmode?'en':'ru'; // default English

  String get locale => _locale;

  Future<void> init() async {
    final box = await Hive.openBox(_boxName);
    final savedLocale = box.get(_localeKey, defaultValue: App_Constructor().istestmode?'en':'ru');
    _locale = savedLocale;
    notifyListeners();
  }

  Future<void> setLocale(String langCode) async {
    _locale = langCode;
    final box = await Hive.openBox(_boxName);
    await box.put(_localeKey, langCode);
    notifyListeners();
  }

  String t(String key) {
    return translations[_locale]?[key] ?? key;
  }
}
