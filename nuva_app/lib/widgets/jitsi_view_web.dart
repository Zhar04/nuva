import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

/// Embeds a Jitsi Meet room (free, meet.jit.si) as an in-app iframe on web.
class JitsiView extends StatefulWidget {
  final String url;
  const JitsiView({super.key, required this.url});

  @override
  State<JitsiView> createState() => _JitsiViewState();
}

class _JitsiViewState extends State<JitsiView> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'jitsi-${identityHashCode(this)}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
      final el = html.IFrameElement()
        ..src = widget.url
        ..allow =
            'camera; microphone; fullscreen; display-capture; autoplay; clipboard-write'
        ..allowFullscreen = true
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
      return el;
    });
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _viewType);
}
