import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'nav.dart';
import 'screens/intro.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  runApp(const AgoraApp());
}

class AgoraApp extends StatelessWidget {
  const AgoraApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Agora',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        navigatorKey: navKey,
        scaffoldMessengerKey: messengerKey,
        home: const SplashScreen(),
      );
}
