import 'package:flutter/foundation.dart';

/// A language the traveler can translate from/to.
class Lang {
  final String name; // English name, also what we send to Gemini
  final String native; // name in its own script
  final String tts; // BCP-47 tag for text-to-speech
  final String stt; // locale id for speech-to-text
  const Lang(this.name, this.native, this.tts, this.stt);
  @override
  String toString() => name;
}

const List<Lang> kLanguages = [
  Lang('English', 'English', 'en-US', 'en_US'),
  Lang('Spanish', 'Español', 'es-ES', 'es_ES'),
  Lang('French', 'Français', 'fr-FR', 'fr_FR'),
  Lang('German', 'Deutsch', 'de-DE', 'de_DE'),
  Lang('Italian', 'Italiano', 'it-IT', 'it_IT'),
  Lang('Portuguese', 'Português', 'pt-BR', 'pt_BR'),
  Lang('Greek', 'Ελληνικά', 'el-GR', 'el_GR'),
  Lang('Turkish', 'Türkçe', 'tr-TR', 'tr_TR'),
  Lang('Arabic', 'العربية', 'ar-SA', 'ar_SA'),
  Lang('Hindi', 'हिन्दी', 'hi-IN', 'hi_IN'),
  Lang('Japanese', '日本語', 'ja-JP', 'ja_JP'),
  Lang('Korean', '한국어', 'ko-KR', 'ko_KR'),
  Lang('Chinese (Simplified)', '简体中文', 'zh-CN', 'zh_CN'),
  Lang('Chinese (Traditional)', '繁體中文', 'zh-TW', 'zh_TW'),
  Lang('Thai', 'ไทย', 'th-TH', 'th_TH'),
  Lang('Vietnamese', 'Tiếng Việt', 'vi-VN', 'vi_VN'),
  Lang('Indonesian', 'Bahasa Indonesia', 'id-ID', 'id_ID'),
  Lang('Russian', 'Русский', 'ru-RU', 'ru_RU'),
  Lang('Dutch', 'Nederlands', 'nl-NL', 'nl_NL'),
  Lang('Polish', 'Polski', 'pl-PL', 'pl_PL'),
  Lang('Swahili', 'Kiswahili', 'sw-KE', 'sw_KE'),
];

Lang langByName(String name) =>
    kLanguages.firstWhere((l) => l.name == name, orElse: () => kLanguages.first);

/// Popular destinations; picking one also suggests the local language.
class Destination {
  final String country;
  final String language;
  const Destination(this.country, this.language);
}

const List<Destination> kDestinations = [
  Destination('Greece', 'Greek'),
  Destination('Italy', 'Italian'),
  Destination('Turkey', 'Turkish'),
  Destination('Japan', 'Japanese'),
  Destination('South Korea', 'Korean'),
  Destination('Thailand', 'Thai'),
  Destination('France', 'French'),
  Destination('Spain', 'Spanish'),
  Destination('Mexico', 'Spanish'),
  Destination('Brazil', 'Portuguese'),
  Destination('Egypt', 'Arabic'),
  Destination('India', 'Hindi'),
  Destination('Vietnam', 'Vietnamese'),
  Destination('Germany', 'German'),
];

/// Shared trip settings (in memory only, as requested).
class TripState extends ChangeNotifier {
  TripState._();
  static final TripState I = TripState._();

  String? country;
  Lang myLang = kLanguages.first; // English by default
  Lang localLang = langByName('Greek');

  bool get isSetUp => country != null && country!.trim().isNotEmpty;
  String get key => '$country|${myLang.name}|${localLang.name}';

  void configure({required String country, required Lang my, required Lang local}) {
    this.country = country.trim();
    myLang = my;
    localLang = local;
    notifyListeners();
  }
}

// ---------------------------------------------------------------------------
// Gemini result models
// ---------------------------------------------------------------------------

class GroundingLink {
  final String title;
  final String uri;
  final String? placeId;
  const GroundingLink({required this.title, required this.uri, this.placeId});
}

class GeminiResult {
  final String text;
  final List<GroundingLink> maps;
  final List<GroundingLink> web;
  final bool usedFallback; // true when a grounding tool was unavailable
  const GeminiResult({
    required this.text,
    this.maps = const [],
    this.web = const [],
    this.usedFallback = false,
  });
}

class TranslationResult {
  final String source;
  final String translation;
  final String pronunciation;
  final String detected;
  final String note;
  final Lang to;
  const TranslationResult({
    required this.source,
    required this.translation,
    required this.pronunciation,
    required this.detected,
    required this.note,
    required this.to,
  });
}

class ScanItem {
  final String original;
  final String translation;
  final String note;
  const ScanItem(this.original, this.translation, this.note);
}

class ScanResult {
  final String detected;
  final String summary;
  final List<ScanItem> items;
  final List<String> warnings;
  const ScanResult({
    required this.detected,
    required this.summary,
    required this.items,
    required this.warnings,
  });
}

class Phrase {
  final String meaning;
  final String local;
  final String pronunciation;
  const Phrase(this.meaning, this.local, this.pronunciation);
}

class Tip {
  final String title;
  final String detail;
  const Tip(this.title, this.detail);
}

class Primer {
  final List<Phrase> phrases;
  final List<Tip> tips;
  final String currencyName;
  final String currencyCode;
  final String currencyTip;
  const Primer({
    required this.phrases,
    required this.tips,
    required this.currencyName,
    required this.currencyCode,
    required this.currencyTip,
  });
}

class ChatTurn {
  final bool fromUser;
  final String text;
  final List<GroundingLink> sources;
  const ChatTurn(this.fromUser, this.text, {this.sources = const []});
}
