import '../../../../core/services/storage_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../datasources/theme_remote_data_source.dart';

class ThemeRepository {
  final ThemeRemoteDataSource remoteDataSource;
  final StorageService storageService;
  final ConnectivityService connectivityService;

  ThemeRepository({
    required this.remoteDataSource,
    required this.storageService,
    required this.connectivityService,
  });

  Future<String> getThemeMode() async {
    // Prefer remote when online, but fall back to local storage
    if (await connectivityService.hasConnection) {
      try {
        final remote = await remoteDataSource.fetchTheme();
        await storageService.saveThemeMode(remote);
        return remote;
      } catch (_) {
        final local = await storageService.getThemeMode();
        return local ?? 'light';
      }
    }

    final local = await storageService.getThemeMode();
    return local ?? 'light';
  }

  Future<void> saveThemeMode(String mode) async {
    await storageService.saveThemeMode(mode);
    if (await connectivityService.hasConnection) {
      await remoteDataSource.saveTheme(mode);
    }
  }
}
