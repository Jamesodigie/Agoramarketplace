import 'package:flutter/material.dart';

final navKey = GlobalKey<NavigatorState>();
final messengerKey = GlobalKey<ScaffoldMessengerState>();

NavigatorState get _nav => navKey.currentState!;

Route<T> softRoute<T>(Widget page) => MaterialPageRoute<T>(builder: (_) => page);

Route<T> fadeRoute<T>(Widget page, {int ms = 450}) => PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: Duration(milliseconds: ms),
      reverseTransitionDuration: Duration(milliseconds: ms),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: CurvedAnimation(parent: a, curve: Curves.easeOut), child: child),
    );

Future<T?> go<T>(Widget page) => _nav.push<T>(softRoute<T>(page));
void goReplace(Widget page) => _nav.pushReplacement(softRoute(page));
void goReset(Widget page) => _nav.pushAndRemoveUntil(softRoute(page), (_) => false);
void goResetFade(Widget page) => _nav.pushAndRemoveUntil(fadeRoute(page, ms: 250), (_) => false);
void back<T>([T? result]) => _nav.maybePop<T>(result);
