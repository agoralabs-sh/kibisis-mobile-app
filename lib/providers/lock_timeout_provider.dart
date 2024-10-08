import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kibisis/providers/storage_provider.dart';

final lockTimeoutProvider =
    StateNotifierProvider<LockTimeoutNotifier, int>((ref) {
  final storageService = ref.watch(storageProvider);
  return LockTimeoutNotifier(storageService);
});

class LockTimeoutNotifier extends StateNotifier<int> {
  final StorageService _storageService;
  static const defaultTimeout = 60;

  LockTimeoutNotifier(this._storageService) : super(defaultTimeout) {
    _loadTimeout();
  }

  void _loadTimeout() async {
    final timeoutSeconds = _storageService.getLockTimeout() ?? defaultTimeout;
    state = timeoutSeconds;
  }

  void setTimeout(int seconds) {
    state = seconds;
    _storageService.setLockTimeout(seconds);
  }
}
