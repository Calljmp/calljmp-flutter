package com.calljmp

import android.content.Context
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.IntegrityTokenRequest
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.security.MessageDigest

class CalljmpDevice private constructor(
    private val context: Context, private val channel: MethodChannel
) : MethodCallHandler {
    private val integrityManager = IntegrityManagerFactory.create(context)

    companion object {
        fun bind(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding): CalljmpDevice {
            val device = CalljmpDevice(
                flutterPluginBinding.applicationContext, MethodChannel(
                    flutterPluginBinding.binaryMessenger, "calljmp_device"
                )
            )
            device.bind()
            return device
        }
    }

    fun bind() {
        channel.setMethodCallHandler(this)
    }

    fun unbind() {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "requestIntegrityToken" -> requestIntegrityToken(call, result)
            else -> result.notImplemented()
        }
    }

    private fun requestIntegrityToken(call: MethodCall, result: Result) {
        try {
            val cloudProjectNumber = call.argument<Int>("cloudProjectNumber")
            val data =
                call.argument<String>("data") ?: throw IllegalArgumentException("Data is required")

            val dataBytes = data.toByteArray(Charsets.UTF_8)
            val digest = MessageDigest.getInstance("SHA-256")
            val hashedData = digest.digest(dataBytes)
            val nonce = hashedData.joinToString("") { "%02x".format(it) }

            val task = integrityManager.requestIntegrityToken(
                IntegrityTokenRequest.builder()
                    .setNonce(nonce)
                    .apply {
                        if (cloudProjectNumber != null) {
                            setCloudProjectNumber(cloudProjectNumber.toLong())
                        }
                    }
                    .build()
            )

            task.addOnSuccessListener { response ->
                result.success(
                    mapOf(
                        "integrityToken" to response.token(),
                        "packageName" to context.packageName
                    )
                )
            }.addOnFailureListener { e ->
                result.error("IntegrityError", e.message, null)
            }
        } catch (e: Exception) {
            result.error("IntegrityError", e.message, null)
        }
    }
}
