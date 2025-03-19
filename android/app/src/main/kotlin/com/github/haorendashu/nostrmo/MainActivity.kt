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

    private val deepLinkChannel by lazy {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
    }

    private var pendingDeepLink: String? = null

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

        // Check if we have a pending deep link to process
        pendingDeepLink?.let {
            deepLinkChannel.invokeMethod("onDeepLink", it)
            pendingDeepLink = null
        }

        // Set up method channel for future deep links
        intent?.data?.let { data ->
            if (data.scheme.equals("plur", ignoreCase = true)) {
                deepLinkChannel.invokeMethod("onDeepLink", data.toString())
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        val data: Uri? = intent.data
        if (::flutterEngine.isInitialized) {
            deepLinkChannel.invokeMethod("onDeepLink", data.toString())
        } else {
            pendingDeepLink = data.toString()
        }
        if (data != null && data.scheme.equals("plur", ignoreCase = true)) {
            // Pass the data to Flutter
            deepLinkChannel.invokeMethod("onDeepLink", data.toString())
        }
    }
}
