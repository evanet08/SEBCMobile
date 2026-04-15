import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'candidature_screen.dart';

/// Login Screen — Email → Password flow
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _api = ApiService();
  bool _emailChecked = false;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _checkEmail() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) { setState(() => _error = 'Saisissez votre email'); return; }
    setState(() { _loading = true; _error = null; });
    final r = await _api.checkEmail(email);
    setState(() { _loading = false; });
    if (r['success'] == true && r['exists'] == true) {
      setState(() => _emailChecked = true);
    } else {
      setState(() => _error = r['error'] ?? 'Email non trouvé');
    }
  }

  Future<void> _login() async {
    if (_passCtrl.text.isEmpty) { setState(() => _error = 'Saisissez votre mot de passe'); return; }
    setState(() { _loading = true; _error = null; });
    final r = await AuthProvider.instance.login(_emailCtrl.text.trim(), _passCtrl.text);
    setState(() { _loading = false; });
    if (r['success'] == true) {
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      setState(() => _error = r['error'] ?? 'Identifiants incorrects');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: SEBCColors.primaryGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(children: [
                // Logo
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: const Icon(Icons.people_alt_rounded, size: 48, color: Colors.white),
                ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.8, 0.8)),
                const SizedBox(height: 20),
                Text('SEBC Dushigikirane', style: GoogleFonts.inter(
                  fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white,
                )).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 4),
                Text('Entraidons-nous', style: GoogleFonts.inter(
                  fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w400,
                )).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 40),

                // Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 10))],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_emailChecked ? 'Mot de passe' : 'Connexion',
                      style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: SEBCColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(_emailChecked ? 'Saisissez votre mot de passe' : 'Entrez votre adresse email',
                      style: GoogleFonts.inter(fontSize: 13, color: SEBCColors.textSecondary)),
                    const SizedBox(height: 20),

                    if (!_emailChecked) ...[
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(hintText: 'votre@email.com', prefixIcon: Icon(Icons.email_outlined)),
                        onSubmitted: (_) => _checkEmail(),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: SEBCColors.surfaceVariant, borderRadius: BorderRadius.circular(10)),
                        child: Row(children: [
                          const Icon(Icons.email, size: 16, color: SEBCColors.primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_emailCtrl.text, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500))),
                          GestureDetector(
                            onTap: () => setState(() => _emailChecked = false),
                            child: const Icon(Icons.edit, size: 16, color: SEBCColors.textTertiary),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          hintText: 'Mot de passe',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 20),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        onSubmitted: (_) => _login(),
                      ),
                    ],

                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: SEBCColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(children: [
                          const Icon(Icons.error_outline, size: 16, color: SEBCColors.error),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!, style: GoogleFonts.inter(fontSize: 12, color: SEBCColors.error))),
                        ]),
                      ),
                    ],

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : (_emailChecked ? _login : _checkEmail),
                        child: _loading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(_emailChecked ? 'Se connecter' : 'Continuer'),
                      ),
                    ),
                  ]),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                // Candidature link
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CandidatureScreen())),
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: 'Pas encore membre ? ', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                    TextSpan(text: 'Devenir membre', style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
                  ])),
                ).animate().fadeIn(delay: 500.ms),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
