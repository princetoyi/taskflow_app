import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity;

  ConnectivityService() : _connectivity = Connectivity();

  Future<bool> get hasConnection async {
    final status = await _connectivity.checkConnectivity();
    return status != ConnectivityResult.none;
  }
}
