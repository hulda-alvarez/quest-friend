import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'theme.dart';

Future<void> openUrl(BuildContext context, String url) async {
  bool ok = false;
  try {
    ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {}
  if (!ok && context.mounted) showSnack(context, 'Could not open that link.');
}

void showSnack(BuildContext context, String message) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Text(message, style: const TextStyle(color: QF.background)),
    behavior: SnackBarBehavior.floating,
    backgroundColor: QF.text,
  ));
}

Future<void> copyText(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) showSnack(context, 'Copied');
}

/// Google Maps deep links: no Maps SDK or Maps API key needed.
String mapsSearchUrl(String query, {double? lat, double? lng}) {
  final q = (lat != null && lng != null) ? '$query near $lat,$lng' : query;
  return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(q)}';
}

String mapsDirectionsUrl(String destination, {String? placeId, String mode = 'walking'}) {
  final pid = (placeId != null && placeId.isNotEmpty) ? '&destination_place_id=$placeId' : '';
  return 'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(destination)}$pid&travelmode=$mode';
}
