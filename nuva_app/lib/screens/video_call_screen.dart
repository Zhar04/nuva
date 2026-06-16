import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/backend_auth.dart';

/// Free video call via a public Jitsi Meet instance. Both participants of a
/// conversation join the same room (derived from [roomSeed]).
///
/// NB: public instances now BLOCK iframe embedding (`meet.ffmuc.net` sends
/// X-Frame-Options/CSP since 2026-03-19, `meet.jit.si` caps embedded calls at
/// 5 min), so we no longer embed — we open the room in a new tab/window where
/// Jitsi works normally. Override the instance with `JITSI_DOMAIN` in `.env`.
/// For a fully in-app, branded call, self-host Jitsi or use JaaS — see
/// docs/VIDEO_CALL.md.
class VideoCallScreen extends ConsumerWidget {
  final String roomSeed;
  const VideoCallScreen({super.key, required this.roomSeed});

  static String get _domain {
    final v = dotenv.env['JITSI_DOMAIN']?.trim();
    return (v != null && v.isNotEmpty) ? v : 'meet.ffmuc.net';
  }

  // Trimmed to what a therapy session needs; applied via the URL hash.
  static const _toolbar =
      '["microphone","camera","tileview","chat","raisehand","hangup","fullscreen","settings"]';

  String _roomUrl(String display) {
    final room = 'nuva${roomSeed.replaceAll(RegExp(r'[^A-Za-z0-9]'), '')}';
    return 'https://$_domain/$room'
        '#userInfo.displayName=${Uri.encodeComponent('"$display"')}'
        '&config.disableDeepLinking=true'
        '&config.prejoinConfig.enabled=true'
        '&config.disableInviteFunctions=true'
        '&config.toolbarButtons=${Uri.encodeComponent(_toolbar)}'
        '&interfaceConfig.DEFAULT_BACKGROUND=${Uri.encodeComponent("#0B1F2A")}'
        '&interfaceConfig.MOBILE_APP_PROMO=false';
  }

  Future<void> _open(BuildContext context, String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть видеозвонок')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.read(backendAuthProvider).user?.name.trim() ?? '';
    final display = name.isEmpty ? 'Гость' : name;
    final url = _roomUrl(display);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1F2A),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_rounded, color: Colors.white70, size: 12),
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
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF5AA6E8), Color(0xFF3DD4C0)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3DD4C0)
                                  .withValues(alpha: 0.4),
                              blurRadius: 28,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.videocam_rounded,
                            color: Colors.white, size: 46),
                      ),
                      const SizedBox(height: 24),
                      const Text('Видеосессия готова',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4)),
                      const SizedBox(height: 10),
                      const Text(
                        'Защищённая комната откроется в новой вкладке. '
                        'Дайте доступ к камере и микрофону, когда браузер '
                        'попросит.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                            height: 1.5),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () => _open(context, url),
                          icon: const Icon(Icons.open_in_new_rounded, size: 20),
                          label: const Text('Войти в видеозвонок'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5AA6E8),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            textStyle: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              color: Colors.white38, size: 14),
                          const SizedBox(width: 6),
                          Text('Сервер: $_domain',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 11.5)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
