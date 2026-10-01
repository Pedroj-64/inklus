package com.inklus.inklus

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/// Recibe archivos `.inklus` (Drive, Archivos, compartir…): copia el contenido a la
/// caché y se lo da a Dart, que lo importa con ImportService.
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var pending: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pending = copyIncoming(intent)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "inklus/open").apply {
            setMethodCallHandler { call, result ->
                if (call.method == "take") {
                    result.success(pending)
                    pending = null
                } else result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val path = copyIncoming(intent) ?: return
        pending = null
        channel?.invokeMethod("file", path)
    }

    private fun copyIncoming(intent: Intent?): String? {
        val uri: Uri = when (intent?.action) {
            Intent.ACTION_VIEW -> intent.data
            Intent.ACTION_SEND -> @Suppress("DEPRECATION") intent.getParcelableExtra(Intent.EXTRA_STREAM)
            else -> null
        } ?: return null
        return try {
            val out = File(cacheDir, "incoming.inklus")
            contentResolver.openInputStream(uri)?.use { i -> out.outputStream().use { i.copyTo(it) } }
                ?: return null
            out.path
        } catch (e: Exception) {
            null
        }
    }
}
