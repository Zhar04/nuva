import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/backend_auth.dart';
import '../widgets/jitsi_view.dart';

/// Free video call via a public Jitsi Meet instance — embedded in-app on web,
/// no infrastructure, no keys. Both participants of a conversation join the
/// same room (derived from [roomSeed], e.g. the conversation id).
///
/// NB: `meet.jit.si` now gates anonymous rooms behind a "moderator must log in"
/// screen, so we default to an open community instance. Override with
/// `JITSI_DOMAIN` in `.env` (and ideally self-host later for privacy — this
/// carries mental-health conversations).
class VideoCallScreen extends ConsumerWidget {
  final String roomSeed;
  const VideoCallScreen({super.key, required this.roomSeed});

  static String get _domain {
    final v = dotenv.env['JITSI_DOMAIN']?.trim();
    return (v != null && v.isNotEmpty) ? v : 'meet.ffmuc.net';
  }

  // Toolbar trimmed to what a therapy session needs (no invite/recording/etc).
  static const _toolbar =
      '["microphone","camera","tileview","chat","raisehand","hangup","fullscreen","settings"]';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.read(backendAuthProvider).user?.name.trim() ?? '';
    final display = name.isEmpty ? 'Гость' : name;
    final room = 'nuva${roomSeed.replaceAll(RegExp(r'[^A-Za-z0-9]'), '')}';
    // Free customizations that the public config whitelist still honours in
    // 2026: display name, no deep-link nag, a calm prejoin (mic/cam check —
    // good before a session), hidden invite, a trimmed toolbar and a dark teal
    // background. NB: removing the Jitsi watermark / recolouring the UI needs a
    // self-host or JaaS — see docs/VIDEO_CALL.md.
    final url = 'https://$_domain/$room'
        '#userInfo.displayName=${Uri.encodeComponent('"$display"')}'
        '&config.disableDeepLinking=true'
        '&config.prejoinConfig.enabled=true'
        '&config.disableInviteFunctions=true'
        '&config.toolbarButtons=${Uri.encodeComponent(_toolbar)}'
        '&interfaceConfig.DEFAULT_BACKGROUND=${Uri.encodeComponent("#0B1F2A")}'
        '&interfaceConfig.DISABLE_VIDEO_BACKGROUND=true'
        '&interfaceConfig.MOBILE_APP_PROMO=false'
        '&interfaceConfig.SHOW_JITSI_WATERMARK=false';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 2),
                  const Text('Видеосессия Nuva',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_rounded,
                            color: Colors.white70, size: 12),
                        SizedBox(width: 5),
                        Text('Зашифровано',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: JitsiView(url: url)),
          ],
        ),
      ),
    );
  }
}
