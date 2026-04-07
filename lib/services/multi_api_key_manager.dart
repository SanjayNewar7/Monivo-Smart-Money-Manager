// services/multi_api_key_manager.dart
import 'dart:async';

class APIKeyManager {
  // Your 5 API keys
  static final List<String> _apiKeys = [
    'API KEY 1', // Key 1 - Original
    'API KEY 2', // Key 2 - Default Gemini
    'API KEY 3', // Key 3 - Default Gemini
    'API KEY 4', // Key 4 - Default Gemini
    'API KEY 5', // Key 5 - New Key
  ];

  static int _currentKeyIndex = 0;
  static final Map<int, int> _keyFailures = {};
  static final Map<int, DateTime> _keyCooldownUntil = {};
  static const int _cooldownMinutes = 5;
  static const int _maxRetriesPerKey = 2;

  // Get current active key
  static String getCurrentKey() {
    return _apiKeys[_currentKeyIndex];
  }

  // Get key by index
  static String getKeyByIndex(int index) {
    if (index >= 0 && index < _apiKeys.length) {
      return _apiKeys[index];
    }
    return _apiKeys[0];
  }

  // Get current key index
  static int getCurrentKeyIndex() => _currentKeyIndex;

  // Get key index using indexOf (PROPER way - no hardcoding)
  static int getKeyIndex(String apiKey) {
    return _apiKeys.indexOf(apiKey);
  }

  // Get next available key (circular rotation)
  static String getNextKey() {
    if (_apiKeys.length <= 1) return _apiKeys[0];

    final int startIndex = _currentKeyIndex;
    int attempts = 0;

    do {
      _currentKeyIndex = (_currentKeyIndex + 1) % _apiKeys.length;
      attempts++;

      // Skip keys that are on cooldown
      if (!_isKeyOnCooldown(_currentKeyIndex)) {
        print('🔄 Switched to API Key ${_currentKeyIndex + 1}: ${_getMaskedKey(_apiKeys[_currentKeyIndex])}');
        return _apiKeys[_currentKeyIndex];
      }

      if (attempts >= _apiKeys.length) {
        break;
      }
    } while (_currentKeyIndex != startIndex);

    // If all keys are on cooldown, return the one with earliest cooldown expiry
    int earliestIndex = -1;
    DateTime? earliestTime;

    for (int i = 0; i < _apiKeys.length; i++) {
      final cooldownUntil = _keyCooldownUntil[i];
      if (cooldownUntil != null) {
        if (earliestTime == null || cooldownUntil.isBefore(earliestTime)) {
          earliestTime = cooldownUntil;
          earliestIndex = i;
        }
      }
    }

    if (earliestIndex != -1) {
      print('⚠️ All keys on cooldown. Using key that expires soonest: Key ${earliestIndex + 1}');
      _currentKeyIndex = earliestIndex;
      return _apiKeys[earliestIndex];
    }

    return _apiKeys[0];
  }

  // Check if key is on cooldown (by index)
  static bool _isKeyOnCooldown(int keyIndex) {
    final cooldownUntil = _keyCooldownUntil[keyIndex];
    if (cooldownUntil == null) return false;

    if (DateTime.now().isAfter(cooldownUntil)) {
      // Cooldown has expired, remove it
      _keyCooldownUntil.remove(keyIndex);
      _keyFailures[keyIndex] = 0;
      return false;
    }
    return true;
  }

  // Mark key as failed (using key string - find index automatically)
  static void markKeyFailed(String apiKey, String errorMessage) {
    final int keyIndex = _apiKeys.indexOf(apiKey);
    if (keyIndex == -1) return;

    final int failCount = (_keyFailures[keyIndex] ?? 0) + 1;
    _keyFailures[keyIndex] = failCount;

    // Set cooldown for this key
    _keyCooldownUntil[keyIndex] = DateTime.now().add(Duration(minutes: _cooldownMinutes));

    print('⚠️ API Key ${keyIndex + 1} (${_getMaskedKey(apiKey)}) failed');
    print('   Reason: $errorMessage');
    print('   Failure count: $failCount');
    print('   On cooldown for $_cooldownMinutes minutes');

    // If current key failed and we have other keys, switch now
    if (_currentKeyIndex == keyIndex && _apiKeys.length > 1) {
      getNextKey();
    }
  }

  // Mark key as successful (using key string)
  static void markKeySuccessful(String apiKey) {
    final int keyIndex = _apiKeys.indexOf(apiKey);
    if (keyIndex == -1) return;

    if (_keyFailures[keyIndex] != null && _keyFailures[keyIndex]! > 0) {
      _keyFailures[keyIndex] = 0;
      print('✅ API Key ${keyIndex + 1} (${_getMaskedKey(apiKey)}) restored to good standing');
    }
    _keyCooldownUntil.remove(keyIndex);
  }

  // Get masked version of API key for logging
  static String _getMaskedKey(String apiKey) {
    if (apiKey.length <= 8) return '***';
    return '...${apiKey.substring(apiKey.length - 4)}';
  }

  // Check if any key is available
  static bool hasAvailableKey() {
    for (int i = 0; i < _apiKeys.length; i++) {
      if (!_isKeyOnCooldown(i)) return true;
    }
    return false;
  }

  // Reset all keys
  static void resetAllKeys() {
    _keyFailures.clear();
    _keyCooldownUntil.clear();
    _currentKeyIndex = 0;
    print('✅ All API keys have been reset');
    printKeyStatus();
  }

  // Get status of all keys
  static void printKeyStatus() {
    print('\n📊 API Keys Status:');
    for (int i = 0; i < _apiKeys.length; i++) {
      final isOnCooldown = _isKeyOnCooldown(i);
      final failCount = _keyFailures[i] ?? 0;
      final isCurrent = i == _currentKeyIndex;

      String status = isOnCooldown ? '⏳ COOLDOWN' : '✅ ACTIVE';
      if (isOnCooldown) {
        final remaining = _keyCooldownUntil[i]!.difference(DateTime.now());
        status = '⏳ Cooldown (${remaining.inMinutes}m ${remaining.inSeconds % 60}s)';
      }

      print('   ${isCurrent ? '👉' : '  '} Key ${i + 1}: ${_getMaskedKey(_apiKeys[i])} | $status | Failures: $failCount ${isCurrent ? "[CURRENT]" : ""}');
    }
    print('');
  }

  // Get total number of keys
  static int getKeyCount() => _apiKeys.length;

  // Get all keys (for debugging)
  static List<String> getAllKeys() => List.unmodifiable(_apiKeys);
}
