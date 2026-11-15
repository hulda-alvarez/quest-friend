import 'package:flutter/material.dart';

import '../gemini_service.dart';
import '../models.dart';
import '../speech.dart';
import '../theme.dart';
import '../utils.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  final _input = TextEditingController();
  final _speech = SpeechController();
  final List<TranslationResult> _history = [];

  Lang? _from = TripState.I.myLang;
  Lang _to = TripState.I.localLang;
  TranslationResult? _result;
  bool _loading = false;
  String? _error;
  String _syncedKey = TripState.I.key;

  @override
  void initState() {
    super.initState();
    TripState.I.addListener(_onTrip);
  }

  void _onTrip() {
    // When the trip languages change in setup, reset the pair.
    if (_syncedKey == TripState.I.key) return;
    _syncedKey = TripState.I.key;
    setState(() {
      _from = TripState.I.myLang;
      _to = TripState.I.localLang;
      _result = null;
    });
  }

  @override
  void dispose() {
    TripState.I.removeListener(_onTrip);
    _input.dispose();
    _speech.dispose();
    super.dispose();
  }

  void _swap() {
    if (_from == null) return;
    setState(() {
      final f = _from!;
      _from = _to;
      _to = f;
      _input.clear();
      _result = null;
      _error = null;
    });
  }

  Future<void> _translate() async {
    final text = _input.text.trim();
    if (text.isEmpty || _loading) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await Gemini.I.translateText(text: text, from: _from, to: _to);
      if (!mounted) return;
      setState(() {
        _result = r;
        _history.insert(0, r);
        if (_history.length > 8) _history.removeLast();
      });
    } on GeminiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Translation failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleMic() async {
    if (_speech.listening) {
      await _speech.stop();
      return;
    }
    await _speech.start(
      localeId: _from?.stt,
      onPartial: (t) {
        if (mounted) setState(() => _input.text = t);
      },
      onFinal: (t) {
        if (!mounted) return;
        setState(() => _input.text = t);
        _translate();
      },
    );
  }

  void _showLarge(String text) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Show to someone')),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Text(text, textAlign: TextAlign.center, style: kDisplay.copyWith(fontSize: 44)),
            ),
          ),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(children: [
          Expanded(child: LangPicker(value: _from, allowAuto: true, onChanged: (l) => setState(() => _from = l))),
          IconButton(
            tooltip: 'Swap languages',
            onPressed: _from == null ? null : _swap,
            icon: const Icon(Icons.swap_horiz, color: QF.primary),
          ),
          Expanded(child: LangPicker(value: _to, onChanged: (l) => setState(() => _to = l ?? _to))),
        ]),
        const SizedBox(height: 14),
        ListenableBuilder(
          listenable: _speech,
          builder: (context, _) => QCard(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextField(
                controller: _input,
                onChanged: (_) => setState(() {}),
                minLines: 3,
                maxLines: 6,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: _speech.listening
                      ? 'Listening... speak in ${_from?.name ?? 'your language'}'
                      : 'Type something, or tap the mic and speak',
                  hintStyle: const TextStyle(color: QF.textSecondary),
                ),
              ),
              Row(children: [
                IconButton.filled(
                  tooltip: _speech.listening ? 'Stop' : 'Speak',
                  style: IconButton.styleFrom(
                    backgroundColor: _speech.listening ? QF.highlight : QF.primary,
                    foregroundColor: _speech.listening ? QF.primary : QF.background,
                  ),
                  onPressed: _toggleMic,
                  icon: Icon(_speech.listening ? Icons.stop : Icons.mic),
                ),
                if (_input.text.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear',
                    onPressed: () => setState(() {
                      _input.clear();
                      _result = null;
                    }),
                    icon: const Icon(Icons.close, color: QF.textSecondary),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: _loading ? null : _translate,
                  child: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: QF.primary))
                      : const Text('Translate'),
                ),
              ]),
              if (_speech.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_speech.error!, style: const TextStyle(color: QF.primary)),
                ),
            ]),
          ),
        ),
        if (_error != null) ...[const SizedBox(height: 12), ErrorCard(_error!, onRetry: _translate)],
        if (_result != null) ...[const SizedBox(height: 14), _resultCard(_result!)],
        if (_history.length > 1) ...[
          const SectionTitle('Recent'),
          for (final h in _history.skip(1))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: QCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                onTap: () => setState(() {
                  _result = h;
                  _input.text = h.source;
                  _to = h.to;
                }),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(h.source, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: QF.textSecondary)),
                  const SizedBox(height: 2),
                  Text(h.translation, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
        ],
        if (_result == null && _history.isEmpty && !_loading)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Column(children: [
              GuidingStar(size: 40, color: QF.highlight, core: QF.background),
              SizedBox(height: 12),
              Text('Say it your way and Quest Friend finds the words.',
                  textAlign: TextAlign.center, style: TextStyle(color: QF.textSecondary)),
            ]),
          ),
      ],
    );
  }

  Widget _resultCard(TranslationResult r) {
    return QCard(
      color: QF.tint,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (r.detected.isNotEmpty)
          Text('From ${r.detected} to ${r.to.name}', style: const TextStyle(color: QF.textSecondary, fontSize: 13)),
        const SizedBox(height: 6),
        SelectableText(r.translation, style: kDisplay.copyWith(fontSize: 26)),
        if (r.pronunciation.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(r.pronunciation, style: const TextStyle(color: QF.textSecondary, fontStyle: FontStyle.italic, fontSize: 16)),
        ],
        if (r.note.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: QF.background, borderRadius: BorderRadius.circular(12)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.lightbulb_outline, size: 18, color: QF.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(r.note, style: const TextStyle(fontSize: 14))),
            ]),
          ),
        ],
        const SizedBox(height: 8),
        Wrap(spacing: 4, children: [
          TextButton.icon(
            onPressed: () => Speaker.I.speak(r.translation, r.to),
            icon: const Icon(Icons.volume_up_outlined, size: 18),
            label: const Text('Play'),
          ),
          TextButton.icon(
            onPressed: () => _showLarge(r.translation),
            icon: const Icon(Icons.fullscreen, size: 18),
            label: const Text('Show'),
          ),
          TextButton.icon(
            onPressed: () => copyText(context, r.translation),
            icon: const Icon(Icons.copy_outlined, size: 18),
            label: const Text('Copy'),
          ),
        ]),
      ]),
    );
  }
}
