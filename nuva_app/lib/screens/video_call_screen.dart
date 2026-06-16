import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/backend_auth.dart';
import '../widgets/jitsi_view.dart';

/// Free video call via Jitsi Meet (meet.jit.si) — embedded in-app on web,
/// no infrastructure, no keys. Both participants of a conversation join the
/// same room (derived from [roomSeed], e.g. the conversation id).
class VideoCallScreen extends ConsumerWidget {
  final String roomSeed;
  const VideoCallScreen({super.key, required this.roomSeed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.read(backendAuthProvider).user?.name.trim() ?? '';
    final display = name.isEmpty ? 'Гость' : name;
    final room = 'nuva${roomSeed.replaceAll(RegExp(r'[^A-Za-z0-9]'), '')}';
    final url = 'https://meet.jit.si/$room'
        '#userInfo.displayName=${Uri.encodeComponent('"$display"')}'
        '&config.disableDeepLinking=true'
        '&config.prejoinPageEnabled=true'
        '&interfaceConfig.MOBILE_APP_PROMO=false';

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
