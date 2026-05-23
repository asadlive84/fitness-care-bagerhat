import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  throw UnimplementedError();
});

class SettingsRepository {
  final SharedPreferences _prefs;
  static const _baseUrlKey = 'api_base_url_v2';
  static const _defaultUrl = 'https://fitnesscare.pocketguard.store';

  SettingsRepository(this._prefs) {
    _resetIfInsecure();
  }

  // Clear any stored http:// URL — always use https in production.
  void _resetIfInsecure() {
    final stored = _prefs.getString(_baseUrlKey);
    if (stored != null && !stored.startsWith('https://')) {
      _prefs.remove(_baseUrlKey);
    }
  }

  String get baseUrl {
    return _prefs.getString(_baseUrlKey) ??
        dotenv.env['API_BASE_URL'] ??
        _defaultUrl;
  }

  Future<void> setBaseUrl(String url) async {
    await _prefs.setString(_baseUrlKey, url);
  }
}
