import 'package:flutter/material.dart';

/// OSEE design palette from the supplied Primary, Secondary, and Tertiary swatches.
abstract final class OseePalette {
  static const primary50 = Color(0xfffbfcfd);
  static const primary100 = Color(0xffd8e1ee);
  static const primary200 = Color(0xffb4c6df);
  static const primary300 = Color(0xff90aad0);
  static const primary400 = Color(0xff6c8fc0);
  static const primary500 = Color(0xff4b74af);
  static const primary600 = Color(0xff3b5c8b);
  static const primary700 = Color(0xff2c4568);
  static const primary800 = Color(0xff1d2d44);
  static const primary900 = Color(0xff0e1520);

  static const secondary50 = Color(0xfff3f4f6);
  static const secondary100 = Color(0xffd6dae0);
  static const secondary200 = Color(0xffb9bfcb);
  static const secondary300 = Color(0xff9ca4b5);
  static const secondary400 = Color(0xff7f899f);
  static const secondary500 = Color(0xff657086);
  static const secondary600 = Color(0xff4f5769);
  static const secondary700 = Color(0xff393f4c);
  static const secondary800 = Color(0xff23272f);
  static const secondary900 = Color(0xff0d0f11);

  static const tertiary50 = Color(0xfff5f5f5);
  static const tertiary100 = Color(0xffdbdbdb);
  static const tertiary200 = Color(0xffc2c2c2);
  static const tertiary300 = Color(0xffa8a8a8);
  static const tertiary400 = Color(0xff8f8f8f);
  static const tertiary500 = Color(0xff757575);
  static const tertiary600 = Color(0xff5c5c5c);
  static const tertiary700 = Color(0xff424242);
  static const tertiary800 = Color(0xff292929);
  static const tertiary900 = Color(0xff0f0f0f);

  static const shadowSoft = Color(0x220e1520);
  static const shadowMedium = Color(0x330e1520);
  static const shadowStrong = Color(0x550e1520);
  static const shadowDeep = Color(0x660e1520);
}

const background = OseePalette.primary50;
const point = OseePalette.primary500;
const panel = OseePalette.secondary50;
const faded = OseePalette.secondary500;
const ink = OseePalette.primary900;
const imageBackground = OseePalette.tertiary50;
const line = OseePalette.secondary100;

ThemeData get oseeTheme => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: background,
  colorScheme: const ColorScheme.light(
    primary: OseePalette.primary500,
    onPrimary: OseePalette.primary50,
    primaryContainer: OseePalette.primary100,
    onPrimaryContainer: OseePalette.primary900,
    primaryFixed: OseePalette.primary100,
    primaryFixedDim: OseePalette.primary200,
    onPrimaryFixed: OseePalette.primary900,
    onPrimaryFixedVariant: OseePalette.primary700,
    secondary: OseePalette.secondary500,
    onSecondary: OseePalette.primary50,
    secondaryContainer: OseePalette.secondary100,
    onSecondaryContainer: OseePalette.secondary900,
    secondaryFixed: OseePalette.secondary100,
    secondaryFixedDim: OseePalette.secondary200,
    onSecondaryFixed: OseePalette.secondary900,
    onSecondaryFixedVariant: OseePalette.secondary700,
    tertiary: OseePalette.tertiary500,
    onTertiary: OseePalette.primary50,
    tertiaryContainer: OseePalette.tertiary100,
    onTertiaryContainer: OseePalette.tertiary900,
    tertiaryFixed: OseePalette.tertiary100,
    tertiaryFixedDim: OseePalette.tertiary200,
    onTertiaryFixed: OseePalette.tertiary900,
    onTertiaryFixedVariant: OseePalette.tertiary700,
    error: OseePalette.primary700,
    onError: OseePalette.primary50,
    errorContainer: OseePalette.primary100,
    onErrorContainer: OseePalette.primary900,
    surface: OseePalette.primary50,
    onSurface: OseePalette.primary900,
    surfaceDim: OseePalette.secondary100,
    surfaceBright: OseePalette.primary50,
    surfaceContainerLowest: OseePalette.primary50,
    surfaceContainerLow: OseePalette.secondary50,
    surfaceContainer: OseePalette.secondary50,
    surfaceContainerHigh: OseePalette.secondary100,
    outline: OseePalette.secondary300,
    outlineVariant: OseePalette.secondary100,
    surfaceContainerHighest: OseePalette.secondary50,
    onSurfaceVariant: OseePalette.secondary700,
    shadow: OseePalette.primary900,
    scrim: OseePalette.primary900,
    inverseSurface: OseePalette.primary900,
    onInverseSurface: OseePalette.primary50,
    inversePrimary: OseePalette.primary200,
    surfaceTint: OseePalette.primary500,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: background,
    foregroundColor: ink,
  ),
);
