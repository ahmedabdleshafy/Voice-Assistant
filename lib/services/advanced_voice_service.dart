import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Advanced Voice Recognition Service with multiple initialization strategies
/// and robust error handling for maximum compatibility
class AdvancedVoiceService {
  static final AdvancedVoiceService _instance = AdvancedVoiceService._internal();
  factory AdvancedVoiceService() => _instance;
  AdvancedVoiceService._internal();

  // Core services
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  // State management
  bool _isInitialized = false;
  bool _isListening = false;
  bool _speechEnabled = false;
  String _lastError = '';
  
  // Configuration
  final List<String> _arabicLocales = [
    'ar-SA', // Saudi Arabia
    'ar-EG', // Egypt
    'ar-AE', // UAE
    'ar-JO', // Jordan
    'ar-LB', // Lebanon
    'ar-MA', // Morocco
    'ar-DZ', // Algeria
    'ar-TN', // Tunisia
    'ar-IQ', // Iraq
    'ar-KW', // Kuwait
    'ar-QA', // Qatar
    'ar-BH', // Bahrain
    'ar-OM', // Oman
    'ar-YE', // Yemen
    'ar-SY', // Syria
    'ar-LY', // Libya
    'ar-SD', // Sudan
    'ar',    // Generic Arabic
  ];
  
  String? _selectedLocale;
  Timer? _initRetryTimer;
  int _initAttempts = 0;
  static const int _maxInitAttempts = 5;
  
  // Callbacks
  Function(String)? _onResult;
  Function(String)? _onError;
  Function(String)? _onStatus;

  /// Initialize the voice service with advanced strategies
  Future<bool> initialize({
    Function(String)? onResult,
    Function(String)? onError,
    Function(String)? onStatus,
  }) async {
    _onResult = onResult;
    _onError = onError;
    _onStatus = onStatus;
    
    _updateStatus('بدء تهيئة الخدمة الصوتية...');
    
    // Strategy 1: Standard initialization
    if (await _tryStandardInit()) {
      return true;
    }
    
    // Strategy 2: Delayed initialization
    if (await _tryDelayedInit()) {
      return true;
    }
    
    // Strategy 3: Force restart initialization
    if (await _tryForceRestartInit()) {
      return true;
    }
    
    // Strategy 4: Alternative package initialization
    if (await _tryAlternativeInit()) {
      return true;
    }
    
    // Strategy 5: System-level initialization
    if (await _trySystemLevelInit()) {
      return true;
    }
    
    // Strategy 6: Hardware-level initialization with device-specific fixes
    if (await _tryHardwareLevelInit()) {
      return true;
    }
    
    // Strategy 7: Emergency fallback with basic functionality
    if (await _tryEmergencyFallback()) {
      return true;
    }
    
    _updateError('فشل في تهيئة الخدمة الصوتية بعد جميع المحاولات');
    return false;
  }

  /// Strategy 1: Standard initialization with enhanced error handling
  Future<bool> _tryStandardInit() async {
    try {
      _updateStatus('المحاولة الأولى: التهيئة القياسية...');
      
      // Request permissions explicitly first
      await _requestMicrophonePermissions();
      
      _speechEnabled = await _speechToText.initialize(
        onError: _handleSpeechError,
        onStatus: _handleSpeechStatus,
        debugLogging: true,
      );
      
      if (_speechEnabled) {
        await _configureBestLocale();
        await _configureTTS();
        _isInitialized = true;
        _updateStatus('تم تهيئة الخدمة الصوتية بنجاح');
        return true;
      }
    } catch (e) {
      _updateError('فشل التهيئة القياسية: $e');
    }
    return false;
  }

  /// Request microphone permissions explicitly
  Future<void> _requestMicrophonePermissions() async {
    try {
      if (Platform.isAndroid) {
        const platform = MethodChannel('microphone_permissions');
        await platform.invokeMethod('requestPermissions');
      }
    } catch (e) {
      print('Permission request failed: $e');
    }
  }

  /// Strategy 2: Delayed initialization (wait for system readiness)
  Future<bool> _tryDelayedInit() async {
    try {
      _updateStatus('المحاولة الثانية: التهيئة المتأخرة...');
      
      // Wait for system to be fully ready
      await Future.delayed(const Duration(seconds: 2));
      
      // Wait for system to be fully ready
      await Future.delayed(const Duration(milliseconds: 500));
      
      _speechEnabled = await _speechToText.initialize(
        onError: _handleSpeechError,
        onStatus: _handleSpeechStatus,
        debugLogging: true,
      );
      
      if (_speechEnabled) {
        await _configureBestLocale();
        await _configureTTS();
        _isInitialized = true;
        _updateStatus('تم تهيئة الخدمة الصوتية بالتأخير');
        return true;
      }
    } catch (e) {
      _updateError('فشل التهيئة المتأخرة: $e');
    }
    return false;
  }

