import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'ui/login_page.dart';
import 'ui/shell.dart';
import 'ui/ui_kit.dart';

final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.initFirstRunCheck();
  await ApiService.initBaseUrl();

  // Restore persisted preferences into global notifiers
  final savedName = await StorageService.getShopName();
  if (savedName != null && savedName.isNotEmpty) {
    shopNameNotifier.value = savedName;
  }
  final savedUpi = await StorageService.getUpiId();
  if (savedUpi != null && savedUpi.isNotEmpty) {
    upiIdNotifier.value = savedUpi;
  }
  final savedTheme = await StorageService.getThemeMode();
  if (savedTheme != null) {
    themeModeNotifier.value = savedTheme == 'dark'
        ? ThemeMode.dark
        : savedTheme == 'light'
            ? ThemeMode.light
            : ThemeMode.system;
  }
  final savedLang = await StorageService.getLanguage();
  if (savedLang != null && savedLang.isNotEmpty) {
    langNotifier.value = savedLang;
  }

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  ApiService.onSessionExpired = () {
    shopNameNotifier.value = '';
    upiIdNotifier.value = '';
    navKey.currentState?.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
  };
  runApp(const MunimApp());
}

class MunimApp extends StatelessWidget {
  const MunimApp({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
        valueListenable: themeModeNotifier,
        builder: (context, mode, _) => ValueListenableBuilder<String>(
          valueListenable: langNotifier,
          builder: (context, lang, _) => MaterialApp(
            key: ValueKey(lang),
            title: 'Munim Ji AI',
            debugShowCheckedModeBanner: false,
            navigatorKey: navKey,
            theme: munimTheme(),
            darkTheme: munimDarkTheme(),
            themeMode: mode,
            home: const _Gate(),
          ),
        ),
      );
}

class _Gate extends StatefulWidget {
  const _Gate();
  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  late final Future<bool> _loggedInFuture;

  @override
  void initState() {
    super.initState();
    _loggedInFuture = StorageService.isLoggedIn();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
        future: _loggedInFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snap.hasError) return const LoginPage();
          return (snap.data ?? false) ? const Shell() : const LoginPage();
        },
      );
}