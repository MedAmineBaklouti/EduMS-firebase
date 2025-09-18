package com.devnet.edums

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

class MainActivity : FlutterActivity() {
    private val channelName = "edu_ms/pdf_picker"
    private val requestCodePickPdf = 1001
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickPdf" -> launchPdfPicker(result)
                    else -> result.notImplemented()
                }
            }
    }

    @Suppress("DEPRECATION")
    private fun launchPdfPicker(result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("already_active", "A file picker request is already running.", null)
            return
        }

        var intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "application/pdf"
        }

        if (intent.resolveActivity(packageManager) == null) {
            intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "application/pdf"
            }
        }

        pendingResult = result
        try {
            startActivityForResult(Intent.createChooser(intent, "Select PDF"), requestCodePickPdf)
        } catch (exception: ActivityNotFoundException) {
            pendingResult = null
            result.error("unavailable", "No application is available to pick PDF files.", null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != requestCodePickPdf) {
            return
        }

        val result = pendingResult
        pendingResult = null
        if (result == null) {
            return
        }

        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            result.success(null)
            return
        }

        val uri = data.data!!
        val fileName = resolveFileName(uri) ?: "selected.pdf"

        try {
            val cachedFile = cachePdf(uri)
            result.success(
                mapOf(
                    "path" to cachedFile.absolutePath,
                    "name" to fileName,
                ),
            )
        } catch (error: Exception) {
            result.error("io_error", error.localizedMessage, null)
        }
    }

    @Throws(IOException::class)
    private fun cachePdf(uri: Uri): File {
        val cacheDir = applicationContext.cacheDir
        val fileName = "picked_pdf_${System.currentTimeMillis()}.pdf"
        val outputFile = File(cacheDir, fileName)
        val resolver = applicationContext.contentResolver

        resolver.openInputStream(uri)?.use { input ->
            FileOutputStream(outputFile).use { output ->
                input.copyTo(output)
            }
        } ?: throw IOException("Unable to open the selected PDF file.")

        return outputFile
    }

    private fun resolveFileName(uri: Uri): String? {
        val resolver = applicationContext.contentResolver
        resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (index >= 0) {
                    return cursor.getString(index)
                }
            }
        }
        return null
    }
}
