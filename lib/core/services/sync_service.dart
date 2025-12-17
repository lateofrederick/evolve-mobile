import 'dart:convert';
import '../storage/local_storage.dart';
import '../network/api_client.dart';
import '../storage/network_info.dart';

class SyncService {
  final LocalStorageService _storage;
  final ApiClient _apiClient;
  final NetworkInfo _networkInfo;

  SyncService(this._storage, this._apiClient, this._networkInfo);

  Future<void> syncPendingActions() async {
    if (!await _networkInfo.isConnected) return;

    final queue = await _storage.getQueue();
    if (queue.isEmpty) return;

    for (final item in queue) {
      try {
        final payload = jsonDecode(item.payloadJson);

        if (item.actionType == 'check_in') {
          await _apiClient.post(
            '/visits/${item.visitId}/check-in',
            body: payload,
          );
        }
        // Add other cases for check_out, emar, etc.

        // If successful, remove from queue
        await _storage.clearQueueItem(item.id);
      } catch (e) {
        print("Sync failed for item ${item.id}: $e");
        // Keep in queue to retry later
      }
    }
  }
}