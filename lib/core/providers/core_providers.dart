import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../storage/local_storage.dart';
import '../storage/network_info.dart';

// Singleton: API Client
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// Singleton: Network Info
final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfo();
});

// Singleton: Local Storage
// Note: LocalStorageService init is async, but we treat the instance as a singleton.
// You might want to ensure initialization in main.dart or handle async here.
final localStorageProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});