import '../../../../core/storage/network_info.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/local_storage.dart';
import '../../domain/visit.dart';

class VisitRepositoryImpl {
  final ApiClient _apiClient;
  final LocalStorageService _storage;
  final NetworkInfo _networkInfo;

  VisitRepositoryImpl(this._apiClient, this._storage, this._networkInfo);

  // 1. Get Schedule (API -> Cache, or Cache -> UI)
  Future<List<Visit>> getDailySchedule() async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await _apiClient.get('/mobile/my-schedule');

        // Convert API response to Domain Entities
        final visits = (response as List).map((json) {
          return Visit(
            id: json['id'].toString(),
            clientName: "${json['client']['first_name']} ${json['client']['last_name']}",
            status: _mapStatus(json['status']),
          );
        }).toList();

        // Convert to Local DTOs and Cache
        final localVisits = visits.map((v) => LocalVisit()
          ..visitId = v.id
          ..clientName = v.clientName
          ..status = v.status.name // Store enum as string
          ..scheduledStart = DateTime.now() // Mock for demo, ideally fetch from JSON
        ).toList();

        await _storage.cacheVisits(localVisits);

        return visits;
      } catch (e) {
        // API failed (server error), fallback to cache
        return _fetchLocalVisits();
      }
    } else {
      // Offline: Fetch from Isar
      return _fetchLocalVisits();
    }
  }

  Future<List<Visit>> _fetchLocalVisits() async {
    final cached = await _storage.getCachedVisits();
    return cached.map((c) => Visit(
      id: c.visitId,
      clientName: c.clientName,
      status: _mapStatusFromString(c.status),
    )).toList();
  }

  // 2. Check In (Offline Queue)
  Future<void> checkIn(String visitId, String qrPayload, double lat, double long) async {
    if (await _networkInfo.isConnected) {
      await _apiClient.post(
        '/visits/$visitId/check-in',
        body: {
          'qr_payload': qrPayload,
          'latitude': lat,
          'longitude': long,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      // Update local status to reflect API success
      await _storage.updateVisitStatus(visitId, 'inProgress');
    } else {
      // Offline: Add to Sync Queue
      await _storage.addToQueue('check_in', visitId, {
        'qr_payload': qrPayload,
        'latitude': lat,
        'longitude': long,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Optimistic Update: Mark as inProgress locally so UI updates immediately
      await _storage.updateVisitStatus(visitId, 'inProgress');
    }
  }

  // 3. Scan Out / Complete
  Future<void> checkOut(String visitId) async {
    if (await _networkInfo.isConnected) {
      await _apiClient.post('/visits/$visitId/check-out');
      await _storage.updateVisitStatus(visitId, 'completed');
    } else {
      await _storage.addToQueue('check_out', visitId, {
        'timestamp': DateTime.now().toIso8601String(),
      });
      await _storage.updateVisitStatus(visitId, 'completed');
    }
  }

  Future<void> updateTask(String visitId, String taskId, bool isCompleted) async {
    if (await _networkInfo.isConnected) {
      await _apiClient.post( // or PATCH if your client supports it
        '/visits/$visitId/tasks', // Note: Using POST usually easier in some clients, adjust if using PATCH
        body: {
          'task_id': taskId,
          'is_completed': isCompleted,
        },
      );
      // Update local storage
      await _storage.updateVisitTask(visitId, taskId, isCompleted);
    } else {
      // Offline Queue
      await _storage.addToQueue('update_task', visitId, {
        'task_id': taskId,
        'is_completed': isCompleted,
      });
      // Optimistic Local Update
      await _storage.updateVisitTask(visitId, taskId, isCompleted);
    }
  }

  Future<void> sendNote(String visitId, String text, String severity) async {
    final payload = {
      'note_text': text,
      'severity': severity, // 'routine', 'concern', 'incident'
    };

    if (await _networkInfo.isConnected) {
      await _apiClient.post(
        '/visits/$visitId/notes',
        body: payload,
      );
      // Optional: Update local storage copy of notes if you track them locally
    } else {
      // Offline Queue
      await _storage.addToQueue('send_note', visitId, payload);
    }
  }
  
  VisitStatus _mapStatus(String status) {
    switch (status) {
      case 'in_progress': return VisitStatus.inProgress;
      case 'completed': return VisitStatus.completed;
      default: return VisitStatus.scheduled;
    }
  }

  VisitStatus _mapStatusFromString(String status) {
    // Matches the enum names stored in Isar
    if (status == 'inProgress') return VisitStatus.inProgress;
    if (status == 'completed') return VisitStatus.completed;
    return VisitStatus.scheduled;
  }
}