import 'dart:convert';

class FoodLog {
  final int id;
  final String memberId;
  final String imageUrl;
  final String? deviceModel;
  final DateTime? captureTime;
  final DateTime logDate;
  final DateTime createdAt;
  final NutritionData nutrition;

  const FoodLog({
    required this.id,
    required this.memberId,
    required this.imageUrl,
    this.deviceModel,
    this.captureTime,
    required this.logDate,
    required this.createdAt,
    required this.nutrition,
  });

  factory FoodLog.fromJson(Map<String, dynamic> json) {
    // Parse the AI Response JSON
    NutritionData nutritionData = const NutritionData();
    final aiResponseRaw = json['ai_response_json'];
    if (aiResponseRaw != null) {
      try {
        Map<String, dynamic>? aiMap;
        if (aiResponseRaw is String) {
          aiMap = jsonDecode(aiResponseRaw) as Map<String, dynamic>?;
        } else if (aiResponseRaw is Map<String, dynamic>) {
          aiMap = aiResponseRaw;
        } else if (aiResponseRaw is Map && aiResponseRaw.containsKey('RawMessage')) {
          // If it comes via pqtype.NullRawMessage/sqlc envelope
          final raw = aiResponseRaw['RawMessage'];
          if (raw is String) {
            aiMap = jsonDecode(raw) as Map<String, dynamic>?;
          } else if (raw is List<int>) {
            aiMap = jsonDecode(utf8.decode(raw)) as Map<String, dynamic>?;
          }
        }

        if (aiMap != null) {
          nutritionData = NutritionData.fromJson(aiMap);
        }
      } catch (e) {
        // Fallback to empty nutrition in case of parse failure
      }
    }

    return FoodLog(
      id: json['id'] as int? ?? 0,
      memberId: json['member_id'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      deviceModel: json['device_model'] as String?,
      captureTime: json['capture_time'] != null
          ? DateTime.parse(json['capture_time'] as String)
          : null,
      logDate: json['log_date'] != null
          ? DateTime.parse(json['log_date'] as String)
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      nutrition: nutritionData,
    );
  }
}

class NutritionData {
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fats;
  final String analysis;

  const NutritionData({
    this.name = 'Unknown Food Item',
    this.calories = 0.0,
    this.protein = 0.0,
    this.carbs = 0.0,
    this.fats = 0.0,
    this.analysis = 'No analysis available',
  });

  factory NutritionData.fromJson(Map<String, dynamic> json) {
    // Look for various keys in case AI returns different names
    final nameKey = ['name', 'dish_name', 'food_name', 'food', 'item']
        .firstWhere((k) => json.containsKey(k), orElse: () => 'name');
    final calKey = ['calories', 'cal', 'energy', 'calories_kcal']
        .firstWhere((k) => json.containsKey(k), orElse: () => 'calories');
    final protKey = ['protein', 'proteins', 'prot', 'p']
        .firstWhere((k) => json.containsKey(k), orElse: () => 'protein');
    final carbKey = ['carbs', 'carbohydrates', 'carb', 'c']
        .firstWhere((k) => json.containsKey(k), orElse: () => 'carbs');
    final fatKey = ['fats', 'fat', 'f']
        .firstWhere((k) => json.containsKey(k), orElse: () => 'fats');
    final anaKey = ['analysis', 'description', 'feedback', 'details']
        .firstWhere((k) => json.containsKey(k), orElse: () => 'analysis');

    return NutritionData(
      name: json[nameKey]?.toString() ?? 'Food Item',
      calories: _parseDouble(json[calKey]),
      protein: _parseDouble(json[protKey]),
      carbs: _parseDouble(json[carbKey]),
      fats: _parseDouble(json[fatKey]),
      analysis: json[anaKey]?.toString() ?? 'AI analysis completed.',
    );
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) {
      // Clean string like "350 kcal" or "25g"
      final clean = val.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(clean) ?? 0.0;
    }
    return 0.0;
  }
}
