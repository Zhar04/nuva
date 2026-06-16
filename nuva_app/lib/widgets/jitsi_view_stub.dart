import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Non-web fallback: open the Jitsi room in the browser / Jitsi app.
class JitsiView extends StatelessWidget {
  final String url;
  const JitsiView({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () =>
            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        icon: const Icon(Icons.videocam_rounded),
        label: const Text('Открыть видеозвонок'),
      ),
    );
  }
}
