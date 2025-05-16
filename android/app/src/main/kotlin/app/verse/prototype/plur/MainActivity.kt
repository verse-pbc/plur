package app.verse.prototype.plur

import android.os.Bundle

/**
 * Main entry point for the application.
 * Uses custom FlutterActivity to avoid Flutter embedding issues.
 */
class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Reference NostrmoPlugin to ensure it's included in the build
        val plugin = NostrmoPlugin(this)
    }
}