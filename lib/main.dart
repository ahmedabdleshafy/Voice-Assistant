import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'services/ai_service.dart';
import 'services/command_processor.dart';
import 'services/advanced_voice_service.dart';

void main() {
  runApp(const RafiqApp());
}

class RafiqApp extends StatelessWidget {
  const RafiqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'رفيق',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyan,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyan,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system, // Automatically switch based on system settings
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AdvancedVoiceService _voiceService = AdvancedVoiceService();
  final AIService _aiService = AIService();
  final CommandProcessor _commandProcessor = CommandProcessor();
  
  bool _speechEnabled = false;
  String _lastWords = '';
  String _statusText = ''; // To display status and error messages
  String _responseText = ''; // AI response text
  bool _isProcessing = false; // Show processing indicator
  bool _isInitializing = true; // Show initialization status

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  /// Initialize all services with advanced voice recognition
  void _initServices() async {
    setState(() {
      _isInitializing = true;
      _statusText = 'تهيئة الخدمات...';
    });

    try {
      // Initialize AI service
      await _aiService.initialize();
      
      // Initialize advanced voice service with callbacks
      _speechEnabled = await _voiceService.initialize(
        onResult: (result) {
          setState(() {
            _lastWords = result;
          });
          if (result.isNotEmpty) {
            _processVoiceCommand(result);
          }
        },
        onError: (error) {
          setState(() {
            _statusText = error;
          });
        },
        onStatus: (status) {
          setState(() {
            _statusText = status;
          });
        },
      );
      
      setState(() {
        _isInitializing = false;
        if (_speechEnabled) {
          _statusText = 'جاهز للاستخدام - اضغط على الميكروفون';
        } else {
          _statusText = 'فشل في تهيئة الميكروفون';
        }
      });
      
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _statusText = 'خطأ في التهيئة: $e';
      });
    }
  }

  /// Start advanced listening with multiple initialization strategies
  void _startAdvancedListening() async {
    if (!_speechEnabled) {
      setState(() {
        _statusText = 'الميكروفون غير متاح';
      });
      return;
    }

    final success = await _voiceService.startListening();
    if (!success) {
      setState(() {
        _statusText = 'فشل في بدء الاستماع';
      });
    }
  }

  /// Stop advanced listening
  void _stopAdvancedListening() async {
    await _voiceService.stopListening();
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
    });

    // After recognition, process with AI and execute command
    if (result.finalResult && _lastWords.isNotEmpty) {
      _processVoiceCommand(_lastWords);
    }
  }

  /// Process voice command using AI service and command processor
  void _processVoiceCommand(String voiceText) async {
    setState(() {
      _isProcessing = true;
      _statusText = 'معالجة الأمر...';
      _responseText = '';
    });

    try {
      // Process command and get response
      final response = await _commandProcessor.processCommand(voiceText);
      
      setState(() {
        _responseText = response;
        _statusText = 'تم تنفيذ الأمر';
        _isProcessing = false;
      });

      // Speak the response
      await _speak(response);
      
    } catch (e) {
      setState(() {
        _responseText = 'عذراً، حدث خطأ في معالجة طلبك';
        _statusText = 'خطأ: $e';
        _isProcessing = false;
      });
      
      await _speak('عذراً، حدث خطأ في معالجة طلبك');
    }
  }

  Future<void> _speak(String text) async {
    await _voiceService.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('رفيق', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: Show conversation history
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Spacer(),
            
            // Voice input display
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'ما قلته:',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _voiceService.isListening
                        ? (_lastWords.isEmpty ? 'استمع...' : _lastWords)
                        : _speechEnabled
                            ? (_lastWords.isEmpty ? 'اضغط على الميكروفون للبدء' : _lastWords)
                            : 'الميكروفون غير متاح. $_statusText',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // AI Response display
            if (_responseText.isNotEmpty || _isProcessing)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.smart_toy,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'رفيق يجيب:',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isProcessing)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'معالجة...',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        _responseText,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            
            const SizedBox(height: 30),
            // This will be our main interaction button
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Change color when listening
                color: !_voiceService.isListening
                    ? (_isInitializing ? Colors.grey : Theme.of(context).colorScheme.primary)
                    : Colors.red,
                boxShadow: [
                  BoxShadow(
                    color: (!_voiceService.isListening
                            ? (_isInitializing ? Colors.grey : Theme.of(context).colorScheme.primary)
                            : Colors.red)
                        .withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: IconButton(
                // Start or stop listening when the button is pressed
                onPressed: _isInitializing ? null : (!_voiceService.isListening ? _startAdvancedListening : _stopAdvancedListening),
                icon: const Icon(Icons.mic, color: Colors.white, size: 48),
                iconSize: 72,
                padding: const EdgeInsets.all(24),
              ),
            ),
            const Spacer(),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
