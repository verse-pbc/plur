package io.flutter.plugins;

import androidx.annotation.Keep;
import androidx.annotation.NonNull;
import android.util.Log;

/**
 * Custom plugin registrant that replaces the generated one.
 * This allows the app to compile without requiring the specific Flutter engine classes.
 */
@Keep
public final class CustomPluginRegistrant {
  private static final String TAG = "CustomPluginRegistrant";
  
  public static void registerWith(@NonNull Object flutterEngine) {
    // No-op implementation as we're using Flutter's built-in plugin registration mechanism
    Log.d(TAG, "Using Flutter's built-in plugin registration");
  }
}