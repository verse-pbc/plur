import 'dart:developer';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:nostrmo/main.dart';

import 'retry_http_file_service.dart';

class CacheManagerBuilder {
  static const key = 'cachedImageData';

  static void build() {
    // Skip cache manager on web platform
    if (kIsWeb) {
      log("Skipping image cache manager on web platform", name: "CacheManagerBuilder");
      // Set to null - the app will handle this case
      imageLocalCacheManager = null;
      return;
    }
    
    try {
      log("Initializing image cache manager", name: "CacheManagerBuilder");
      
      // Use a simpler initialization approach to reduce potential issues
      // Create a basic config without custom file service
      final config = Config(
        key, 
        stalePeriod: const Duration(days: 2),
        maxNrOfCacheObjects: 300,
      );
      
      // Create the cache manager
      imageLocalCacheManager = CacheManager(config);
      
      log("Image cache manager initialized successfully", name: "CacheManagerBuilder");
    } catch (e) {
      // In case of initialization failure, set to null and log error
      log("Error initializing image cache manager: $e", name: "CacheManagerBuilder");
      imageLocalCacheManager = null;
      
      // Try with completely default config as last resort
      try {
        log("Attempting default cache manager initialization", name: "CacheManagerBuilder");
        imageLocalCacheManager = DefaultCacheManager();
        log("Default cache manager initialized successfully", name: "CacheManagerBuilder");
      } catch (e2) {
        log("Could not create default cache manager: $e2", name: "CacheManagerBuilder");
        imageLocalCacheManager = null;
      }
    }
  }
  
  static void clearCache() {
    // Skip on web platform
    if (kIsWeb) {
      log("Skipping cache clear on web platform", name: "CacheManagerBuilder");
      return;
    }
    
    try {
      if (imageLocalCacheManager != null) {
        imageLocalCacheManager!.emptyCache();
        log("Image cache cleared", name: "CacheManagerBuilder");
      } else {
        log("Cache manager is null, nothing to clear", name: "CacheManagerBuilder");
      }
    } catch (e) {
      log("Failed to clear image cache: $e", name: "CacheManagerBuilder");
    }
  }
}
