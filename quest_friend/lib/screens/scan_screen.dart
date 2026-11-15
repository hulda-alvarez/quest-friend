import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../gemini_service.dart';
import '../models.dart';
import '../theme.dart';
import '../utils.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _picker = ImagePicker();
  final _question = TextEditingController();

  Uint8List? _bytes;
  String _mime = 'image/jpeg';
  Lang _to = TripState.I.myLang;
  ScanResult? _result;
  bool _loading = false;
  String? _error;
  String? _answer;
  bool _asking = false;
  String _syncedKey = TripState.I.key;

  @override
  void initState() {
    super.initState();
    TripState.I.addListener(_onTrip);
  }

  void _onTrip() {
    if (_syncedKey == TripState.I.key) return;
    _syncedKey = TripState.I.key;
    setState(() => _to = TripState.I.myLang);
  }

  @override
  void dispose() {
    TripState.I.removeListener(_onTrip);
    _question.dispose();
    super.dispose();
  }

  String _mimeOf(XFile f) {
    final m = f.mimeType;
    if (m != null && m.startsWith('image/')) return m;
    final n = f.name.toLowerCase();
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.webp')) return 'image/webp';
    if (n.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final f = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
      if (f == null) return;
      final bytes = await f.readAsBytes();
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _mime = _mimeOf(f);
        _result = null;
        _answer = null;
        _error = null;
      });
      await _analyze();
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Could not open the camera or photo library. Check the permission, or use Upload instead.');
      }
    }
  }

  Future<void> _analyze() async {
    final bytes = _bytes;
    if (bytes == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _answer = null;
    });
    try {
      final r = await Gemini.I.analyzeImage(
        bytes: bytes,
        mime: _mime,
        to: _to,
        country: TripState.I.country,
      );
      if (mounted) setState(() => _result = r);
    } on GeminiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not read that image. Try a clearer photo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _ask() async {
    final q = _question.text.trim();
    final bytes = _bytes;
    if (q.isEmpty || bytes == null || _asking) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _asking = true;
      _answer = null;
    });
    try {
      final a = await Gemini.I.askAboutImage(
        bytes: bytes,
        mime: _mime,
        question: q,
        to: _to,
        country: TripState.I.country,
      );
      if (mounted) setState(() => _answer = a);
    } on GeminiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _asking = false);
    }
  }

  String _allText(ScanResult r) {
    final b = StringBuffer(r.summary);
    for (final i in r.items) {
      b.writeln();
      b.write('${i.original} - ${i.translation}');
      if (i.note.isNotEmpty) b.write(' (${i.note})');
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(children: [
          const Text('Translate into', style: TextStyle(color: QF.textSecondary)),
          const SizedBox(width: 12),
          Expanded(
            child: LangPicker(
              value: _to,
              onChanged: (l) {
                setState(() => _to = l ?? _to);
                if (_bytes != null) _analyze();
              },
            ),
          ),
        ]),
        const SizedBox(height: 12),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: _loading ? null : () => _pick(ImageSource.camera),
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Take photo'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _loading ? null : () => _pick(ImageSource.gallery),
              icon: const Icon(Icons.upload_outlined),
              label: const Text('Upload'),
            ),
          ),
        ]),
        if (_bytes == null && !_loading)
          const Padding(
            padding: EdgeInsets.only(top: 48),
            child: Column(children: [
              GuidingStar(size: 40, color: QF.highlight, core: QF.background),
              SizedBox(height: 12),
              Text('Point at the text and Quest Friend will read it for you.',
                  textAlign: TextAlign.center, style: TextStyle(color: QF.textSecondary)),
            ]),
          ),
        if (_bytes != null) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.memory(_bytes!, height: 200, width: double.infinity, fit: BoxFit.cover),
          ),
        ],
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: StarLoader(label: 'Reading the text...')),
          ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          ErrorCard(_error!, onRetry: _bytes == null ? null : _analyze),
        ],
        if (_result != null && !_loading) ..._resultWidgets(_result!),
      ],
    );
  }

  List<Widget> _resultWidgets(ScanResult r) {
    return [
      const SizedBox(height: 14),
      QCard(
        color: QF.tint,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (r.detected.isNotEmpty)
            Text('Detected: ${r.detected}', style: const TextStyle(color: QF.textSecondary, fontSize: 13)),
          if (r.summary.isNotEmpty) ...[
            const SizedBox(height: 6),
            MarkdownLite(r.summary),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => copyText(context, _allText(r)),
              icon: const Icon(Icons.copy_outlined, size: 18),
              label: const Text('Copy all'),
            ),
          ),
        ]),
      ),
      if (r.warnings.isNotEmpty) ...[
        const SizedBox(height: 10),
        QCard(
          color: QF.highlight,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.warning_amber_rounded, color: QF.primary),
              SizedBox(width: 8),
              Text('Heads up', style: TextStyle(fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 6),
            for (final w in r.warnings)
              Padding(padding: const EdgeInsets.only(top: 2), child: Text('\u2022  $w')),
          ]),
        ),
      ],
      if (r.items.isNotEmpty) ...[
        const SectionTitle('Line by line'),
        for (final i in r.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: QCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(i.original, style: const TextStyle(color: QF.textSecondary)),
                const SizedBox(height: 2),
                Text(i.translation, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                if (i.note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(i.note, style: const TextStyle(fontSize: 14)),
                ],
              ]),
            ),
          ),
      ],
      const SectionTitle('Ask about this photo'),
      Row(children: [
        Expanded(
          child: TextField(
            controller: _question,
            onSubmitted: (_) => _ask(),
            decoration: qfInput('Is this vegetarian? Can I go in?'),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: _asking ? null : _ask,
          icon: _asking
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: QF.background))
              : const Icon(Icons.send),
        ),
      ]),
      if (_answer != null) ...[
        const SizedBox(height: 12),
        QCard(child: MarkdownLite(_answer!)),
      ],
    ];
  }
}
