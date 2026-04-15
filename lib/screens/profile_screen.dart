import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../models/models.dart';

/// Profile Screen — Espace membre
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _profileData;
  List<AyantDroit> _ayantsDroits = [];
  bool _loading = true;

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
    }
    final ad = await _api.getAyantsDroits();
    if (ad['success'] == true) {
      _ayantsDroits = (ad['ayants_droits'] as List? ?? []).map((a) => AyantDroit.fromJson(a)).toList();
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final m = AuthProvider.instance.membre;

    return Scaffold(
      appBar: AppBar(
        title: Text('Mon Espace', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Profile card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: SEBCColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                      ),
                      child: Center(child: Text(
                        (m?.prenom.isNotEmpty == true ? m!.prenom[0] : '?').toUpperCase(),
                        style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                      )),
                    ),
                    const SizedBox(height: 12),
                    Text(m?.nomComplet ?? '', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(m?.email ?? '', style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
                    const SizedBox(height: 10),
                    Wrap(spacing: 6, children: [
                      _chip(m?.role ?? 'MEMBRE', Colors.white.withValues(alpha: 0.2), Colors.white),
                      _chip(m?.statut ?? 'EN_ATTENTE', _statutColor(m?.statut), Colors.white),
                      if (m?.celluleCode != null) _chip(m!.celluleCode!, Colors.white.withValues(alpha: 0.15), Colors.white),
                    ]),
                  ]),
                ),

                const SizedBox(height: 20),
                // Info items
                Text('Informations', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: SEBCColors.textPrimary)),
                const SizedBox(height: 10),
                _infoRow(Icons.email_outlined, 'Email', m?.email ?? ''),
                _infoRow(Icons.phone_outlined, 'Téléphone', m?.telephone ?? 'Non renseigné'),
                _infoRow(Icons.phone_android, 'Tél. Canada', m?.telephoneCanada ?? 'Non renseigné'),
                _infoRow(Icons.location_city, 'Ville', m?.ville ?? 'Non renseigné'),
                _infoRow(Icons.badge_outlined, 'Type', m?.typeMembre ?? 'Membre'),

                // Ayants droits
                const SizedBox(height: 24),
                Row(children: [
                  Text('Ayants Droits', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: SEBCColors.textPrimary)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: SEBCColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text('${_ayantsDroits.length}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: SEBCColors.primary)),
                  ),
                ]),
                const SizedBox(height: 10),
                if (_ayantsDroits.isEmpty)
                  Center(child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Aucun ayant droit déclaré', style: GoogleFonts.inter(color: SEBCColors.textTertiary, fontSize: 13)),
                  ))
                else ..._ayantsDroits.map((ad) => _ayantDroitCard(ad)),

                // Parrainage section
                if (_profileData?['filleuls_en_attente'] != null && (_profileData!['filleuls_en_attente'] as List).isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Filleuls en attente', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: SEBCColors.warning)),
                  const SizedBox(height: 10),
                  ...(_profileData!['filleuls_en_attente'] as List).map((f) => _filleulCard(f)),
                ],

                const SizedBox(height: 80),
              ]),
            ),
          ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
  );

  Color _statutColor(String? statut) {
    switch (statut) {
      case 'APPROUVE': return SEBCColors.success.withValues(alpha: 0.3);
      case 'EN_ATTENTE': return SEBCColors.warning.withValues(alpha: 0.3);
      case 'REJETE': return SEBCColors.error.withValues(alpha: 0.3);
      default: return Colors.white.withValues(alpha: 0.15);
    }
  }

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SEBCColors.textTertiary.withValues(alpha: 0.1)),
      ),
      child: Row(children: [
        Icon(icon, size: 20, color: SEBCColors.primary),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: SEBCColors.textTertiary, fontWeight: FontWeight.w500)),
          Text(value, style: GoogleFonts.inter(fontSize: 14, color: SEBCColors.textPrimary, fontWeight: FontWeight.w500)),
        ]),
      ]),
    ),
  );

  Widget _ayantDroitCard(AyantDroit ad) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: SEBCColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: const Icon(Icons.person, color: SEBCColors.primary, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${ad.prenom} ${ad.nom}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
        Text(ad.typeLien, style: GoogleFonts.inter(fontSize: 12, color: SEBCColors.textSecondary)),
      ])),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: ad.estApprouve ? SEBCColors.success.withValues(alpha: 0.1) : SEBCColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(ad.estApprouve ? 'Approuvé' : 'En attente',
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: ad.estApprouve ? SEBCColors.success : SEBCColors.warning)),
      ),
    ]),
  );

  Widget _filleulCard(Map<String, dynamic> f) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: SEBCColors.warning.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: SEBCColors.warning.withValues(alpha: 0.2)),
    ),
    child: Row(children: [
      const Icon(Icons.person_add, color: SEBCColors.warning, size: 22),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${f['prenom']} ${f['nom']}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
        Text(f['email'] ?? '', style: GoogleFonts.inter(fontSize: 12, color: SEBCColors.textSecondary)),
      ])),
      ElevatedButton(
        onPressed: () async {
          await _api.validerFilleul(f['id']);
          _load();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: SEBCColors.success, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        child: const Text('Valider'),
      ),
    ]),
  );
}
