package app.verse.prototype.plur

import app.verse.prototype.plur.NostrmoPlugin

import androidx.annotation.NonNull
import android.os.Bundle

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.Log

class MainActivity: FlutterFragmentActivity() {

    var TAG = "MainActivity"

    var nostrmoPlugin: NostrmoPlugin? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        nostrmoPlugin = NostrmoPlugin(this)
    }

    override public fun configureFlutterEngine(@NonNull flutterEngine : FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        try {
            if (nostrmoPlugin != null) {
                flutterEngine.getPlugins().add(nostrmoPlugin!!)
            }
        } catch (e : Exception) {
            Log.e(TAG, "Error registering plugin NostrmoPlugin, app.verse.prototype.plur.NostrmoPlugin", e)
        }
    }

}
