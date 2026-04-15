import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

/// Profile Screen — Mon Espace personnel
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _profileData;
  bool _loading = true;
  bool _editing = false;
  final _phoneCtrl = TextEditingController();
  final _phoneCanadaCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await _api.getProfile();
    if (r['success'] == true) {
      _profileData = r['membre'];
      AuthProvider.instance.setMembreFromJson(r['membre']);
      _phoneCtrl.text = r['membre']?['telephone'] ?? '';
      _phoneCanadaCtrl.text = r['membre']?['telephone_canada'] ?? '';
      _villeCtrl.text = r['membre']?['ville'] ?? '';
    }
    setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    final r = await _api.updateProfile({
      'telephone_whatsapp': _phoneCtrl.text.trim(),
      'telephone_canada': _phoneCanadaCtrl.text.trim(),
      'ville_residence': _villeCtrl.text.trim(),
    });
    if (r['success'] == true && mounted) {
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour !'), backgroundColor: Color(0xFF059669)));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = AuthProvider.instance.membre;

    return Scaffold(
      backgroundColor: const Color(0xFFD5DDE7),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : CustomScrollView(slivers: [
            // ── Header ──
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: const Color(0xFF0F1D35),
              actions: [
                IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
                IconButton(
                  icon: Icon(_editing ? Icons.close_rounded : Icons.edit_rounded),
                  onPressed: () => setState(() => _editing = !_editing),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [Color(0xFF0B1628), Color(0xFF1A3A5C), Color(0xFF234B73)],
                    ),
                  ),
                  child: SafeArea(
                    child: Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const SizedBox(height: 20),
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 2),
                          ),
                          child: Center(child: Text(
                            (m?.prenom.isNotEmpty == true ? m!.prenom[0] : '?').toUpperCase(),
                            style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                          )),
                        ),
                        const SizedBox(height: 10),
                        Text(m?.nomComplet ?? '', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(m?.email ?? '', style: GoogleFonts.inter(fontSize: 12, color: Colors.white60)),
                        const SizedBox(height: 8),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          _chip(m?.role ?? 'MEMBRE', Colors.white.withValues(alpha: 0.12)),
                          const SizedBox(width: 6),
                          _chip(m?.statut ?? '', _statutColor(m?.statut)),
                          if (m?.celluleCode != null) ...[
                            const SizedBox(width: 6),
                            _chip(m!.celluleCode!, Colors.white.withValues(alpha: 0.08)),
                          ],
                        ]),
                      ]),
                    ),
                  ),
                ),
              ),
            ),

            // ── Content ──
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(delegate: SliverChildListDelegate([
                // Informations personnelles
                _sectionTitle('Informations personnelles'),
                const SizedBox(height: 10),
                _infoCard([
                  _infoRow(Icons.email_outlined, 'Email', m?.email ?? '', editable: false),
                  _infoRow(Icons.phone_outlined, 'Téléphone WhatsApp', m?.telephone ?? 'Non renseigné',
                    editable: _editing, controller: _phoneCtrl),
                  _infoRow(Icons.phone_android_rounded, 'Téléphone Canada', m?.telephoneCanada ?? 'Non renseigné',
                    editable: _editing, controller: _phoneCanadaCtrl),
                  _infoRow(Icons.location_city_rounded, 'Ville de résidence', m?.ville ?? 'Non renseigné',
                    editable: _editing, controller: _villeCtrl),
                  _infoRow(Icons.badge_outlined, 'Type de membre', m?.typeMembre ?? 'Membre standard', editable: false),
                ]),

                if (_editing) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity, height: 48,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Sauvegarder', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ],

                // Parrainage info
                const SizedBox(height: 20),
                _sectionTitle('Parrainage'),
                const SizedBox(height: 10),
                _infoCard([
                  _infoRow(Icons.shield_rounded, 'Mon parrain', _profileData?['parrain_nom'] ?? 'Aucun', editable: false),
                  _infoRow(Icons.verified_rounded, 'Validation', (_profileData?['parrain_valide'] == true) ? 'Validé ✓' : 'En attente', editable: false),
                ]),
                const SizedBox(height: 80),
              ])),
            ),
          ]),
    );
  }

  Widget _chip(String label, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
  );

  Color _statutColor(String? s) {
    switch (s) {
      case 'APPROUVE': return const Color(0xFF059669).withValues(alpha: 0.4);
      case 'EN_ATTENTE': return const Color(0xFFD97706).withValues(alpha: 0.4);
      default: return Colors.white.withValues(alpha: 0.12);
    }
  }

  Widget _sectionTitle(String title) => Text(title,
    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)));

  Widget _infoCard(List<Widget> children) => Container(
    decoration: BoxDecoration(color: const Color(0xFFF0F3F7), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFCBD5E1))),
    child: Column(children: children),
  );

  Widget _infoRow(IconData icon, String label, String value, {bool editable = false, TextEditingController? controller}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(children: [
        Icon(icon, size: 18, color: const Color(0xFF1A3A5C)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          if (editable && controller != null)
            TextField(
              controller: controller,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF0F172A)),
              decoration: InputDecoration(
                isDense: true, contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                hintText: 'Saisir...',
                hintStyle: GoogleFonts.inter(color: const Color(0xFFCBD5E1)),
              ),
            )
          else
            Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF0F172A))),
        ])),
      ]),
    );
  }
}
