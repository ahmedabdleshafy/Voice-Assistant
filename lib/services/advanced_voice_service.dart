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
    
    _updateError('فشل في تهيئة الخدمة الصوتية بعد جميع المحاولات');
    return false;
  }

  /// Strategy 1: Standard initialization with enhanced error handling
  Future<bool> _tryStandardInit() async {
    try {
      _updateStatus('المحاولة الأولى: التهيئة القياسية...');
      
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

  /// Start listening with enhanced error handling
  Future<bool> startListening() async {
    if (!_isInitialized || !_speechEnabled) {
      _updateError('الخدمة الصوتية غير مهيأة');
      return false;
    }

    if (_isListening) {
      await stopListening();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    try {
      _updateStatus('بدء الاستماع...');
      
      final success = await _speechToText.listen(
        onResult: _handleSpeechResult,
        localeId: _selectedLocale,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.confirmation,
      );

      if (success) {
        _isListening = true;
        _updateStatus('جاري الاستماع... تحدث الآن');
        return true;
      } else {
        _updateError('فشل في بدء الاستماع');
        return false;
      }
    } catch (e) {
      _updateError('خطأ في بدء الاستماع: $e');
      return false;
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
