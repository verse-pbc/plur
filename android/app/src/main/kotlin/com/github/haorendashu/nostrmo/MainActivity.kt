package app.verse.prototype.plur

import app.verse.prototype.plur.NostrmoPlugin

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.annotation.NonNull

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.Log
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {

    var TAG = "MainActivity"
    private val CHANNEL = "com.example.app/deeplink"

    var nostrmoPlugin: NostrmoPlugin? = null

    private lateinit var flutterEngine: FlutterEngine

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        nostrmoPlugin = NostrmoPlugin(this)
    }

    override public fun configureFlutterEngine(@NonNull flutterEngine : FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        this.flutterEngine = flutterEngine

        try {
            if (nostrmoPlugin != null) {
                flutterEngine.getPlugins().add(nostrmoPlugin!!)
            }
        } catch (e : Exception) {
            Log.e(TAG, "Error registering plugin NostrmoPlugin, app.verse.prototype.plur.NostrmoPlugin", e)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        val data: Uri? = intent.data
        if (data != null && data.scheme.equals("plur", ignoreCase = true)) {
            // Pass the data to Flutter
            val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            channel.invokeMethod("onDeepLink", data.toString())
        }
    }
}
