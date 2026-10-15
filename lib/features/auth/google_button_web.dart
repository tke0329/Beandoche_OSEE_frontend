import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

Widget buildGoogleButton() => web.renderButton(
  configuration: web.GSIButtonConfiguration(
    size: web.GSIButtonSize.large,
    text: web.GSIButtonText.continueWith,
    shape: web.GSIButtonShape.pill,
    minimumWidth: 280,
  ),
);
