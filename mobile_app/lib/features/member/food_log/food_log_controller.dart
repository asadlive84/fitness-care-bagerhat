import 'package:fitness_care_bagerhat/features/member/food_log/food_log.dart';
import 'package:fitness_care_bagerhat/features/member/food_log/food_log_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FoodLogController extends StateNotifier<AsyncValue<List<FoodLog>>> {
  FoodLogController({required FoodLogRepository repository})
      : _repository = repository,
        super(const AsyncValue.loading()) {
    load();
  }

  final FoodLogRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final logs = await _repository.list();
      state = AsyncValue.data(logs);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<NutritionData> logMeal(String localFilePath) async {
    // 1. Upload compressed image to server
    final imageUrl = await _repository.uploadImage(localFilePath);
    
    // 2. Perform AI vision analysis
    final nutrition = await _repository.analyzeImage(imageUrl);
    
    // 3. Reload list so user sees the new item in history
    await load();
    
    return nutrition;
  }
}

final foodLogControllerProvider = StateNotifierProvider.autoDispose<
    FoodLogController, AsyncValue<List<FoodLog>>>((ref) {
  return FoodLogController(repository: ref.watch(foodLogRepositoryProvider));
});