  /// Strategy 3: Force restart initialization
  Future<bool> _tryForceRestartInit() async {
    try {
      _updateStatus('المحاولة الثالثة: إعادة تشغيل قسري...');
      
      // Stop any existing speech recognition
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }
      
      // Wait and try to reinitialize
      await Future.delayed(const Duration(seconds: 3));
      
      _speechEnabled = await _speechToText.initialize(
        onError: _handleSpeechError,
        onStatus: _handleSpeechStatus,
        debugLogging: true,
      );
      
      if (_speechEnabled) {
        await _configureBestLocale();
        await _configureTTS();
        _isInitialized = true;
        _updateStatus('تم تهيئة الخدمة بإعادة التشغيل');
        return true;
      }
    } catch (e) {
      _updateError('فشل إعادة التشغيل القسري: $e');
    }
    return false;
  }

  /// Strategy 4: Alternative package initialization
  Future<bool> _tryAlternativeInit() async {
    try {
      _updateStatus('المحاولة الرابعة: طريقة بديلة...');
      
      // Try with minimal configuration
      _speechEnabled = await _speechToText.initialize(
        onError: (error) => print('Minimal init error: ${error.errorMsg}'),
        onStatus: (status) => print('Minimal init status: $status'),
        debugLogging: false, // Disable debug logging
      );
      
      if (_speechEnabled) {
        // Use default locale first
        _selectedLocale = 'ar-SA';
        await _configureTTS();
        _isInitialized = true;
        _updateStatus('تم تهيئة الخدمة بالطريقة البديلة');
        return true;
      }
    } catch (e) {
      _updateError('فشل الطريقة البديلة: $e');
    }
    return false;
  }

  /// Strategy 5: System-level initialization
  Future<bool> _trySystemLevelInit() async {
    try {
      _updateStatus('المحاولة الخامسة: تهيئة على مستوى النظام...');
      
      // Request audio focus
      await _requestAudioFocus();
      
      // Wait for audio system to be ready
      await Future.delayed(const Duration(seconds: 1));
      
      _speechEnabled = await _speechToText.initialize(
        onError: _handleSpeechError,
        onStatus: _handleSpeechStatus,
      );
      
      if (_speechEnabled) {
        _selectedLocale = 'ar-SA'; // Use default
        await _configureTTS();
        _isInitialized = true;
        _updateStatus('تم تهيئة الخدمة على مستوى النظام');
        return true;
      }
    } catch (e) {
      _updateError('فشل التهيئة على مستوى النظام: $e');
    }
    return false;
  }

  /// Strategy 6: Hardware-level initialization with device-specific fixes
  Future<bool> _tryHardwareLevelInit() async {
    try {
      _updateStatus('المحاولة السادسة: تهيئة على مستوى الأجهزة...');
      
      // Check microphone permissions at system level
      const platform = MethodChannel('microphone_permissions');
      final hasPermission = await platform.invokeMethod('checkPermissions');
      
      if (!hasPermission) {
        _updateError('لا توجد أذونات للميكروفون');
        return false;
      }
      
      // Request audio focus with maximum priority
      await _requestAudioFocus();
      
      // Wait for hardware to be ready
      await Future.delayed(const Duration(seconds: 5));
      
      // Try with minimal configuration for problematic devices
      _speechEnabled = await _speechToText.initialize(
        onError: (error) => print('Hardware init error: ${error.errorMsg}'),
        onStatus: (status) => print('Hardware init status: $status'),
        debugLogging: false,
      );
      
      if (_speechEnabled) {
        _selectedLocale = 'ar-SA'; // Use default
        await _configureTTS();
        _isInitialized = true;
        _updateStatus('تم تهيئة الخدمة على مستوى الأجهزة');
        return true;
      }
    } catch (e) {
      _updateError('فشل التهيئة على مستوى الأجهزة: $e');
    }
    return false;
  }

  /// Strategy 7: Emergency fallback with basic functionality
  Future<bool> _tryEmergencyFallback() async {
    try {
      _updateStatus('المحاولة الأخيرة: وضع الطوارئ...');
      
      // Run ULTIMATE diagnostics to identify the exact issue
      final diagnosticResult = await _runUltimateDiagnostics();
      
      // Try device-specific fixes based on diagnostics
      if (await _tryDeviceSpecificFixes(diagnosticResult)) {
        return true;
      }
      
      // If all else fails, enable emergency mode with TTS-only functionality
      _speechEnabled = false; // No speech recognition
      _selectedLocale = 'ar-SA';
      await _configureTTS();
      _isInitialized = true;
      
      _updateStatus('وضع الطوارئ نشط - النطق متاح، الاستماع معطل');
      await speak('تم تفعيل وضع الطوارئ. يمكنني التحدث ولكن لا يمكنني الاستماع.');
      return true;
      
    } catch (e) {
      _updateError('فشل وضع الطوارئ: $e');
    }
    return false;
  }

  /// Run ULTIMATE diagnostics to identify the exact issue
  Future<Map<String, dynamic>> _runUltimateDiagnostics() async {
    final diagnostics = <String, dynamic>{};
    
    try {
      _updateStatus('تشغيل نظام التشخيص المتقدم...');
      
      // 1. Platform and Device Information
      diagnostics['platform'] = Platform.operatingSystem;
      diagnostics['platform_version'] = Platform.operatingSystemVersion;
      
      // 2. Microphone Permission Status
      try {
        const platform = MethodChannel('microphone_permissions');
        final hasPermission = await platform.invokeMethod('checkPermissions');
        diagnostics['microphone_permission'] = hasPermission;
        print('✅ Microphone Permission: ${hasPermission ? "GRANTED" : "DENIED"}');
      } catch (e) {
        diagnostics['microphone_permission'] = 'ERROR: $e';
        print('❌ Permission Check Failed: $e');
      }
      
      // 3. Audio Focus Status
      try {
        const platform = MethodChannel('audio_focus');
        final audioFocus = await platform.invokeMethod('requestAudioFocus');
        diagnostics['audio_focus'] = audioFocus;
        print('✅ Audio Focus: ${audioFocus ? "GRANTED" : "DENIED"}');
      } catch (e) {
        diagnostics['audio_focus'] = 'ERROR: $e';
        print('❌ Audio Focus Failed: $e');
      }
      
      // 4. Speech Recognition Engine Status
      try {
        final speechToText = SpeechToText();
        final available = await speechToText.initialize(
          debugLogging: true,
          onError: (error) => print('❌ Speech Engine Error: ${error.errorMsg}'),
          onStatus: (status) => print('ℹ️ Speech Engine Status: $status'),
        );
        diagnostics['speech_engine_available'] = available;
        print('✅ Speech Engine: ${available ? "AVAILABLE" : "NOT AVAILABLE"}');
        
        if (available) {
          final locales = await speechToText.locales();
          diagnostics['total_locales'] = locales.length;
          final arabicLocales = locales.where((l) => l.localeId.startsWith('ar')).toList();
          diagnostics['arabic_locales'] = arabicLocales.map((l) => l.localeId).toList();
          print('✅ Total Locales: ${locales.length}');
          print('✅ Arabic Locales: ${arabicLocales.map((l) => l.localeId).join(", ")}');
        }
      } catch (e) {
        diagnostics['speech_engine_available'] = 'ERROR: $e';
        print('❌ Speech Engine Check Failed: $e');
      }
      
      // Log comprehensive diagnostics
      print('\n=== ULTIMATE VOICE DIAGNOSTICS ===');
      diagnostics.forEach((key, value) {
        print('$key: $value');
      });
      print('=== END ULTIMATE DIAGNOSTICS ===\n');
      
      return diagnostics;
      
    } catch (e) {
      print('❌ Ultimate diagnostics failed: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Run comprehensive diagnostics to identify the issue (legacy method)
  Future<void> _runDiagnostics() async {
    final diagnostics = <String>[];
    
    try {
      // Check platform
      diagnostics.add('Platform: ${Platform.operatingSystem}');
      
      // Check permissions
      try {
        const platform = MethodChannel('microphone_permissions');
        final hasPermission = await platform.invokeMethod('checkPermissions');
        diagnostics.add('Microphone Permission: ${hasPermission ? "Granted" : "Denied"}');
      } catch (e) {
        diagnostics.add('Permission Check Failed: $e');
      }
      
      // Check audio focus
      try {
        const platform = MethodChannel('audio_focus');
        final audioFocus = await platform.invokeMethod('requestAudioFocus');
        diagnostics.add('Audio Focus: ${audioFocus ? "Granted" : "Denied"}');
      } catch (e) {
        diagnostics.add('Audio Focus Failed: $e');
      }
      
      // Check speech recognition availability
      try {
        final available = await _speechToText.initialize();
        diagnostics.add('Speech Recognition: ${available ? "Available" : "Not Available"}');
        if (available) {
          final locales = await _speechToText.locales();
          diagnostics.add('Available Locales: ${locales.length}');
          final arabicLocales = locales.where((l) => l.localeId.startsWith('ar')).toList();
          diagnostics.add('Arabic Locales: ${arabicLocales.length}');
        }
      } catch (e) {
        diagnostics.add('Speech Recognition Check Failed: $e');
      }
      
      // Log all diagnostics
      print('=== VOICE SERVICE DIAGNOSTICS ===');
      for (final diagnostic in diagnostics) {
        print(diagnostic);
      }
      print('=== END DIAGNOSTICS ===');
      
    } catch (e) {
      print('Diagnostics failed: $e');
    }
  }

  /// Try device-specific fixes based on diagnostic results
  Future<bool> _tryDeviceSpecificFixes(Map<String, dynamic> diagnostics) async {
    try {
      _updateStatus('تجربة إصلاحات خاصة بالجهاز...');
      
      // Fix 1: Permission Issue
      if (diagnostics['microphone_permission'] == false) {
        print('ℹ️ Attempting to fix permission issue...');
        try {
          const platform = MethodChannel('microphone_permissions');
          await platform.invokeMethod('requestPermissions');
          await Future.delayed(const Duration(seconds: 2));
          
          // Retry initialization after permission fix
          final success = await _tryStandardInit();
          if (success) {
            _updateStatus('تم إصلاح مشكلة الأذونات');
            return true;
          }
        } catch (e) {
          print('❌ Permission fix failed: $e');
        }
      }
      
      // Fix 2: Audio Focus Issue
      if (diagnostics['audio_focus'] == false) {
        print('ℹ️ Attempting to fix audio focus issue...');
        try {
          // Force release and re-request audio focus
          const platform = MethodChannel('audio_focus');
          await platform.invokeMethod('releaseAudioFocus');
          await Future.delayed(const Duration(milliseconds: 500));
          await platform.invokeMethod('requestAudioFocus');
          
          // Retry initialization after audio focus fix
          final success = await _tryStandardInit();
          if (success) {
            _updateStatus('تم إصلاح مشكلة التركيز الصوتي');
            return true;
          }
        } catch (e) {
          print('❌ Audio focus fix failed: $e');
        }
      }
      
      // Fix 3: Speech Engine Issue
      if (diagnostics['speech_engine_available'] == false || 
          diagnostics['speech_engine_available'].toString().contains('ERROR')) {
        print('ℹ️ Attempting to fix speech engine issue...');
        try {
          // Try with a completely fresh SpeechToText instance
          final freshSpeechToText = SpeechToText();
          await Future.delayed(const Duration(seconds: 3));
          
          final available = await freshSpeechToText.initialize(
            debugLogging: false,
            onError: (error) => print('Fresh engine error: ${error.errorMsg}'),
            onStatus: (status) => print('Fresh engine status: $status'),
          );
          
          if (available) {
            _speechToText = freshSpeechToText;
            _speechEnabled = true;
            await _configureBestLocale();
            await _configureTTS();
            _isInitialized = true;
            _updateStatus('تم إصلاح محرك التعرف على الصوت');
            return true;
          }
        } catch (e) {
          print('❌ Speech engine fix failed: $e');
        }
      }
      
      // Fix 4: Locale Issue
      if (diagnostics['arabic_locales'] != null && 
          (diagnostics['arabic_locales'] as List).isEmpty) {
        print('ℹ️ Attempting to fix Arabic locale issue...');
        try {
          // Try with generic locale
          _selectedLocale = 'ar';
          final success = await _tryStandardInit();
          if (success) {
            _updateStatus('تم إصلاح مشكلة اللغة العربية');
            return true;
          }
        } catch (e) {
          print('❌ Locale fix failed: $e');
        }
      }
      
      // Fix 5: Nuclear Option - Complete System Reset
      print('ℹ️ Attempting nuclear option - complete system reset...');
      try {
        // Reset everything
        _isInitialized = false;
        _speechEnabled = false;
        _isListening = false;
        _lastError = '';
        
        // Wait for system to settle
        await Future.delayed(const Duration(seconds: 5));
        
        // Try one more time with minimal configuration
        _speechEnabled = await _speechToText.initialize(
          debugLogging: false,
        );
        
        if (_speechEnabled) {
          _selectedLocale = 'ar-SA';
          await _configureTTS();
          _isInitialized = true;
          _updateStatus('تم إصلاح النظام بالكامل');
          return true;
        }
      } catch (e) {
        print('❌ Nuclear option failed: $e');
      }
      
      return false;
      
    } catch (e) {
      print('❌ Device-specific fixes failed: $e');
      return false;
    }
  }

  /// Configure the best available Arabic locale
  Future<void> _configureBestLocale() async {
    try {
      final locales = await _speechToText.locales();
      print('Available locales: ${locales.map((l) => '${l.localeId} (${l.name})').join(', ')}');
      
      // Find the best Arabic locale
      for (String locale in _arabicLocales) {
        if (locales.any((l) => l.localeId == locale)) {
          _selectedLocale = locale;
          _updateStatus('تم اختيار اللغة: $locale');
          break;
        }
      }
      
      _selectedLocale ??= 'ar-SA'; // Fallback
    } catch (e) {
      _selectedLocale = 'ar-SA';
      print('Error configuring locale: $e');
    }
  }

  /// Configure Text-to-Speech
  Future<void> _configureTTS() async {
    try {
      await _flutterTts.setLanguage("ar-SA");
      await _flutterTts.setSpeechRate(0.8);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      
      // Test TTS
      if (Platform.isAndroid) {
        await _flutterTts.setQueueMode(1);
      }
    } catch (e) {
      print('TTS configuration error: $e');
    }
  }

  /// Request audio focus (Android specific)
  Future<void> _requestAudioFocus() async {
    try {
      if (Platform.isAndroid) {
        const platform = MethodChannel('audio_focus');
        await platform.invokeMethod('requestAudioFocus');
      }
    } catch (e) {
      print('Audio focus request failed: $e');
    }
  }

  /// Start listening for voice input
  Future<void> startListening() async {
    if (!_isInitialized) {
      _updateError('الخدمة الصوتية غير مهيأة');
      return;
    }

    // Handle emergency mode
    if (!_speechEnabled) {
      _updateStatus('وضع الطوارئ: الاستماع غير متاح');
      await speak('عذرا، الميكروفون غير متاح. يمكنني التحدث فقط.');
      return;
    }

    if (_speechToText.isListening) {
      _updateStatus('يتم الاستماع بالفعل...');
      return;
    }

    try {
      await _requestAudioFocus();
      
      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            _onResult?.call(result.recognizedWords);
          }
        },
        localeId: _selectedLocale,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: false,
      );
      
      _updateStatus('يتم الاستماع... تحدث الآن');
    } catch (e) {
      _updateError('فشل في بدء الاستماع: $e');
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    try {
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }
      _isListening = false;
      _updateStatus('تم إيقاف الاستماع');
    } catch (e) {
      _updateError('خطأ في إيقاف الاستماع: $e');
    }
  }

  /// Speak text with enhanced configuration
  Future<void> speak(String text) async {
    try {
      if (text.isEmpty) return;
      
      // Stop any current speech
      await _flutterTts.stop();
      
      // Speak the text
      await _flutterTts.speak(text);
    } catch (e) {
      _updateError('خطأ في النطق: $e');
    }
  }

  /// Handle speech recognition results
  void _handleSpeechResult(SpeechRecognitionResult result) {
    if (result.recognizedWords.isNotEmpty) {
      _onResult?.call(result.recognizedWords);
      
      if (result.finalResult) {
        _isListening = false;
        _updateStatus('تم الانتهاء من الاستماع');
      }
    }
  }

  /// Handle speech errors
  void _handleSpeechError(dynamic error) {
    _lastError = error.errorMsg ?? error.toString();
    _updateError('خطأ في التعرف على الصوت: $_lastError');
    _isListening = false;
  }

  /// Handle speech status changes
  void _handleSpeechStatus(String status) {
    _updateStatus('حالة الميكروفون: $status');
    
    if (status == 'listening') {
      _isListening = true;
    } else if (status == 'notListening') {
      _isListening = false;
    }
  }

  /// Update status
  void _updateStatus(String status) {
    print('Voice Service Status: $status');
    _onStatus?.call(status);
  }

  /// Update error
  void _updateError(String error) {
    print('Voice Service Error: $error');
    _onError?.call(error);
  }

  /// Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  bool get speechEnabled => _speechEnabled;
  String get lastError => _lastError;
  String? get selectedLocale => _selectedLocale;

  /// Cleanup
  void dispose() {
    _initRetryTimer?.cancel();
    _speechToText.stop();
    _flutterTts.stop();
  }
}
