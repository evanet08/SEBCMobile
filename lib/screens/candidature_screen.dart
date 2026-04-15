import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme.dart';
import '../services/api_service.dart';

/// Candidature Screen — Processus d'adhésion en étapes
class CandidatureScreen extends StatefulWidget {
  const CandidatureScreen({super.key});
  @override State<CandidatureScreen> createState() => _CandidatureScreenState();
}

class _CandidatureScreenState extends State<CandidatureScreen> {
  final _api = ApiService();
  int _step = 0; // 0=parrain, 1=identification, 2=OTP, 3=password, 4=success
  bool _loading = false;
  String? _error;

  // Parrain
  final _parrainCtrl = TextEditingController();
  String? _parrainEmail;
  int? _parrainId;

  // Identification
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telWhatsappCtrl = TextEditingController();
  final _telCanadaCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  String? _selectedPays;

  // OTP
  final _otpCtrl = TextEditingController();

  // Password
  final _passCtrl = TextEditingController();
  final _passConfirmCtrl = TextEditingController();

  Future<void> _checkParrain() async {
    final contact = _parrainCtrl.text.trim();
    if (contact.isEmpty) { setState(() => _error = "Saisissez l'email ou le téléphone du parrain"); return; }
    setState(() { _loading = true; _error = null; });
    final r = await _api.checkParrain(contact);
    setState(() => _loading = false);
    if (r['success'] == true && r['found'] == true) {
      setState(() { _parrainEmail = r['email']; _parrainId = r['parrain_id']; _step = 1; _error = null; });
    } else {
      setState(() => _error = r['error'] ?? 'Parrain non trouvé. Vérifiez les informations.');
    }
  }

  Future<void> _submitIdentification() async {
    if (_nomCtrl.text.trim().isEmpty || _prenomCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Nom, prénom et email sont obligatoires'); return;
    }
    if (_telWhatsappCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Le téléphone WhatsApp est obligatoire'); return;
    }
    setState(() { _loading = true; _error = null; });
    final r = await _api.submitCandidature({
      'nom': _nomCtrl.text.trim(),
      'prenom': _prenomCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'telephone_whatsapp': _telWhatsappCtrl.text.trim(),
      'telephone_canada': _telCanadaCtrl.text.trim(),
      'ville': _villeCtrl.text.trim(),
      'parrain_id': _parrainId,
    });
    setState(() => _loading = false);
    if (r['success'] == true) {
      setState(() { _step = 2; _error = null; });
    } else {
      setState(() => _error = r['error'] ?? "Erreur lors de l'enregistrement");
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.trim().length != 6) { setState(() => _error = 'Le code doit comporter 6 chiffres'); return; }
    setState(() { _loading = true; _error = null; });
    final r = await _api.verifyOtp(_emailCtrl.text.trim(), _otpCtrl.text.trim());
    setState(() => _loading = false);
    if (r['success'] == true) {
      setState(() { _step = 3; _error = null; });
    } else {
      setState(() => _error = r['error'] ?? 'Code invalide ou expiré');
    }
  }

  Future<void> _setPassword() async {
    if (_passCtrl.text.length < 6) { setState(() => _error = 'Minimum 6 caractères'); return; }
    if (_passCtrl.text != _passConfirmCtrl.text) { setState(() => _error = 'Les mots de passe ne correspondent pas'); return; }
    setState(() { _loading = true; _error = null; });
    final r = await _api.setPasswordApi(_emailCtrl.text.trim(), _passCtrl.text);
    setState(() => _loading = false);
    if (r['success'] == true) {
      setState(() { _step = 4; _error = null; });
    } else {
      setState(() => _error = r['error'] ?? 'Erreur');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: SEBCColors.primaryGradient),
        child: SafeArea(
          child: Column(children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(children: [
                if (_step > 0 && _step < 4) IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => setState(() { _step--; _error = null; }),
                ),
                Expanded(child: Text('Candidature SEBC', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white))),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Connexion', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                ),
              ]),
            ),

