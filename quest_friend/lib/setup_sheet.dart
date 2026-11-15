import 'package:flutter/material.dart';

import 'models.dart';
import 'theme.dart';

// ---------------------------------------------------------------------------
// Trip setup sheet: destination + languages
// ---------------------------------------------------------------------------

Future<void> showSetupSheet(BuildContext context) {
  final locked = !TripState.I.isSetUp;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: !locked,
    enableDrag: !locked,
    backgroundColor: QF.background,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const _SetupSheet(),
  );
}

class _SetupSheet extends StatefulWidget {
  const _SetupSheet();

  @override
  State<_SetupSheet> createState() => _SetupSheetState();
}

class _SetupSheetState extends State<_SetupSheet> {
  final _country = TextEditingController(text: TripState.I.country ?? '');
  Lang _my = TripState.I.myLang;
  Lang _local = TripState.I.localLang;

  @override
  void dispose() {
    _country.dispose();
    super.dispose();
  }

  void _pick(Destination d) {
    setState(() {
      _country.text = d.country;
      _local = langByName(d.language);
    });
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _country.text.trim().isNotEmpty;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('Where are you headed?', style: kDisplay.copyWith(fontSize: 24)),
          const SizedBox(height: 6),
          const Text('Quest Friend tailors translations, tips and places to your destination.',
              style: TextStyle(color: QF.textSecondary)),
          const SizedBox(height: 16),
          TextField(
            controller: _country,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.words,
            decoration: qfInput('Country'),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final d in kDestinations)
              ActionChip(
                label: Text(d.country),
                backgroundColor: _country.text.trim() == d.country ? QF.tint : QF.surface,
                side: const BorderSide(color: QF.border),
                onPressed: () => _pick(d),
              ),
          ]),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('I speak', style: TextStyle(color: QF.textSecondary)),
                const SizedBox(height: 6),
                LangPicker(value: _my, onChanged: (l) => setState(() => _my = l ?? _my)),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Locals speak', style: TextStyle(color: QF.textSecondary)),
                const SizedBox(height: 6),
                LangPicker(value: _local, onChanged: (l) => setState(() => _local = l ?? _local)),
              ]),
            ),
          ]),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: canSave
                  ? () {
                      TripState.I.configure(country: _country.text, my: _my, local: _local);
                      Navigator.of(context).pop();
                    }
                  : null,
              child: const Text('Start exploring'),
            ),
          ),
        ]),
      ),
    );
  }
}
