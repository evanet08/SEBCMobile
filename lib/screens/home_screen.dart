import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'communication_screen.dart';
import 'meetings_screen.dart';
import 'admin_screen.dart';

/// Home Screen — Bottom Navigation avec 5 onglets
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _unreadCount = 0;
  Timer? _unreadTimer;
  final _api = ApiService();

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      const _DashboardTab(),
      const CommunicationScreen(),
      const MeetingsScreen(),
      const AdminScreen(),
      const ProfileScreen(),
    ]);
    _fetchUnread();
    _unreadTimer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchUnread());
  }

  @override
  void dispose() {
    _unreadTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchUnread() async {
    final r = await _api.getUnreadCount();
    if (r['success'] == true && mounted) {
      setState(() => _unreadCount = r['count'] ?? 0);
    }
  }

  void navigateTo(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F1D35),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.dashboard_rounded, 'Accueil'),
                _navItem(1, Icons.forum_rounded, 'Messages', badge: _unreadCount),
                _navItem(2, Icons.event_rounded, 'Réunions'),
                _navItem(3, Icons.admin_panel_settings_rounded, 'Admin'),
                _navItem(4, Icons.account_circle_rounded, 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, {int badge = 0}) {
    final active = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(clipBehavior: Clip.none, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: active ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: active ? Colors.white : Colors.white.withValues(alpha: 0.4)),
            ),
            if (badge > 0) Positioned(
              top: -2, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: const Color(0xFFE83350), borderRadius: BorderRadius.circular(10)),
                child: Text('$badge', style: GoogleFonts.inter(color: const Color(0xFFFFFFFF), fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
          const SizedBox(height: 3),
          Text(label, style: GoogleFonts.inter(
            fontSize: 9, fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.4),
          )),
        ]),
      ),
    );
  }
}

// ═══ Dashboard Tab ═══
class _DashboardTab extends StatefulWidget {
  const _DashboardTab();
  @override State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  final _api = ApiService();
  Map<String, dynamic>? _profileData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await _api.getProfile();
    if (r['success'] == true && mounted) {
      setState(() { _profileData = r['membre']; _loading = false; });
      AuthProvider.instance.setMembreFromJson(r['membre']);
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthProvider.instance;
    final m = auth.membre;
    final filleuls = (_profileData?['filleuls_en_attente'] as List?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFD7E9F7),
      body: CustomScrollView(slivers: [
        // ── App Bar ──
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          backgroundColor: const Color(0xFF0F1D35),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF0B1628), Color(0xFF1A3A5C), Color(0xFF234B73)],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                    Row(children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Center(child: Text(
                          (m?.prenom.isNotEmpty == true ? m!.prenom[0] : 'S').toUpperCase(),
                          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                        )),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Bienvenue,', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                        Text(m?.nomComplet ?? 'Membre SEBC', style: GoogleFonts.inter(color: const Color(0xFFFFFFFF), fontSize: 18, fontWeight: FontWeight.w700)),
                      ])),
                      IconButton(
                        icon: Icon(Icons.logout_rounded, color: Colors.white.withValues(alpha: 0.6), size: 20),
                        onPressed: () async {
                          await auth.logout();
                          if (!context.mounted) return;
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                        },
                      ),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      _statusChip(m?.role ?? 'MEMBRE', Colors.white.withValues(alpha: 0.12)),
                      const SizedBox(width: 6),
                      _statusChip(m?.statut ?? 'EN_ATTENTE', _statutBgColor(m?.statut)),
                      if (m?.celluleCode != null) ...[
                        const SizedBox(width: 6),
                        _statusChip(m!.celluleCode!, Colors.white.withValues(alpha: 0.08)),
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
            // ── Filleuls en attente (alerte) ──
            if (filleuls.isNotEmpty) ...[
              _alertCard(
                icon: Icons.people_alt_rounded,
                color: const Color(0xFFD97706),
                title: '${filleuls.length} filleul(s) en attente de validation',
                action: 'Voir',
                onTap: () => context.findAncestorStateOfType<HomeScreenState>()?.navigateTo(4),
              ),
              const SizedBox(height: 12),
            ],

            // ── Modules ──
            Text('Modules', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: [
                _moduleCard(Icons.forum_rounded, 'Communication', 'Messagerie', const Color(0xFF0EA5E9),
                  () => context.findAncestorStateOfType<HomeScreenState>()?.navigateTo(1)),
                _moduleCard(Icons.event_rounded, 'Réunions', 'Planifier & rejoindre', const Color(0xFF0D9488),
                  () => context.findAncestorStateOfType<HomeScreenState>()?.navigateTo(2)),
                _moduleCard(Icons.admin_panel_settings_rounded, 'Administration', 'Gestion membres', const Color(0xFF7C3AED),
                  () => context.findAncestorStateOfType<HomeScreenState>()?.navigateTo(3)),
                _moduleCard(Icons.account_circle_rounded, 'Mon Espace', 'Profil & documents', const Color(0xFF1A3A5C),
                  () => context.findAncestorStateOfType<HomeScreenState>()?.navigateTo(4)),
              ],
            ),

            const SizedBox(height: 20),
            // ── Infos SEBC ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBDD4EA)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF1A3A5C)),
                  const SizedBox(width: 8),
                  Text('S.E.B.C Dushigikirane', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A3A5C))),
                ]),
                const SizedBox(height: 8),
                Text(
                  'Soutien Entre Burundais du Canada — Association d\'entraide mutuelle pour la communauté burundaise au Canada.',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), height: 1.5),
                ),
              ]),
            ),
            const SizedBox(height: 80),
          ])),
        ),
      ]),
    );
  }

  Widget _statusChip(String label, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
  );

  Color _statutBgColor(String? s) {
    switch (s) {
      case 'APPROUVE': return const Color(0xFF059669).withValues(alpha: 0.4);
      case 'EN_ATTENTE': return const Color(0xFFD97706).withValues(alpha: 0.4);
      case 'REJETE': return const Color(0xFFDC2626).withValues(alpha: 0.4);
      default: return Colors.white.withValues(alpha: 0.12);
    }
  }

  Widget _alertCard({required IconData icon, required Color color, required String title, required String action, required VoidCallback onTap}) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 20, color: color),
      ),
      const SizedBox(width: 12),
      Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: color))),
      TextButton(onPressed: onTap, child: Text(action, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: color))),
    ]),
  );

  Widget _moduleCard(IconData icon, String title, String sub, Color color, VoidCallback? onTap) => Material(
    color: const Color(0xFFFFFFFF),
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
            Text(sub, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8))),
          ]),
        ]),
      ),
    ),
  );
}
