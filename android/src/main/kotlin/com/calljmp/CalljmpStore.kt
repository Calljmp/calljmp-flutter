package com.calljmp

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import androidx.core.content.edit
import java.nio.charset.StandardCharsets
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class CalljmpStore private constructor(
    private val context: Context,
    private val channel: MethodChannel
) : MethodCallHandler {
    private val keyAlias = "CalljmpStoreKey"
    private val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
    private val sharedPrefsName = "CalljmpSecurePrefs"
    private val ivPrefix = "iv_"

    companion object {
        fun bind(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding): CalljmpStore {
            val device = CalljmpStore(
                flutterPluginBinding.applicationContext,
                MethodChannel(flutterPluginBinding.binaryMessenger, "calljmp_store")
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
            "securePut" -> securePut(call, result)
            "secureGet" -> secureGet(call, result)
            "secureDelete" -> secureDelete(call, result)
            else -> result.notImplemented()
        }
    }

    private fun getOrCreateKey(): SecretKey {
        if (!keyStore.containsAlias(keyAlias)) {
            val keyGenerator = KeyGenerator.getInstance(
                KeyProperties.KEY_ALGORITHM_AES,
                "AndroidKeyStore"
            )
            val keySpec = KeyGenParameterSpec.Builder(
                keyAlias,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build()
            keyGenerator.init(keySpec)
            return keyGenerator.generateKey()
        }
        return keyStore.getKey(keyAlias, null) as SecretKey
    }

    private fun securePut(call: MethodCall, result: Result) {
        try {
            val value = call.argument<String>("value")
                ?: throw IllegalArgumentException("Value cannot be null")
            val key =
                call.argument<String>("key") ?: throw IllegalArgumentException("Key cannot be null")

            val secretKey = getOrCreateKey()
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.ENCRYPT_MODE, secretKey)

            val iv = cipher.iv
            val encryptedBytes = cipher.doFinal(value.toByteArray(StandardCharsets.UTF_8))

            val encryptedValue = Base64.encodeToString(encryptedBytes, Base64.DEFAULT)
            val ivValue = Base64.encodeToString(iv, Base64.DEFAULT)

            context.getSharedPreferences(sharedPrefsName, Context.MODE_PRIVATE).edit {
                putString(key, encryptedValue)
                putString("$ivPrefix$key", ivValue)
            }

            result.success(true)
        } catch (e: Exception) {
            result.error("EncryptionError", e.message, null)
        }
    }

    private fun secureGet(call: MethodCall, result: Result) {
        try {
            val key =
                call.argument<String>("key") ?: throw IllegalArgumentException("Key cannot be null")

            val prefs = context.getSharedPreferences(sharedPrefsName, Context.MODE_PRIVATE)
            val encryptedValue = prefs.getString(key, null)
            val ivValue = prefs.getString("$ivPrefix$key", null)

            if (encryptedValue == null || ivValue == null) {
                result.success(null)
                return
            }

            val secretKey = getOrCreateKey()
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            val iv = Base64.decode(ivValue, Base64.DEFAULT)
            val spec = GCMParameterSpec(128, iv)

            cipher.init(Cipher.DECRYPT_MODE, secretKey, spec)
            val encryptedBytes = Base64.decode(encryptedValue, Base64.DEFAULT)
            val decryptedBytes = cipher.doFinal(encryptedBytes)

            result.success(String(decryptedBytes, StandardCharsets.UTF_8))
        } catch (e: Exception) {
            result.error("DecryptionError", e.message, null)
        }
    }

    private fun secureDelete(call: MethodCall, result: Result) {
        try {
            val key =
                call.argument<String>("key") ?: throw IllegalArgumentException("Key cannot be null")

            context.getSharedPreferences(sharedPrefsName, Context.MODE_PRIVATE).edit {
                remove(key)
                remove("$ivPrefix$key")
            }

            result.success(true)
        } catch (e: Exception) {
            result.error("DeletionError", e.message, null)
        }
    }
}
