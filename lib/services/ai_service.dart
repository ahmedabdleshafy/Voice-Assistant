import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/conversation_context.dart';
import '../models/intent_result.dart';
import '../models/voice_command.dart';

/// Main AI service that handles intent recognition and conversation management
/// Uses free AI APIs (Hugging Face, local models) for processing
class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final Dio _dio = Dio();
  final Uuid _uuid = const Uuid();
  
  // Conversation context management
  ConversationContext? _currentContext;
  final List<VoiceCommand> _conversationHistory = [];
  
  // Hugging Face API configuration (free tier)
  static const String _huggingFaceApiUrl = 'https://api-inference.huggingface.co/models';
  static const String _intentClassificationModel = 'aubmindlab/bert-base-arabertv2';
  
  // Local AI fallback (when Hugging Face is unavailable)
  static const String _localAIUrl = 'http://localhost:11434'; // Ollama default port
  
  /// Initialize the AI service
  Future<void> initialize() async {
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    
    // Load conversation context from storage
    await _loadConversationContext();
    
    print('AI Service initialized successfully');
  }

  /// Process voice input and return intent with entities
  Future<IntentResult> processVoiceInput(String voiceText) async {
    try {
      // Create voice command record
      final command = VoiceCommand(
        id: _uuid.v4(),
        text: voiceText,
        timestamp: DateTime.now(),
        language: 'ar',
      );
      
      // Add to conversation history
      _conversationHistory.add(command);
      
      // Classify intent using free AI services
      final intentResult = await _classifyIntent(voiceText);
      
      // Update conversation context
      await _updateConversationContext(command, intentResult);
      
      return intentResult;
      
    } catch (e) {
      print('Error processing voice input: $e');
      return IntentResult.error('فشل في معالجة الأمر الصوتي');
    }
  }

  /// Classify user intent using Hugging Face or local AI
  Future<IntentResult> _classifyIntent(String text) async {
    // Try Hugging Face first (free tier)
    try {
      return await _classifyWithHuggingFace(text);
    } catch (e) {
      print('Hugging Face failed, trying local AI: $e');
      
      // Fallback to local AI (Ollama)
      try {
        return await _classifyWithLocalAI(text);
      } catch (e) {
        print('Local AI failed, using rule-based fallback: $e');
        
        // Final fallback: rule-based classification
        return _classifyWithRules(text);
      }
    }
  }

  /// Classify intent using Hugging Face Transformers (free tier)
  Future<IntentResult> _classifyWithHuggingFace(String text) async {
    final response = await _dio.post(
      '$_huggingFaceApiUrl/$_intentClassificationModel',
      data: {
        'inputs': text,
        'parameters': {
          'candidate_labels': [
            'إضافة موعد', // Add appointment
            'إضافة تذكير', // Add reminder
            'إضافة مصروف', // Add expense
            'عرض المواعيد', // Show appointments
            'عرض التذكيرات', // Show reminders
            'عرض المصاريف', // Show expenses
            'حذف موعد', // Delete appointment
            'تعديل موعد', // Edit appointment
            'الطقس', // Weather
            'الأخبار', // News
            'الوقت', // Time
            'التاريخ', // Date
            'حساب', // Calculate
            'ترجمة', // Translate
            'أخرى' // Other
          ]
        }
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer YOUR_HUGGING_FACE_TOKEN', // Replace with actual token
          'Content-Type': 'application/json',
        },
      ),
    );

    return _parseHuggingFaceResponse(response.data, text);
  }

  /// Classify intent using local AI (Ollama)
  Future<IntentResult> _classifyWithLocalAI(String text) async {
    final prompt = '''
تحليل النص العربي التالي وتحديد النية (Intent) والكيانات (Entities):

النص: "$text"

أرجع النتيجة بتنسيق JSON:
{
  "intent": "نوع النية",
  "confidence": 0.95,
  "entities": {
    "date": "التاريخ إن وجد",
    "time": "الوقت إن وجد",
    "amount": "المبلغ إن وجد",
    "description": "الوصف إن وجد"
  }
}

النيات المتاحة: إضافة_موعد، إضافة_تذكير، إضافة_مصروف، عرض_المواعيد، عرض_التذكيرات، عرض_المصاريف، حذف_موعد، تعديل_موعد، الطقس، الأخبار، الوقت، التاريخ، حساب، ترجمة، أخرى
''';

    final response = await _dio.post(
      '$_localAIUrl/api/generate',
      data: {
        'model': 'llama2', // or any Arabic-capable model
        'prompt': prompt,
        'stream': false,
      },
    );

    return _parseLocalAIResponse(response.data, text);
  }

  /// Rule-based intent classification (fallback)
  IntentResult _classifyWithRules(String text) {
    final lowerText = text.toLowerCase();
    
    // Appointment keywords
    if (lowerText.contains('موعد') || lowerText.contains('اجتماع') || lowerText.contains('لقاء')) {
      if (lowerText.contains('أضف') || lowerText.contains('احجز') || lowerText.contains('سجل')) {
        return IntentResult(
          intent: 'add_appointment',
          confidence: 0.8,
          entities: _extractEntitiesFromText(text),
          originalText: text,
        );
      } else if (lowerText.contains('عرض') || lowerText.contains('أظهر') || lowerText.contains('اعرض')) {
        return IntentResult(
          intent: 'show_appointments',
          confidence: 0.8,
          entities: {},
          originalText: text,
        );
      }
    }
    
    // Reminder keywords
    if (lowerText.contains('تذكير') || lowerText.contains('ذكرني')) {
      return IntentResult(
        intent: 'add_reminder',
        confidence: 0.8,
        entities: _extractEntitiesFromText(text),
        originalText: text,
      );
    }
    
    // Expense keywords
    if (lowerText.contains('مصروف') || lowerText.contains('دفعت') || lowerText.contains('اشتريت')) {
      return IntentResult(
        intent: 'add_expense',
        confidence: 0.8,
        entities: _extractEntitiesFromText(text),
        originalText: text,
      );
    }
    
    // Weather keywords
    if (lowerText.contains('طقس') || lowerText.contains('جو') || lowerText.contains('حرارة')) {
      return IntentResult(
        intent: 'weather',
        confidence: 0.8,
        entities: {},
        originalText: text,
      );
    }
    
    // Time keywords
    if (lowerText.contains('وقت') || lowerText.contains('ساعة') || lowerText.contains('كم الساعة')) {
      return IntentResult(
        intent: 'time',
        confidence: 0.8,
        entities: {},
        originalText: text,
      );
    }
    
    // Default: unknown intent
    return IntentResult(
      intent: 'unknown',
      confidence: 0.3,
      entities: {},
      originalText: text,
    );
  }

  /// Extract entities from text using simple patterns
  Map<String, dynamic> _extractEntitiesFromText(String text) {
    final entities = <String, dynamic>{};
    
    // Extract numbers (for amounts, times)
    final numberRegex = RegExp(r'\d+');
    final numbers = numberRegex.allMatches(text).map((m) => m.group(0)).toList();
    
    // Extract time patterns
    final timeRegex = RegExp(r'\d{1,2}:\d{2}|\d{1,2}\s*(ص|م|صباحا|مساء)');
    final timeMatch = timeRegex.firstMatch(text);
    if (timeMatch != null) {
      entities['time'] = timeMatch.group(0);
    }
    
    // Extract date patterns (simple)
    if (text.contains('غدا') || text.contains('غداً')) {
      entities['date'] = 'tomorrow';
    } else if (text.contains('اليوم')) {
      entities['date'] = 'today';
    } else if (text.contains('بعد غد')) {
      entities['date'] = 'day_after_tomorrow';
    }
    
    // Extract amounts
    if (numbers.isNotEmpty && (text.contains('ريال') || text.contains('درهم') || text.contains('دولار'))) {
      entities['amount'] = numbers.first;
    }
    
    return entities;
  }

  /// Parse Hugging Face API response
  IntentResult _parseHuggingFaceResponse(dynamic data, String originalText) {
    // Implementation depends on Hugging Face response format
    // This is a simplified version
    return IntentResult(
      intent: 'unknown',
      confidence: 0.5,
      entities: {},
      originalText: originalText,
    );
  }

  /// Parse local AI response
  IntentResult _parseLocalAIResponse(dynamic data, String originalText) {
    try {
      final responseText = data['response'] ?? '';
      final jsonMatch = RegExp(r'\{.*\}').firstMatch(responseText);
      
      if (jsonMatch != null) {
        final jsonData = json.decode(jsonMatch.group(0)!);
        return IntentResult(
          intent: jsonData['intent'] ?? 'unknown',
          confidence: (jsonData['confidence'] ?? 0.5).toDouble(),
          entities: Map<String, dynamic>.from(jsonData['entities'] ?? {}),
          originalText: originalText,
        );
      }
    } catch (e) {
      print('Error parsing local AI response: $e');
    }
    
    return IntentResult.error('فشل في تحليل الاستجابة');
  }

  /// Update conversation context
  Future<void> _updateConversationContext(VoiceCommand command, IntentResult result) async {
    _currentContext = ConversationContext(
      sessionId: _currentContext?.sessionId ?? _uuid.v4(),
      lastCommand: command,
      lastIntent: result,
      conversationHistory: List.from(_conversationHistory),
      timestamp: DateTime.now(),
    );
    
    await _saveConversationContext();
  }

  /// Load conversation context from storage
  Future<void> _loadConversationContext() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contextJson = prefs.getString('conversation_context');
      
      if (contextJson != null) {
        final contextData = json.decode(contextJson);
        _currentContext = ConversationContext.fromJson(contextData);
      }
    } catch (e) {
      print('Error loading conversation context: $e');
    }
  }

  /// Save conversation context to storage
  Future<void> _saveConversationContext() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentContext != null) {
        await prefs.setString('conversation_context', json.encode(_currentContext!.toJson()));
      }
    } catch (e) {
      print('Error saving conversation context: $e');
    }
  }

  /// Get current conversation context
  ConversationContext? get currentContext => _currentContext;

  /// Get conversation history
  List<VoiceCommand> get conversationHistory => List.unmodifiable(_conversationHistory);

  /// Clear conversation context
  Future<void> clearContext() async {
    _currentContext = null;
    _conversationHistory.clear();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('conversation_context');
  }
}
