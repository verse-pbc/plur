import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:nostrmo/main.dart';

import 'retry_http_file_service.dart';

class CacheManagerBuilder {
  static const key = 'cachedImageData';

  static void build() {
    final config = Config(key, fileService: RetryHttpFileService());
    imageLocalCacheManager = CacheManager(config);
  }
}
