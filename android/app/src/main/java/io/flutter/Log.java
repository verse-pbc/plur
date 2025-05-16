package io.flutter;

/**
 * Mock implementation of Log for the build process.
 */
public class Log {
    public static void e(String tag, String message) {
        // Just delegate to Android's Log
        android.util.Log.e(tag, message);
    }
    
    public static void e(String tag, String message, Throwable e) {
        // Just delegate to Android's Log
        android.util.Log.e(tag, message, e);
    }
}