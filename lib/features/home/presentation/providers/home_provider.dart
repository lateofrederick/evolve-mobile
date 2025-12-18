import 'package:evolve/features/visit/data/repository/visit_repository.dart';
import 'package:evolve/features/visit/domain/visit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../visit/presentation/visit_notifier.dart';

final homeScheduleProvider = StateNotifierProvider<HomeScheduleNotifier, AsyncValue<List<Visit>>>((ref) {
  final repo = ref.watch(visitRepositoryProvider);
  return HomeScheduleNotifier(repo);
});

class HomeScheduleNotifier extends StateNotifier<AsyncValue<List<Visit>>> {
  final VisitRepositoryImpl _repository;

  HomeScheduleNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSchedule();
  }

  Future<void> loadSchedule() async {
    try {
      final visits = await _repository.getDailySchedule();
      state = AsyncValue.data(visits);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}