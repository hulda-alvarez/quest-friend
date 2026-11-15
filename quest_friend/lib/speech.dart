import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'models.dart';

/// Wraps speech_to_text (works on Android and in Chrome).
class SpeechController extends ChangeNotifier {
  final SpeechToText _stt = SpeechToText();
  bool _ready = false;
  bool _delivered = false;
  void Function(String text)? _onFinal;

  bool listening = false;
  String transcript = '';
  String? error;

  Future<bool> _init() async {
    if (_ready) return true;
    try {
      _ready = await _stt.initialize(
        onStatus: (s) {
          if (s == 'done' || s == 'notListening') _finish();
        },
        onError: (e) {
          listening = false;
          error = _friendly(e.errorMsg);
          notifyListeners();
        },
      );
    } catch (_) {
      _ready = false;
    }
    return _ready;
  }

  String _friendly(String code) {
    switch (code) {
      case 'error_no_match':
      case 'error_speech_timeout':
        return "Didn't catch that. Tap the mic and try again.";
      case 'error_language_not_supported':
      case 'error_language_unavailable':
        return "Speech recognition isn't available for that language on this device. You can type instead.";
      case 'error_permission':
        return 'Microphone permission is needed. Allow it and try again.';
      default:
        return 'Speech recognition stopped ($code). You can type instead.';
    }
  }

  Future<void> start({
    String? localeId,
    required void Function(String partial) onPartial,
    required void Function(String finalText) onFinal,
  }) async {
    if (listening) return;
    final ok = await _init();
    if (!ok) {
      error =
          "Speech recognition isn't available here. In Chrome, allow the microphone; on Android, check the microphone permission.";
      notifyListeners();
      return;
    }
    transcript = '';
    error = null;
    _delivered = false;
    _onFinal = onFinal;
    listening = true;
    notifyListeners();
    try {
      await _stt.listen(
        localeId: localeId,
        listenFor: const Duration(seconds: 45),
        pauseFor: const Duration(seconds: 4),
        onResult: (r) {
          transcript = r.recognizedWords;
          onPartial(transcript);
          if (r.finalResult) _finish();
          notifyListeners();
        },
      );
    } catch (_) {
      listening = false;
      error = 'Could not start the microphone.';
      notifyListeners();
    }
  }

  void _finish() {
    if (_delivered || !listening) return;
    _delivered = true;
    listening = false;
    final t = transcript;
    notifyListeners();
    if (t.trim().isNotEmpty) _onFinal?.call(t);
  }

  Future<void> stop() async {
    try {
      await _stt.stop();
    } catch (_) {}
    // Give the engine a moment to deliver its final words, then finish.
    Future.delayed(const Duration(milliseconds: 900), _finish);
  }

  @override
  void dispose() {
    try {
      _stt.cancel();
    } catch (_) {}
    super.dispose();
  }
}

/// Reads text aloud in the right language (flutter_tts).
class Speaker {
  Speaker._();
  static final Speaker I = Speaker._();
  final FlutterTts _tts = FlutterTts();

  Future<void> speak(String text, Lang lang) async {
    try {
      await _tts.stop();
      await _tts.setLanguage(lang.tts);
      await _tts.speak(text);
    } catch (_) {
      // Text-to-speech is a nice-to-have; fail silently.
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
