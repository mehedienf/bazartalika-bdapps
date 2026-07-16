import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './screens/home_screen.dart';
import './screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // MobileAds.instance.initialize();
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('bazar_is_dark_mode') ?? false;
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  runApp(BazarTalikaApp(initialDarkMode: isDarkMode, isLoggedIn: isLoggedIn));
}

class BazarTalikaApp extends StatefulWidget {
  final bool initialDarkMode;
  final bool isLoggedIn;

  const BazarTalikaApp({super.key, required this.initialDarkMode, required this.isLoggedIn});

  @override
  State<BazarTalikaApp> createState() => _BazarTalikaAppState();
}

class _BazarTalikaAppState extends State<BazarTalikaApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.initialDarkMode;
  }

  Future<void> _saveDarkMode(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bazar_is_dark_mode', val);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bazar Talika',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.green,
        useMaterial3: true,
        fontFamily: 'TiroBangla',
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.green,
        useMaterial3: true,
        fontFamily: 'TiroBangla',
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: widget.isLoggedIn ? '/home' : '/login',
      routes: {
        '/login': (_) => const LoginPage(),
        '/home': (_) => HomeScreen(
          onDarkModeToggle: (val) {
            setState(() {
              _isDarkMode = val;
            });
            _saveDarkMode(val);
          },
          isDarkMode: _isDarkMode,
        ),
      },
    );
  }
}
