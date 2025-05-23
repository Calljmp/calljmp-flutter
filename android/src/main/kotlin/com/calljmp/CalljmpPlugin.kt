package com.calljmp

import io.flutter.embedding.engine.plugins.FlutterPlugin

class CalljmpPlugin : FlutterPlugin {
    private lateinit var device: CalljmpDevice
    private lateinit var store: CalljmpStore

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        device = CalljmpDevice.bind(flutterPluginBinding)
        store = CalljmpStore.bind(flutterPluginBinding)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        device.unbind()
        store.unbind()
    }
}
