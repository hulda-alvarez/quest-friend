import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../gemini_service.dart';
import '../models.dart';
import '../theme.dart';
import '../utils.dart';

class _Category {
  final IconData icon;
  final String label;
  final String query;
  final bool guide; // true = general explainer (Search grounding) instead of places
  const _Category(this.icon, this.label, this.query, {this.guide = false});
}

const _categories = [
  _Category(Icons.restaurant_outlined, 'Restaurants', 'good local restaurants'),
  _Category(Icons.directions_subway_outlined, 'Public transit', 'nearest metro, train or bus stops'),
  _Category(Icons.storefront_outlined, 'Convenience stores', 'convenience stores'),
  _Category(Icons.local_pharmacy_outlined, 'Pharmacies', 'pharmacies'),
  _Category(Icons.atm_outlined, 'ATMs', 'ATMs and currency exchange'),
  _Category(Icons.wc_outlined, 'Restrooms', 'public restrooms'),
  _Category(Icons.account_balance_outlined, 'Landmarks', 'must-see landmarks and attractions'),
  _Category(Icons.confirmation_number_outlined, 'How transit works', '', guide: true),
];

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _place = TextEditingController();
  final _search = TextEditingController();

  double? _lat;
  double? _lng;
  String? _locStatus;
  bool _locating = false;

  GeminiResult? _result;
  String _lastQuery = '';
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _place.dispose();
    _search.dispose();
    super.dispose();
  }

  bool get _hasLocation => (_lat != null && _lng != null) || _place.text.trim().isNotEmpty;

  Future<void> _useMyLocation() async {
    if (_locating) return;
    setState(() {
      _locating = true;
      _locStatus = null;
    });
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _locStatus = 'Location is turned off on this device. Type where you are instead.';
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        _locStatus = 'Location permission was not granted. Type where you are instead.';
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      _lat = pos.latitude;
      _lng = pos.longitude;
      _locStatus = 'Using your current location';
    } catch (_) {
      _locStatus = 'Could not get your location. Type where you are instead.';
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _run(String label, String query, {bool guide = false}) async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    final t = TripState.I;

    if (!guide && !_hasLocation) {
      await _useMyLocation();
      if (!_hasLocation) {
        if (mounted) showSnack(context, 'Share your location or type where you are first.');
        return;
      }
    }

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
      _lastQuery = label;
    });
    try {
      final GeminiResult r;
      if (guide) {
        r = await Gemini.I.chat(
          turns: [
            ChatTurn(
              true,
              'Explain how public transit works in ${t.country ?? 'this country'} for a first-time visitor: how to pay or buy tickets, passes or cards worth getting, etiquette on board, and common mistakes. Keep it practical.',
            ),
          ],
          country: t.country,
          my: t.myLang,
          local: t.localLang,
        );
      } else {
        r = await Gemini.I.nearby(
          query: query,
          lat: _lat,
          lng: _lng,
          placeText: _place.text.trim(),
          country: t.country,
          my: t.myLang,
          local: t.localLang,
        );
      }
      if (mounted) setState(() => _result = r);
    } on GeminiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = TripState.I;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        QCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(_lat != null ? Icons.my_location : Icons.location_searching, color: QF.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _lat != null ? 'Using your current location' : 'Where are you?',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: _locating ? null : _useMyLocation,
                child: Text(_locating ? 'Locating...' : (_lat != null ? 'Update' : 'Use my location')),
              ),
            ]),
            const SizedBox(height: 8),
            TextField(
              controller: _place,
              onChanged: (_) => setState(() {}),
              decoration: qfInput('Or type a city, area or landmark').copyWith(fillColor: QF.background),
            ),
            if (_locStatus != null && _lat == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_locStatus!, style: const TextStyle(color: QF.textSecondary, fontSize: 13)),
              ),
          ]),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _search,
          textInputAction: TextInputAction.search,
          onSubmitted: (v) => v.trim().isEmpty ? null : _run(v.trim(), v.trim()),
          decoration: qfInput(
            'Search nearby (ramen, post office, ...)',
            suffix: IconButton(
              icon: const Icon(Icons.search, color: QF.primary),
              onPressed: () {
                final v = _search.text.trim();
                if (v.isNotEmpty) _run(v, v);
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final c in _categories)
            ActionChip(
              avatar: Icon(c.icon, size: 18, color: QF.primary),
              label: Text(c.label),
              backgroundColor: QF.surface,
              side: const BorderSide(color: QF.border),
              onPressed: _loading ? null : () => _run(c.label, c.query, guide: c.guide),
            ),
        ]),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: StarLoader(label: 'Finding your way...')),
          ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          ErrorCard(_error!),
        ],
        if (_result != null && !_loading) ..._resultWidgets(_result!, t),
        if (_result == null && !_loading && _error == null)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Column(children: [
              GuidingStar(size: 40, color: QF.highlight, core: QF.background),
              SizedBox(height: 12),
              Text('Pick a category or search for what you need.',
                  textAlign: TextAlign.center, style: TextStyle(color: QF.textSecondary)),
            ]),
          ),
      ],
    );
  }

  List<Widget> _resultWidgets(GeminiResult r, TripState t) {
    final isGuide = r.maps.isEmpty && r.web.isNotEmpty;
    return [
      const SizedBox(height: 16),
      if (r.usedFallback)
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: ErrorCard('Live map data is not available right now, so these are general suggestions. Use the button below to search Google Maps directly.'),
        ),
      QCard(child: MarkdownLite(r.text)),
      if (r.maps.isNotEmpty) ...[
        const SectionTitle('On the map'),
        for (final p in r.maps.take(6))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: QCard(
              color: QF.tint,
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.place_outlined, color: QF.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(p.title, style: const TextStyle(fontWeight: FontWeight.w700))),
                ]),
                Row(children: [
                  TextButton.icon(
                    onPressed: () => openUrl(context, mapsDirectionsUrl(p.title, placeId: p.placeId)),
                    icon: const Icon(Icons.directions_walk, size: 18),
                    label: const Text('Directions'),
                  ),
                  TextButton.icon(
                    onPressed: () => openUrl(context, p.uri),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Open in Maps'),
                  ),
                ]),
              ]),
            ),
          ),
        const Padding(
          padding: EdgeInsets.only(top: 2, bottom: 4),
          child: Text('Place data from Google Maps', style: TextStyle(color: QF.textSecondary, fontSize: 12)),
        ),
      ],
      if (isGuide) ...[
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final w in r.web.take(4))
            ActionChip(
              avatar: const Icon(Icons.link, size: 16, color: QF.primary),
              label: Text(w.title, overflow: TextOverflow.ellipsis),
              backgroundColor: QF.surface,
              side: const BorderSide(color: QF.border),
              onPressed: () => openUrl(context, w.uri),
            ),
        ]),
      ],
      if (!isGuide && _lastQuery.isNotEmpty) ...[
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => openUrl(
            context,
            mapsSearchUrl(
              _place.text.trim().isNotEmpty && _lat == null ? '$_lastQuery near ${_place.text.trim()}' : _lastQuery,
              lat: _lat,
              lng: _lng,
            ),
          ),
          icon: const Icon(Icons.map_outlined),
          label: Text('Search "$_lastQuery" in Google Maps'),
        ),
      ],
    ];
  }
}
