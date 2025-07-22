import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

/// Manages in-memory and persistent caching for queries.
///
/// This class uses Hive for persistent storage.
///
/// IMPORTANT: For custom types (e.g., `DoctorEntity`), you MUST register
/// a [TypeAdapter] for them with Hive before initializing the cache.
/// Example: `Hive.registerAdapter(DoctorEntityAdapter());`
class QueryCache {
  static QueryCache? _instance;

  /// Provides a singleton instance of [QueryCache].
  static QueryCache get instance => _instance ??= QueryCache._();

  QueryCache._();

  /// In-memory cache for quick access.
  final Map<String, dynamic> _memoryCache = {};

  /// Persistent Hive box for long-term storage.
  Box? _persistentCache;

  /// Indicates if the cache has been initialized.
  bool _initialized = false;

  /// Initializes the [QueryCache].
  ///
  /// This must be called before using any cache operations, typically
  /// at the start of your application.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Ensure Hive is initialized for Flutter
      await Hive.initFlutter();
      final appDocumentDir = await getApplicationDocumentsDirectory();
      Hive.init(appDocumentDir.path);

      _persistentCache = await Hive.openBox('flutter_data_query_cache');
      _initialized = true;
      debugPrint('QueryCache initialized successfully.');
    } catch (e) {
      debugPrint('Error initializing QueryCache: $e');
      // Handle initialization errors, perhaps by falling back to in-memory only.
    }
  }

  /// Stores data in both in-memory and persistent cache.
  ///
  /// [key] is the unique identifier for the cached data.
  /// [data] is the data to be cached.
  /// [ttl] (Time To Live) is an optional duration after which the data
  /// in the persistent cache will be considered expired.
  Future<void> set<T>(String key, T data, {Duration? ttl}) async {
    _memoryCache[key] = data; // Store in memory

    if (_initialized && _persistentCache != null) {
      try {
        // Hive handles custom objects directly if adapters are registered.
        await _persistentCache!.put(key, data);
        // TODO: Implement TTL for persistent cache if needed.
        // Hive doesn't have built-in TTL per entry. This would require
        // storing metadata (timestamp, ttl) alongside the data or
        // a separate mechanism to clean up expired entries.
        // For simplicity, current implementation relies on `Query` to check staleness.
      } catch (e) {
        debugPrint('Error saving to persistent cache for key $key: $e');
      }
    }
  }

  /// Retrieves data from cache, checking memory first, then persistent storage.
  ///
  /// [key] is the unique identifier for the data.
  /// Returns the cached data if found and not expired, otherwise `null`.
  Future<T?> get<T>(String key) async {
    // Check memory first
    final memoryData = _memoryCache[key];
    if (memoryData != null) {
      return memoryData as T?;
    }

    // Check persistent storage
    if (_initialized && _persistentCache != null) {
      try {
        final persistentData = _persistentCache!.get(key);
        if (persistentData != null) {
          // Update memory cache from persistent storage
          _memoryCache[key] = persistentData;
          return persistentData as T?;
        }
      } catch (e) {
        debugPrint('Error retrieving from persistent cache for key $key: $e');
        // If data is corrupted, remove it
        await remove(key);
      }
    }
    return null;
  }

  /// Removes data from both in-memory and persistent cache.
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    if (_initialized && _persistentCache != null) {
      try {
        await _persistentCache!.delete(key);
      } catch (e) {
        debugPrint('Error removing from persistent cache for key $key: $e');
      }
    }
  }

  /// Clears all data from both in-memory and persistent cache.
  Future<void> clear() async {
    _memoryCache.clear();
    if (_initialized && _persistentCache != null) {
      try {
        await _persistentCache!.clear();
      } catch (e) {
        debugPrint('Error clearing persistent cache: $e');
      }
    }
  }

  /// Checks if the cache contains data for a given key.
  bool has(String key) {
    return _memoryCache.containsKey(key) ||
        (_persistentCache?.containsKey(key) ?? false);
  }

  /// Disposes the persistent cache. Should be called on app shutdown.
  Future<void> dispose() async {
    if (_persistentCache != null) {
      try {
        await _persistentCache!.close();
        _persistentCache = null;
      } catch (e) {
        debugPrint('Error disposing QueryCache: $e');
      }
    }
    _initialized = false;
    _instance = null; // Reset singleton
  }
}