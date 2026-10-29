import 'package:flutter/material.dart';

/// Agora colours. Blue comes from the Figma file, brand blue from the logo.
class C {
  static const blue = Color(0xFF005AE6);
  static const brand = Color(0xFF0060FD);
  static const blue600 = Color(0xFF004CC4);
  static const blue50 = Color(0xFFEAF1FF);
  static const blue100 = Color(0xFFD6E4FF);
  static const navy = Color(0xFF0B1530);
  static const ink = Color(0xFF0F1729);
  static const muted = Color(0xFF6B7280);
  static const faint = Color(0xFF9AA3B2);
  static const bg = Color(0xFFF4F6FA);
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFE7EBF2);
  static const green = Color(0xFF22C55E);
  static const greenInk = Color(0xFF15803D);
  static const green50 = Color(0xFFE7F7ED);
  static const amber = Color(0xFFF59E0B);
  static const amberInk = Color(0xFFB45309);
  static const amber50 = Color(0xFFFEF5DF);
  static const red = Color(0xFFEF4444);
  static const red50 = Color(0xFFFDECEC);
  static const light = Color(0xFFEAF1FF);
}

const kFont = 'Inter';

/// Soft, springy motion used everywhere.
const kSpring = Curves.easeOutBack;
const kEase = Curves.easeOutCubic;

const List<BoxShadow> kShadow1 = [
  BoxShadow(color: Color(0x0A101828), blurRadius: 2, offset: Offset(0, 1)),
  BoxShadow(color: Color(0x0D101828), blurRadius: 18, offset: Offset(0, 6)),
];
const List<BoxShadow> kShadow2 = [
  BoxShadow(color: Color(0x0F101828), blurRadius: 6, offset: Offset(0, 2)),
  BoxShadow(color: Color(0x1A101828), blurRadius: 40, offset: Offset(0, 18)),
];

TextStyle ts(double size, {FontWeight w = FontWeight.w400, Color? c, double? h, double? ls}) =>
    TextStyle(fontFamily: kFont, fontSize: size, fontWeight: w, color: c ?? C.ink, height: h, letterSpacing: ls);

const w5 = FontWeight.w500;
const w6 = FontWeight.w600;
const w7 = FontWeight.w700;

class SoftPageTransitions extends PageTransitionsBuilder {
  const SoftPageTransitions();
  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    final inC = CurvedAnimation(parent: animation, curve: kEase, reverseCurve: Curves.easeInCubic);
    final outC = CurvedAnimation(parent: secondaryAnimation, curve: kEase);
    return FadeTransition(
      opacity: inC,
      child: SlideTransition(
        position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(inC),
        child: SlideTransition(
          position: Tween(begin: Offset.zero, end: const Offset(-0.05, 0)).animate(outC),
          child: child,
        ),
      ),
    );
  }
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: kFont,
    scaffoldBackgroundColor: C.bg,
    colorScheme: ColorScheme.fromSeed(seedColor: C.blue, primary: C.blue, surface: C.bg),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: SoftPageTransitions(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: SoftPageTransitions(),
      TargetPlatform.linux: SoftPageTransitions(),
      TargetPlatform.fuchsia: SoftPageTransitions(),
    }),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: C.blue),
  );
  return base.copyWith(textTheme: base.textTheme.apply(fontFamily: kFont, bodyColor: C.ink, displayColor: C.ink));
}
