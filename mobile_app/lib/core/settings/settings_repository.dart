import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  throw UnimplementedError();
});

class SettingsRepository {
  final SharedPreferences _prefs;
  static const _baseUrlKey = 'api_base_url';

  SettingsRepository(this._prefs);

  String get baseUrl {
    return _prefs.getString(_baseUrlKey) ?? 
           dotenv.env['API_BASE_URL'] ?? 
           'https://fitnesscare.pocketguard.store';
  }

  Future<void> setBaseUrl(String url) async {
    await _prefs.setString(_baseUrlKey, url);
  }
}
