import 'package:flutter/material.dart';

import '../gemini_service.dart';
import '../models.dart';
import '../setup_sheet.dart';
import '../speech.dart';
import '../theme.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int> onNavigate;
  const HomeScreen({super.key, required this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Primer? _primer;
  String? _error;
  bool _loading = false;
  String? _loadedKey;

  @override
  void initState() {
    super.initState();
    TripState.I.addListener(_maybeLoad);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoad());
  }

  @override
  void dispose() {
    TripState.I.removeListener(_maybeLoad);
    super.dispose();
  }

  Future<void> _maybeLoad({bool force = false}) async {
    final t = TripState.I;
    if (!t.isSetUp) return;
    if (!force && _loadedKey == t.key) return;
    final key = t.key;
    _loadedKey = key;
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await Gemini.I.tripPrimer(country: t.country!, my: t.myLang, local: t.localLang);
      if (!mounted || _loadedKey != key) return;
      setState(() => _primer = p);
    } on GeminiException catch (e) {
      if (mounted && _loadedKey == key) setState(() => _error = e.message);
    } catch (_) {
      if (mounted && _loadedKey == key) {
        setState(() => _error = 'Something went wrong while loading your trip guide.');
      }
    } finally {
      if (mounted && _loadedKey == key) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TripState.I,
      builder: (context, _) {
        final t = TripState.I;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            _hero(t),
            if (!Gemini.I.hasKey) ...[
              const SizedBox(height: 12),
              const ErrorCard('Add your Gemini API key to assets/app.env (GEMINI_API_KEY=...), then stop and restart the app.'),
            ],
            const SizedBox(height: 16),
            _actions(t),
            if (t.isSetUp) ..._guide(t),
          ],
        );
      },
    );
  }

  Widget _hero(TripState t) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        color: QF.primary,
        height: 200,
        child: NightScene(
          hillHeight: 64,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 230),
                child: Text(
                  t.isSetUp ? 'Your journey to ${t.country}' : 'Where to next?',
                  style: kDisplay.copyWith(fontSize: 28, color: QF.background),
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 230),
                child: Text(
                  t.isSetUp
                      ? 'Translate, find your way and ask anything about local customs.'
                      : 'Pick a destination and Quest Friend does the rest.',
                  style: const TextStyle(color: QF.highlight, height: 1.3),
                ),
              ),
              if (!t.isSetUp) ...[
                const SizedBox(height: 10),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: QF.surface, foregroundColor: QF.text),
                  onPressed: () => showSetupSheet(context),
                  child: const Text('Choose destination'),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  Widget _actions(TripState t) {
    final items = [
      (Icons.translate, 'Say it in ${t.localLang.name}', 'Type or speak, then play it aloud', 1),
      (Icons.photo_camera_outlined, 'Scan something', 'Menus, signs and labels', 2),
      (Icons.map_outlined, 'Find nearby', 'Food, transit and essentials', 3),
      (Icons.chat_bubble_outline, 'Ask Quest Friend', 'Laws, etiquette and money', 4),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        for (final a in items)
          QCard(
            onTap: () => widget.onNavigate(a.$4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Icon(a.$1, color: QF.primary),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.$2, style: const TextStyle(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(a.$3, style: const TextStyle(color: QF.textSecondary, fontSize: 12.5), maxLines: 2, overflow: TextOverflow.ellipsis),
              ]),
            ]),
          ),
      ],
    );
  }

  List<Widget> _guide(TripState t) {
    if (_loading && _primer == null) {
      return [const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: StarLoader(label: 'Preparing your guide...')))];
    }
    if (_error != null && _primer == null) {
      return [const SizedBox(height: 16), ErrorCard(_error!, onRetry: () => _maybeLoad(force: true))];
    }
    final p = _primer;
    if (p == null) return [];
    return [
      SectionTitle('Phrases for ${t.country}'),
      for (final ph in p.phrases)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: QCard(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ph.local, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  if (ph.pronunciation.isNotEmpty)
                    Text(ph.pronunciation, style: const TextStyle(color: QF.textSecondary, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 2),
                  Text(ph.meaning),
                ]),
              ),
              IconButton(
                tooltip: 'Play aloud',
                icon: const Icon(Icons.volume_up_outlined, color: QF.primary),
                onPressed: () => Speaker.I.speak(ph.local, t.localLang),
              ),
            ]),
          ),
        ),
      if (p.tips.isNotEmpty) ...[
        const SectionTitle('Good to know'),
        for (final tip in p.tips)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: QCard(
              color: QF.tint,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tip.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(tip.detail),
              ]),
            ),
          ),
      ],
      if (p.currencyName.isNotEmpty) ...[
        const SectionTitle('Money'),
        QCard(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.payments_outlined, color: QF.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${p.currencyName}${p.currencyCode.isEmpty ? '' : ' (${p.currencyCode})'}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                if (p.currencyTip.isNotEmpty) ...[const SizedBox(height: 4), Text(p.currencyTip)],
                const SizedBox(height: 8),
                TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
                  onPressed: () => widget.onNavigate(4),
                  child: const Text('Ask about current prices and rates'),
                ),
              ]),
            ),
          ]),
        ),
      ],
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _loading ? null : () => _maybeLoad(force: true),
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Refresh guide'),
        ),
      ),
    ];
  }
}
