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
      
      // Set up the config with error handling and retry
      final config = Config(
        key, 
        fileService: RetryHttpFileService(),
        stalePeriod: const Duration(days: 2),  // Consider files stale after 2 days
        maxNrOfCacheObjects: 300,  // Limit cache size to prevent excessive storage use
        repo: JsonCacheInfoRepository(databaseName: key + '_db'),
      );
      
      // Create the cache manager
      imageLocalCacheManager = CacheManager(config);
      
      log("Image cache manager initialized successfully", name: "CacheManagerBuilder");
    } catch (e) {
      // In case of initialization failure, create a basic cache manager as fallback
      log("Error initializing image cache manager: $e", name: "CacheManagerBuilder");
      log("Creating fallback image cache manager", name: "CacheManagerBuilder");
      
      try {
        final fallbackConfig = Config(key + '_fallback');
        imageLocalCacheManager = CacheManager(fallbackConfig);
      } catch (e2) {
        log("Could not create fallback cache manager: $e2", name: "CacheManagerBuilder");
        // At this point, the app will need to handle null imageLocalCacheManager
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