            // Progress
            if (_step < 4) Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(children: List.generate(4, (i) => Expanded(child: Container(
                height: 4, margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: i <= _step ? Colors.white : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              )))),
            ),

            // Content
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 10))],
                    ),
                    child: _buildStep(),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _stepParrain();
      case 1: return _stepIdentification();
      case 2: return _stepOtp();
      case 3: return _stepPassword();
      case 4: return _stepSuccess();
      default: return const SizedBox();
    }
  }

  Widget _stepParrain() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _stepHeader('Vérification du Parrain', 'Saisissez l\'email ou le téléphone de votre parrain', Icons.person_search),
    const SizedBox(height: 20),
    TextField(controller: _parrainCtrl, decoration: const InputDecoration(hintText: 'Email ou téléphone du parrain', prefixIcon: Icon(Icons.search)),
      onSubmitted: (_) => _checkParrain()),
    _errorWidget(),
    const SizedBox(height: 16),
    _actionButton('Vérifier', _checkParrain),
    const SizedBox(height: 12),
    Center(child: Text('Votre parrain doit être un membre existant approuvé.', textAlign: TextAlign.center,
      style: GoogleFonts.inter(fontSize: 11, color: SEBCColors.textTertiary))),
  ]);

  Widget _stepIdentification() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _stepHeader('Identification', 'Remplissez vos informations personnelles', Icons.person_add),
    // Parrain info
    Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: SEBCColors.success.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        const Icon(Icons.check_circle, color: SEBCColors.success, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text('Parrain : $_parrainEmail', style: GoogleFonts.inter(fontSize: 12, color: SEBCColors.success, fontWeight: FontWeight.w500))),
      ]),
    ),
    const SizedBox(height: 4),
    _field(_nomCtrl, 'Nom *', Icons.badge),
    _field(_prenomCtrl, 'Prénom *', Icons.badge_outlined),
    _field(_emailCtrl, 'Email *', Icons.email_outlined, type: TextInputType.emailAddress),
    _field(_telWhatsappCtrl, 'Téléphone WhatsApp *', Icons.phone, type: TextInputType.phone),
    _field(_telCanadaCtrl, 'Téléphone Canada', Icons.phone_android, type: TextInputType.phone),
    _field(_villeCtrl, 'Ville de résidence', Icons.location_city),
    _errorWidget(),
    const SizedBox(height: 16),
    _actionButton("S'enregistrer", _submitIdentification),
  ]);

  Widget _stepOtp() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _stepHeader('Vérification Email', 'Un code à 6 chiffres a été envoyé à\n${_emailCtrl.text}', Icons.mark_email_read),
    const SizedBox(height: 20),
    TextField(controller: _otpCtrl, decoration: const InputDecoration(hintText: 'Code OTP (6 chiffres)', prefixIcon: Icon(Icons.lock_clock)),
      keyboardType: TextInputType.number, maxLength: 6, textAlign: TextAlign.center,
      style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 8),
      onSubmitted: (_) => _verifyOtp()),
    _errorWidget(),
    const SizedBox(height: 16),
    _actionButton('Vérifier', _verifyOtp),
    const SizedBox(height: 8),
    Center(child: TextButton(
      onPressed: () async { await _api.requestOtp(_emailCtrl.text.trim()); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code renvoyé'))); },
      child: Text('Renvoyer le code', style: GoogleFonts.inter(fontSize: 13, color: SEBCColors.primary)),
    )),
  ]);

  Widget _stepPassword() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _stepHeader('Créer un mot de passe', 'Choisissez un mot de passe sécurisé', Icons.lock_outline),
    const SizedBox(height: 20),
    TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(hintText: 'Mot de passe', prefixIcon: Icon(Icons.lock))),
    const SizedBox(height: 12),
    TextField(controller: _passConfirmCtrl, obscureText: true, decoration: const InputDecoration(hintText: 'Confirmer le mot de passe', prefixIcon: Icon(Icons.lock_outline)),
      onSubmitted: (_) => _setPassword()),
    _errorWidget(),
    const SizedBox(height: 16),
    _actionButton('Créer mon compte', _setPassword),
  ]);

  Widget _stepSuccess() => Column(children: [
    Container(
      width: 80, height: 80,
      decoration: BoxDecoration(color: SEBCColors.success.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: const Icon(Icons.check_circle_rounded, size: 48, color: SEBCColors.success),
    ),
    const SizedBox(height: 16),
    Text('Candidature envoyée !', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: SEBCColors.textPrimary)),
    const SizedBox(height: 8),
    Text('Votre parrain a été notifié par email.\nUne fois validé, vous pourrez accéder à votre espace.',
      textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: SEBCColors.textSecondary, height: 1.5)),
    const SizedBox(height: 8),
    Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: SEBCColors.warning.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Icon(Icons.info_outline, color: SEBCColors.warning, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text('Si votre parrain tarde, vous pourrez le relancer depuis votre espace membre.',
          style: GoogleFonts.inter(fontSize: 11, color: SEBCColors.textSecondary))),
      ]),
    ),
    const SizedBox(height: 20),
    SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
      onPressed: () => Navigator.pop(context),
      child: const Text('Se connecter'),
    )),
  ]);

  Widget _stepHeader(String title, String sub, IconData icon) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: SEBCColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: SEBCColors.primary, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: SEBCColors.textPrimary)),
        Text(sub, style: GoogleFonts.inter(fontSize: 12, color: SEBCColors.textSecondary)),
      ])),
    ]),
  ]);

  Widget _field(TextEditingController ctrl, String hint, IconData icon, {TextInputType type = TextInputType.text}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(controller: ctrl, keyboardType: type, decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
  );

  Widget _errorWidget() => _error != null ? Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: SEBCColors.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        const Icon(Icons.error_outline, size: 16, color: SEBCColors.error),
        const SizedBox(width: 8),
        Expanded(child: Text(_error!, style: GoogleFonts.inter(fontSize: 12, color: SEBCColors.error))),
      ]),
    ),
  ) : const SizedBox();

  Widget _actionButton(String label, VoidCallback onPressed) => SizedBox(
    width: double.infinity, height: 50,
    child: ElevatedButton(
      onPressed: _loading ? null : onPressed,
      child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(label),
    ),
  );
}
