package com.example.rafiq_app

import android.content.Context
import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val AUDIO_FOCUS_CHANNEL = "audio_focus"
    private val MICROPHONE_PERMISSIONS_CHANNEL = "microphone_permissions"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Audio focus channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_FOCUS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestAudioFocus" -> {
                        val success = requestAudioFocus()
                        result.success(success)
                    }
                    "releaseAudioFocus" -> {
                        releaseAudioFocus()
                        result.success(true)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
            
        // Microphone permissions channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MICROPHONE_PERMISSIONS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestPermissions" -> {
                        requestMicrophonePermissions()
                        result.success(true)
                    }
                    "checkPermissions" -> {
                        val hasPermission = checkMicrophonePermissions()
                        result.success(hasPermission)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }
    
    private fun requestAudioFocus(): Boolean {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        
        return try {
            val result = audioManager.requestAudioFocus(
                null,
                AudioManager.STREAM_MUSIC,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT
            )
            result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        } catch (e: Exception) {
            false
        }
    }
    
    private fun releaseAudioFocus() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        audioManager.abandonAudioFocus(null)
    }
    
    private fun requestMicrophonePermissions() {
        try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                if (checkSelfPermission(android.Manifest.permission.RECORD_AUDIO) != 
                    android.content.pm.PackageManager.PERMISSION_GRANTED) {
                    requestPermissions(
                        arrayOf(android.Manifest.permission.RECORD_AUDIO),
                        1001
                    )
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    private fun checkMicrophonePermissions(): Boolean {
        return if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            checkSelfPermission(android.Manifest.permission.RECORD_AUDIO) == 
                android.content.pm.PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }
}
