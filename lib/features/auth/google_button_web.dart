import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

@JS('google.accounts.id.renderButton')
external void _renderButton(web.HTMLElement parent, JSObject configuration);

Widget buildGoogleButton(double width, {required VoidCallback onError}) =>
    HtmlElementView.fromTagName(
      tagName: 'div',
      onElementCreated: (element) {
        final parent = element as web.HTMLElement;
        parent.style
          ..width = '${width}px'
          ..height = '40px';
        try {
          _renderButton(
            parent,
            {
                  'type': 'standard',
                  'size': 'large',
                  'text': 'continue_with',
                  'shape': 'pill',
                  'logo_alignment': 'left',
                  'width': width,
                }.jsify()!
                as JSObject,
          );
        } catch (_) {
          scheduleMicrotask(onError);
        }
      },
    );
