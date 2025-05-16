package io.flutter.embedding.engine;

import androidx.annotation.NonNull;

/**
 * Mock implementation of FlutterEngine for the build process.
 */
public class FlutterEngine {
    public PluginRegistry getPlugins() {
        return new PluginRegistry();
    }

    public static class PluginRegistry {
        public boolean add(Object plugin) {
            // No-op implementation
            return true;
        }
    }
}