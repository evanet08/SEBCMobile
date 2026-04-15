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

/// Home Screen — Bottom Navigation avec 4 onglets
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
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home_rounded, 'Accueil'),
                _navItem(1, Icons.chat_rounded, 'Messages', badge: _unreadCount),
                _navItem(2, Icons.videocam_rounded, 'Réunions'),
                _navItem(3, Icons.person_rounded, 'Profil'),
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
        width: 70,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(clipBehavior: Clip.none, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: active ? SEBCColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: active ? SEBCColors.primary : SEBCColors.textTertiary),
            ),
            if (badge > 0) Positioned(
              top: 0, right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: SEBCColors.accent, borderRadius: BorderRadius.circular(10)),
                child: Text('$badge', style: GoogleFonts.inter(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(
            fontSize: 10, fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? SEBCColors.primary : SEBCColors.textTertiary,
          )),
        ]),
      ),
    );
  }
}

// ═══ Dashboard Tab ═══
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final auth = AuthProvider.instance;
    final m = auth.membre;
    return Scaffold(
      appBar: AppBar(
        title: Text('SEBC Dushigikirane', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await auth.logout();
              if (!context.mounted) return;
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Welcome card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: SEBCColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: SEBCColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(child: Text(
                    (m?.prenom.isNotEmpty == true ? m!.prenom[0] : 'S').toUpperCase(),
                    style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                  )),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Bienvenue,', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                  Text(m?.nomComplet ?? 'Membre', style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                ])),
              ]),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${m?.role ?? 'MEMBRE'} • ${m?.celluleCode ?? 'Aucune cellule'}',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 24),
          Text('Modules', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: SEBCColors.textPrimary)),
          const SizedBox(height: 12),

          // Module cards
          _ModuleCard(
            icon: Icons.chat_rounded, color: SEBCColors.info, label: 'Communication',
            sub: 'Messagerie et appels vidéo',
            onTap: () => context.findAncestorStateOfType<HomeScreenState>()?.navigateTo(1),
          ),
          const SizedBox(height: 10),
          _ModuleCard(
            icon: Icons.videocam_rounded, color: SEBCColors.teal, label: 'Réunions',
            sub: 'Planifier et rejoindre des réunions',
            onTap: () => context.findAncestorStateOfType<HomeScreenState>()?.navigateTo(2),
          ),
          const SizedBox(height: 10),
          _ModuleCard(
            icon: Icons.person_rounded, color: SEBCColors.primary, label: 'Mon Espace',
            sub: 'Profil, ayants droits, documents',
            onTap: () => context.findAncestorStateOfType<HomeScreenState>()?.navigateTo(3),
          ),
        ]),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String sub;
  final VoidCallback? onTap;

  const _ModuleCard({required this.icon, required this.color, required this.label, required this.sub, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: SEBCColors.textPrimary)),
              Text(sub, style: GoogleFonts.inter(fontSize: 12, color: SEBCColors.textSecondary)),
            ])),
            const Icon(Icons.chevron_right_rounded, color: SEBCColors.textTertiary),
          ]),
        ),
      ),
    );
  }
}
