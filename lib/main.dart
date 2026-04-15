import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utils/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

/// Contourner les erreurs de certificat SSL en dev
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: AuthProvider.instance),
      ],
      child: const SEBCApp(),
    ),
  );
}

class SEBCApp extends StatelessWidget {
  const SEBCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SEBC Dushigikirane',
      debugShowCheckedModeBanner: false,
      theme: SEBCTheme.theme,
      home: const SplashScreen(),
    );
  }
}

/// Splash Screen — vérifie la session existante
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _animCtrl.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    final isLoggedIn = await AuthProvider.instance.checkSession();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => isLoggedIn ? const HomeScreen() : const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: SEBCColors.primaryGradient),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Icons.people_alt_rounded, size: 52, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text('SEBC', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4)),
              const SizedBox(height: 4),
              Text('Dushigikirane', style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w300, letterSpacing: 2)),
              const SizedBox(height: 30),
              SizedBox(width: 24, height: 24, child: CircularProgressIndicator(
                strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.6)),
              )),
            ]),
          ),
        ),
      ),
    );
  }
}
