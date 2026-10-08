package com.ndri.dairyrisk

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val saveRequestCode = 4817
    private var pendingResult: MethodChannel.Result? = null
    private var pendingBytes: ByteArray? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.ndri.dairyrisk/documents")
            .setMethodCallHandler { call, result ->
                if (call.method != "savePdf") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (pendingResult != null) {
                    result.error("busy", "A document save is already in progress", null)
                    return@setMethodCallHandler
                }
                val name = call.argument<String>("name")
                val bytes = call.argument<ByteArray>("bytes")
                if (name.isNullOrBlank() || bytes == null) {
                    result.error("invalid_args", "PDF name and bytes are required", null)
                    return@setMethodCallHandler
                }
                pendingResult = result
                pendingBytes = bytes
                try {
                    val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "application/pdf"
                        putExtra(Intent.EXTRA_TITLE, name)
                        addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                    }
                    startActivityForResult(intent, saveRequestCode)
                } catch (error: Exception) {
                    pendingResult = null
                    pendingBytes = null
                    result.error("save_failed", error.message, null)
                }
            }
    }

    @Deprecated("Handled for Android's document picker")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != saveRequestCode) return
        val result = pendingResult
        val bytes = pendingBytes
        pendingResult = null
        pendingBytes = null
        if (result == null) return
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            result.success(false)
            return
        }
        try {
            val uri = data.data!!
            contentResolver.openOutputStream(uri, "w")?.use { it.write(bytes ?: ByteArray(0)) }
                ?: throw IllegalStateException("Unable to write selected document")
            result.success(true)
        } catch (error: Exception) {
            result.error("save_failed", error.message, null)
        }
    }
}
