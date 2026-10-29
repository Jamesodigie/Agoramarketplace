import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'links.dart';
import 'nav.dart';
import 'screens/delivery_ui.dart';
import 'screens/intro.dart';
import 'screens/seller.dart';
import 'screens/shop.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Clean web addresses (agoramarket.ng/storebyella, not agoramarket.ng/#/storebyella).
  if (kIsWeb) usePathUrlStrategy();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  runApp(const AgoraApp());
}

/// Builds the page for a link. "/" is the normal app start;
/// "/<handle>" opens that store, from the web or from an app link on the phone.
Route<dynamic> routeFor(String? name, {bool initial = false}) {
  if (Uri.tryParse(name ?? '')?.path == '/admin') {
    return initial ? fadeRoute(const AdminScreen(entry: true)) : softRoute(const AdminScreen());
  }
  final handle = handleFromPath(name);
  if (handle == null) {
    return initial ? fadeRoute(const SplashScreen()) : softRoute(const HomeScreen());
  }
  final store = storeByHandle(handle);
  final page = store == null ? StoreNotFoundScreen(handle) : StoreScreen(store, entry: true);
  return initial ? fadeRoute(page) : softRoute(page);
}

class AgoraApp extends StatelessWidget {
  const AgoraApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Agora Marketplace',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        navigatorKey: navKey,
        scaffoldMessengerKey: messengerKey,
        onGenerateInitialRoutes: (name) => [routeFor(name, initial: true)],
        onGenerateRoute: (settings) => routeFor(settings.name),
      );
}
