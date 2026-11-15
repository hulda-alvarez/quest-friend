import 'package:flutter/material.dart';

import '../gemini_service.dart';
import '../models.dart';
import '../speech.dart';
import '../theme.dart';
import '../utils.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _speech = SpeechController();
  final List<ChatTurn> _turns = [];

  bool _sending = false;
  String? _error;
  String _syncedKey = TripState.I.key;

  @override
  void initState() {
    super.initState();
    TripState.I.addListener(_onTrip);
  }

  void _onTrip() {
    if (_syncedKey == TripState.I.key) return;
    final countryChanged = _syncedKey.split('|').first != TripState.I.key.split('|').first;
    _syncedKey = TripState.I.key;
    // A new destination starts a fresh conversation.
    if (countryChanged) {
      setState(() {
        _turns.clear();
        _error = null;
      });
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    TripState.I.removeListener(_onTrip);
    _input.dispose();
    _scroll.dispose();
    _speech.dispose();
    super.dispose();
  }

  List<String> get _suggestions {
    final c = TripState.I.country ?? 'here';
    return [
      'What etiquette mistakes do visitors make in $c?',
      'Is tipping expected, and how much?',
      'What laws or rules might surprise a tourist?',
      'How far does my money go? Give me a feel for prices.',
      'What are the emergency numbers and how do I stay safe?',
      'How do I greet people politely?',
    ];
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _sending) return;
    FocusScope.of(context).unfocus();
    _input.clear();
    setState(() {
      _turns.add(ChatTurn(true, text));
      _sending = true;
      _error = null;
    });
    _scrollDown();
    await _ask();
  }

  Future<void> _ask() async {
    final t = TripState.I;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final r = await Gemini.I.chat(turns: _turns, country: t.country, my: t.myLang, local: t.localLang);
      if (!mounted) return;
      setState(() => _turns.add(ChatTurn(false, r.text, sources: r.web.take(4).toList())));
    } on GeminiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollDown();
    }
  }

  Future<void> _toggleMic() async {
    if (_speech.listening) {
      await _speech.stop();
      return;
    }
    await _speech.start(
      localeId: TripState.I.myLang.stt,
      onPartial: (t) {
        if (mounted) setState(() => _input.text = t);
      },
      onFinal: (t) {
        if (!mounted) return;
        setState(() => _input.text = t);
        _send();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
        child: _turns.isEmpty && !_sending ? _empty() : _list(),
      ),
      _composer(),
    ]);
  }

  Widget _empty() {
    final c = TripState.I.country;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      children: [
        const Center(child: GuidingStar(size: 44, color: QF.highlight, core: QF.background)),
        const SizedBox(height: 14),
        Text(
          c == null ? 'Ask me anything about your trip' : 'Ask me anything about $c',
          textAlign: TextAlign.center,
          style: kDisplay.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 6),
        const Text(
          'Laws, customs, money, safety and getting around. Answers use live Google Search where it matters.',
          textAlign: TextAlign.center,
          style: TextStyle(color: QF.textSecondary),
        ),
        const SizedBox(height: 20),
        Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
          for (final s in _suggestions)
            ActionChip(
              label: Text(s),
              backgroundColor: QF.surface,
              side: const BorderSide(color: QF.border),
              onPressed: () => _send(s),
            ),
        ]),
      ],
    );
  }

  Widget _list() {
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      children: [
        for (final m in _turns) _bubble(m),
        if (_sending)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Align(alignment: Alignment.centerLeft, child: StarLoader(size: 26, label: 'Thinking...')),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ErrorCard(_error!, onRetry: _turns.isNotEmpty && _turns.last.fromUser ? _ask : null),
          ),
      ],
    );
  }

  Widget _bubble(ChatTurn m) {
    if (m.fromUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: QF.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(m.text, style: const TextStyle(color: QF.background, fontSize: 15.5)),
        ),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 24),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        decoration: BoxDecoration(
          color: QF.surface,
          border: Border.all(color: QF.border),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SelectionArea(child: MarkdownLite(m.text, style: const TextStyle(fontSize: 15.5))),
          if (m.sources.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final s in m.sources)
                ActionChip(
                  visualDensity: VisualDensity.compact,
                  avatar: const Icon(Icons.link, size: 14, color: QF.primary),
                  label: Text(s.title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                  backgroundColor: QF.background,
                  side: const BorderSide(color: QF.border),
                  onPressed: () => openUrl(context, s.uri),
                ),
            ]),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Copy',
              icon: const Icon(Icons.copy_outlined, size: 16, color: QF.textSecondary),
              onPressed: () => copyText(context, m.text),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _composer() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: const BoxDecoration(
          color: QF.background,
          border: Border(top: BorderSide(color: QF.border)),
        ),
        child: ListenableBuilder(
          listenable: _speech,
          builder: (context, _) => Column(mainAxisSize: MainAxisSize.min, children: [
            if (_speech.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(_speech.error!, style: const TextStyle(color: QF.primary, fontSize: 13)),
              ),
            Row(children: [
              IconButton(
                tooltip: _speech.listening ? 'Stop' : 'Speak',
                style: IconButton.styleFrom(
                  backgroundColor: _speech.listening ? QF.highlight : Colors.transparent,
                ),
                onPressed: _toggleMic,
                icon: Icon(_speech.listening ? Icons.stop : Icons.mic_none, color: QF.primary),
              ),
              Expanded(
                child: TextField(
                  controller: _input,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: qfInput(_speech.listening ? 'Listening...' : 'Ask about local customs, laws, prices...'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _sending ? null : () => _send(),
                icon: const Icon(Icons.send),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
