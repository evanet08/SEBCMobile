import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'candidature_screen.dart';

/// Login Screen — Premium Aurora design matching the web version
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _api = ApiService();
  bool _emailChecked = false;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  late AnimationController _pulseCtrl;
  late AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _floatCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

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
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      body: Stack(
        children: [
          // ═══ AURORA BACKGROUND ═══
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0B1628),
                  Color(0xFF122240),
                  Color(0xFF1A3050),
                  Color(0xFF0F1D35),
                ],
                stops: [0.0, 0.3, 0.6, 1.0],
              ),
            ),
          ),

          // ═══ GLOW EFFECTS ═══
          // Top-right blue glow
          Positioned(
            top: -size.height * 0.15,
            right: -size.width * 0.2,
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Container(
                width: size.width * 0.7,
                height: size.width * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF1E90FF).withValues(alpha: 0.15 + _pulseCtrl.value * 0.1),
                      const Color(0xFF1E90FF).withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.5, 1],
                  ),
                ),
              ),
            ),
          ),

          // Bottom-left magenta glow
          Positioned(
            bottom: -size.height * 0.1,
            left: -size.width * 0.25,
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Container(
                width: size.width * 0.65,
                height: size.width * 0.65,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFB03060).withValues(alpha: 0.12 + _pulseCtrl.value * 0.08),
                      const Color(0xFFB03060).withValues(alpha: 0.04),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.5, 1],
                  ),
                ),
              ),
            ),
          ),

          // Center subtle teal glow
          Positioned(
            top: size.height * 0.3,
            left: size.width * 0.1,
            child: AnimatedBuilder(
              animation: _floatCtrl,
              builder: (_, __) => Transform.translate(
                offset: Offset(0, _floatCtrl.value * 20 - 10),
                child: Container(
                  width: size.width * 0.35,
                  height: size.width * 0.35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF0D9488).withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ═══ FLOATING DECORATIVE DOTS ═══
          ..._buildFloatingOrbs(size),

          // ═══ MAIN CONTENT ═══
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? size.width * 0.15 : 28,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(children: [
                    // ── Logo ──
                    _buildLogo().animate().fadeIn(duration: 600.ms).scale(
                      begin: const Offset(0.7, 0.7),
                      curve: Curves.elasticOut,
                      duration: 800.ms,
                    ),
                    const SizedBox(height: 20),

                    // ── Title ──
                    Text(
                      'S.E.B.C',
                      style: GoogleFonts.inter(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 6,
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                    const SizedBox(height: 4),
                    Text(
                      'Dushigikirane',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w300,
                        letterSpacing: 3,
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Text(
                        'Soutien Entre Burundais du Canada',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                    const SizedBox(height: 36),

                    // ── Login Card ──
                    _buildLoginCard().animate().fadeIn(delay: 500.ms, duration: 600.ms).slideY(begin: 0.15),

                    // ── Candidature link ──
                    const SizedBox(height: 24),
                    _buildCandidatureLink().animate().fadeIn(delay: 700.ms),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // WIDGETS
  // ═══════════════════════════════════════════

  Widget _buildLogo() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E90FF).withValues(alpha: 0.2),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.asset('assets/images/logo_sebc.png', fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.people_alt_rounded, size: 44, color: Colors.white)),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: const Color(0xFF1E90FF).withValues(alpha: 0.08),
            blurRadius: 60,
            spreadRadius: -10,
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A3A5C), Color(0xFF2C5F8A)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _emailChecked ? Icons.lock_rounded : Icons.login_rounded,
              size: 18, color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              _emailChecked ? 'Mot de passe' : 'Connexion',
              style: GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
            ),
            Text(
              _emailChecked ? 'Saisissez votre mot de passe' : 'Accédez à votre espace membre',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
            ),
          ]),
        ]),
        const SizedBox(height: 24),

        // Divider
        Container(height: 1, decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            Colors.transparent,
            const Color(0xFFE2E8F0),
            Colors.transparent,
          ]),
        )),
        const SizedBox(height: 24),

        // ── Email Field ──
        if (!_emailChecked) ...[
          _buildLabel('Adresse email'),
          const SizedBox(height: 8),
          _buildEmailField(),
        ] else ...[
          _buildEmailChip(),
          const SizedBox(height: 16),
          _buildLabel('Mot de passe'),
          const SizedBox(height: 8),
          _buildPasswordField(),
        ],

        // ── Error ──
        if (_error != null) ...[
          const SizedBox(height: 14),
          _buildErrorBanner(),
        ],

        const SizedBox(height: 24),

        // ── Submit Button ──
        _buildSubmitButton(),
      ]),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF475569),
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: TextField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'votre@email.com',
          hintStyle: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 14),
          prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF94A3B8), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          filled: false,
        ),
        onSubmitted: (_) => _checkEmail(),
      ),
    );
  }

  Widget _buildEmailChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          const Color(0xFF1A3A5C).withValues(alpha: 0.06),
          const Color(0xFF2C5F8A).withValues(alpha: 0.04),
        ]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A3A5C).withValues(alpha: 0.12)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF059669).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.check_circle, size: 16, color: Color(0xFF059669)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(
          _emailCtrl.text,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1A3A5C)),
        )),
        GestureDetector(
          onTap: () => setState(() { _emailChecked = false; _error = null; }),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.edit_rounded, size: 14, color: Color(0xFF64748B)),
          ),
        ),
      ]),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: TextField(
        controller: _passCtrl,
        obscureText: _obscure,
        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: '••••••••',
          hintStyle: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 14),
          prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF94A3B8), size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              size: 20, color: const Color(0xFF94A3B8),
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          filled: false,
        ),
        onSubmitted: (_) => _login(),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFDC2626).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFDC2626)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(
          _error!,
          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFDC2626), fontWeight: FontWeight.w500),
        )),
      ]),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F2440), Color(0xFF1A3A5C), Color(0xFF234B73)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A3A5C).withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _loading ? null : (_emailChecked ? _login : _checkEmail),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: _loading
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(
                  _emailChecked ? 'Se connecter' : 'Continuer',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
              ]),
        ),
      ),
    );
  }

  Widget _buildCandidatureLink() {
    return TextButton(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CandidatureScreen())),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.04),
      ),
      child: Text.rich(TextSpan(children: [
        TextSpan(
          text: 'Pas encore membre ? ',
          style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
        ),
        TextSpan(
          text: 'Rejoindre l\'association',
          style: GoogleFonts.inter(
            color: const Color(0xFFE83350),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ])),
    );
  }

  // ═══ FLOATING ORBS ═══
  List<Widget> _buildFloatingOrbs(Size size) {
    final rng = Random(42);
    return List.generate(6, (i) {
      final orbSize = 4.0 + rng.nextDouble() * 4;
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final alpha = 0.15 + rng.nextDouble() * 0.25;
      return Positioned(
        left: x, top: y,
        child: AnimatedBuilder(
          animation: _floatCtrl,
          builder: (_, __) => Transform.translate(
            offset: Offset(
              sin(_floatCtrl.value * pi * 2 + i) * 8,
              cos(_floatCtrl.value * pi * 2 + i * 0.7) * 12,
            ),
            child: Container(
              width: orbSize,
              height: orbSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: alpha),
                boxShadow: [BoxShadow(
                  color: const Color(0xFF1E90FF).withValues(alpha: 0.3),
                  blurRadius: 8,
                )],
              ),
            ),
          ),
        ),
      );
    });
  }
}
