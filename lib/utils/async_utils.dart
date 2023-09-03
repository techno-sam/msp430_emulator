class NestableLock {
  int _lock = 0;

  void lock() {
    _lock++;
  }

  void unlock() {
    if (_lock > 0) {
      _lock--;
    }
  }

  bool get isLocked => _lock > 0;
  bool get isUnlocked => _lock == 0;
}