import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App language (en / ar), persisted on device.
class LocaleController extends Notifier<Locale> {
  static const _key = 'evc_locale';

  @override
  Locale build() {
    _load();
    return const Locale('en');
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_key);
      if (code != null && code != state.languageCode) {
        state = Locale(code);
      }
    } catch (_) {
      // No prefs available (e.g. tests) — keep the default.
    }
  }

  Future<void> set(Locale locale) async {
    state = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, locale.languageCode);
    } catch (_) {/* best-effort persistence */}
  }

  void toggle() =>
      set(state.languageCode == 'ar' ? const Locale('en') : const Locale('ar'));
}

final localeProvider =
    NotifierProvider<LocaleController, Locale>(LocaleController.new);