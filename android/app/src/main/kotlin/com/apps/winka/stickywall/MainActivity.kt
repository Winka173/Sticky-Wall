package com.apps.winka.stickywall

import android.os.Build
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// A FragmentActivity because the app lock (local_auth) shows the system's
// fingerprint / face / screen-lock prompt as a fragment.
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // While the app lock is on or a private board is open, the recent-apps
        // screen shows a blank card instead of the notes. Android 13+ can hide
        // just that thumbnail; older versions only have FLAG_SECURE, which
        // also blocks screenshots while it is set.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sticky_wall/privacy")
            .setMethodCallHandler { call, result ->
                if (call.method == "hideInRecents") {
                    val hide = call.arguments as? Boolean ?: false
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        setRecentsScreenshotEnabled(!hide)
                    } else if (hide) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
