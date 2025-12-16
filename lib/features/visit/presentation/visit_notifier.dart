import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../data/repository/visit_repository.dart';
import '../domain/visit.dart';

// 1. Dependency Injection for Repository
final visitRepositoryProvider = Provider<VisitRepositoryImpl>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(localStorageProvider);
  final networkInfo = ref.watch(networkInfoProvider);

  return VisitRepositoryImpl(apiClient, storage, networkInfo);
});

// 2. The Logic Controller (Notifier)
// 'family' allows us to pass the unique 'visitId' when creating this provider
final visitProvider = StateNotifierProvider.family<VisitNotifier, AsyncValue<Visit>, String>((ref, visitId) {
  final repository = ref.watch(visitRepositoryProvider);
  return VisitNotifier(repository, visitId);
});

class VisitNotifier extends StateNotifier<AsyncValue<Visit>> {
  final VisitRepositoryImpl _repository;
  final String _visitId;

  VisitNotifier(this._repository, this._visitId) : super(const AsyncValue.loading()) {
    _fetchVisitDetails();
  }

  // Initial load
  Future<void> _fetchVisitDetails() async {
    try {
      // In a real scenario, you would call: await _repository.getVisitById(_visitId);
      // For now, we simulate a network delay or assume data is fetched from the schedule list
      await Future.delayed(const Duration(milliseconds: 300));

      // Ideally, the repository would provide a getVisitById method that checks cache/API
      state = AsyncValue.data(Visit(
        id: _visitId,
        clientName: "Mr. Arthur Jones", // This would come from API/Cache
        status: VisitStatus.scheduled,
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Action: Scan QR Code
  Future<void> scanIn(String qrPayload, double lat, double long) async {
    // 1. Set UI to loading
    state = const AsyncValue.loading();

    try {
      // 2. Call Repository (which handles Offline Logic internally)
      await _repository.checkIn(_visitId, qrPayload, lat, long);

      // 3. Update State to 'In Progress' on success (Optimistic UI handled by Repo status update logic potentially, but here we update local state)
      if (state.hasValue) {
         state = AsyncValue.data(state.value!.copyWith(
          status: VisitStatus.inProgress,
          checkInTime: DateTime.now(),
        ));
      } else {
        // Fallback reconstruction
         state = AsyncValue.data(Visit(
          id: _visitId,
          clientName: "Mr. Arthur Jones",
          status: VisitStatus.inProgress,
          checkInTime: DateTime.now(),
        ));
      }
    } catch (e, stack) {
      // 4. Handle Error
      state = AsyncValue.error(e, stack);
    }
  }

  // Action: Scan Out / Complete
  Future<void> scanOut() async {
    // Optimistic Update
    final previousState = state;

    try {
      await _repository.checkOut(_visitId);

      if (state.hasValue) {
        state = AsyncValue.data(state.value!.copyWith(
          status: VisitStatus.completed,
          checkOutTime: DateTime.now(),
        ));
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      // Optional: Revert to previous state if needed
    }
  }

  Future<void> toggleTask(String taskId, bool? value) async {
    if (value == null) return;

    // 1. Optimistic UI Update (Instant Feedback)
    final oldState = state.value!;
    final currentTasks = List<String>.from(oldState.completedTasks); // Ensure we have this field in Visit entity

    if (value) {
      currentTasks.add(taskId);
    } else {
      currentTasks.remove(taskId);
    }

    state = AsyncValue.data(oldState.copyWith(completedTasks: currentTasks));

    try {
      // 2. Call Repo
      await _repository.updateTask(_visitId, taskId, value);
    } catch (e) {
      // Revert on error
      state = AsyncValue.error(e, StackTrace.current);
      // Or silent fail + snackbar
    }
  }

  Future<void> saveNote(String text, String severity) async {
    // We don't necessarily need to set state to loading here,
    // maybe just return a Future so UI can show a success snackbar.
    try {
      await _repository.sendNote(_visitId, text, severity);
      // If successful, we don't update local state unless we display notes list.
      // We assume "Fire and Forget" for logs.
    } catch (e, stack) {
      // Pass error back to UI logic if needed
      state = AsyncValue.error(e, stack);
    }
  }
}