import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'avatar_viewer.dart';
import 'avatar_stage.dart';

/// `web/viewer/avatar.html` is a plain file next to index.html, so it resolves against the base href.
Widget buildAvatarViewer(double height, AvatarModel model, int? heightMm) =>
    _WebAvatarViewer(height: height, model: model, heightMm: heightMm);

class _WebAvatarViewer extends StatefulWidget {
  const _WebAvatarViewer({
    required this.height,
    required this.model,
    this.heightMm,
  });
  final double height;
  final AvatarModel model;
  final int? heightMm;

  @override
  State<_WebAvatarViewer> createState() => _WebAvatarViewerState();
}

class _WebAvatarViewerState extends State<_WebAvatarViewer> {
  web.HTMLIFrameElement? _frame;
  late final JSFunction _listener;
  Timer? _timeout;
  int _attempt = 0;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _listener = ((web.Event raw) {
      final event = raw as web.MessageEvent;
      if (event.origin != web.window.location.origin ||
          !identical(event.source, _frame?.contentWindow)) {
        return;
      }
      try {
        final message = event.data.dartify();
        if (message is! Map || message['type'] != 'osee:avatar-viewer') return;
        if (message['state'] == 'ready') {
          _finish(false);
          _sendHeight();
        }
        if (message['state'] == 'error') _finish(true);
      } catch (_) {
        _finish(true);
      }
    }).toJS;
    web.window.addEventListener('message', _listener);
  }

  void _sendHeight() {
    _frame?.contentWindow?.postMessage(
      {'type': 'osee:avatar-config', 'heightMm': widget.heightMm}.jsify(),
      web.window.location.origin.toJS,
    );
  }

  @override
  void didUpdateWidget(covariant _WebAvatarViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_loading && !_failed && oldWidget.heightMm != widget.heightMm) {
      _sendHeight();
    }
  }

  void _finish(bool failed) {
    if (!mounted) return;
    _timeout?.cancel();
    if (failed) _frame = null;
    setState(() {
      _loading = false;
      _failed = failed;
    });
  }

  void _createFrame(Object element) {
    final frame = element as web.HTMLIFrameElement;
    _frame = frame;
    _timeout?.cancel();
    _timeout = Timer(const Duration(seconds: 30), () => _finish(true));
    frame
      ..src = 'viewer/avatar.html?model=${widget.model.id}'
      ..title = '3D 아바타 (${widget.model.label})'
      ..setAttribute('allowtransparency', 'true');
    frame.style
      ..border = 'none'
      ..width = '100%'
      ..height = '100%'
      ..backgroundColor = 'transparent';
  }

  void _retry() {
    setState(() {
      _frame = null;
      _attempt++;
      _loading = true;
      _failed = false;
    });
  }

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      if (!_failed)
        Positioned.fill(
          child: HtmlElementView.fromTagName(
            key: ValueKey(_attempt),
            tagName: 'iframe',
            onElementCreated: _createFrame,
          ),
        ),
      if (_loading)
        const Center(
          child: CircularProgressIndicator(semanticsLabel: '3D 아바타 불러오는 중'),
        ),
      if (_failed) ...[
        AvatarStage(height: widget.height),
        Positioned(
          left: 8,
          right: 8,
          bottom: 8,
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '3D 모델을 불러오지 못해 대체 이미지를 표시합니다.',
                  textAlign: TextAlign.center,
                ),
                TextButton(onPressed: _retry, child: const Text('모델 다시 불러오기')),
              ],
            ),
          ),
        ),
      ],
    ],
  );

  @override
  void dispose() {
    _timeout?.cancel();
    web.window.removeEventListener('message', _listener);
    _frame = null;
    super.dispose();
  }
}
