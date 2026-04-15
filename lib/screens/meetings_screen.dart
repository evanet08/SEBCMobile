import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/api_service.dart';

/// Meetings Screen — Onglets À venir / Historique + Planification
class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key});
  @override State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _api = ApiService();
  List<Meeting> _meetings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await _api.getMeetings();
    if (r['success'] == true) {
      _meetings = (r['meetings'] as List? ?? []).map((m) => Meeting.fromJson(m)).toList();
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _meetings.where((m) => m.status == 'scheduled' || m.status == 'live').toList();
    final history = _meetings.where((m) => m.status == 'ended' || m.status == 'cancelled').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFD7E9F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1D35),
        foregroundColor: Colors.white,
        title: Text('Réunions', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17)),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load)],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: 'À venir (${upcoming.length})'),
            Tab(text: 'Historique (${history.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showScheduleDialog,
        backgroundColor: const Color(0xFF1A3A5C),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(controller: _tabCtrl, children: [
            _buildList(upcoming, empty: 'Aucune réunion planifiée', emptyIcon: Icons.event_available_rounded),
            _buildList(history, empty: 'Aucun historique', emptyIcon: Icons.history_rounded),
          ]),
    );
  }

  Widget _buildList(List<Meeting> list, {required String empty, required IconData emptyIcon}) {
    if (list.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFFBDD4EA).withValues(alpha: 0.4), shape: BoxShape.circle),
          child: Icon(emptyIcon, size: 48, color: const Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 16),
        Text(empty, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
        const SizedBox(height: 4),
        Text('Planifiez une réunion avec le bouton +', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) => _meetingCard(list[i]),
      ),
    );
  }

  Widget _meetingCard(Meeting m) {
    final isActive = m.status == 'scheduled' || m.status == 'live';
    final statusColor = m.status == 'live' ? const Color(0xFF059669)
      : m.status == 'scheduled' ? const Color(0xFF0EA5E9)
      : m.status == 'cancelled' ? const Color(0xFFDC2626) : const Color(0xFF94A3B8);
    final statusLabel = m.status == 'live' ? 'En cours'
      : m.status == 'scheduled' ? 'Planifiée'
      : m.status == 'cancelled' ? 'Annulée' : 'Terminée';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBDD4EA)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(isActive ? Icons.videocam_rounded : Icons.videocam_off_rounded, size: 20, color: statusColor),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
              const SizedBox(height: 2),
              Text('Par ${m.creatorName}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6),
                border: Border.all(color: statusColor.withValues(alpha: 0.2))),
              child: Text(statusLabel, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
            ),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF0F6FB), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              _infoChip(Icons.calendar_today_rounded, m.scheduledDisplay),
              const SizedBox(width: 16),
              _infoChip(Icons.timer_outlined, '${m.durationMinutes} min'),
              const SizedBox(width: 16),
              _infoChip(Icons.people_outline_rounded, '${m.nInvitees} invités'),
            ]),
          ),
          if (isActive) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _actionBtn('Rejoindre', const Color(0xFF059669), Icons.videocam_rounded, () => _joinMeeting(m))),
              const SizedBox(width: 8),
              _actionBtn('Copier', const Color(0xFF1A3A5C), Icons.copy_rounded, () => _copyLink(m)),
              if (m.isOwner) ...[
                const SizedBox(width: 8),
                _actionBtn('Annuler', const Color(0xFFDC2626), Icons.cancel_rounded, () => _cancelMeeting(m)),
              ],
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 13, color: const Color(0xFF94A3B8)),
    const SizedBox(width: 4),
    Text(text, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
  ]);

  Widget _actionBtn(String label, Color color, IconData icon, VoidCallback onTap) => Material(
    color: color,
    borderRadius: BorderRadius.circular(10),
    child: InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
        ]),
      ),
    ),
  );

  void _joinMeeting(Meeting m) async {
    final url = 'https://meet.jit.si/${m.roomName}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _cancelMeeting(Meeting m) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Annuler la réunion ?', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      content: Text('Voulez-vous annuler "${m.title}" ?', style: GoogleFonts.inter()),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
          child: const Text('Oui, annuler'),
        ),
      ],
    ));
    if (confirm == true) { await _api.cancelMeeting(m.id); _load(); }
  }

  void _copyLink(Meeting m) {
    Clipboard.setData(ClipboardData(text: m.shareUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lien copié !'), backgroundColor: const Color(0xFF1A3A5C)));
  }

  void _showScheduleDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 1));
    int duration = 60;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFBDD4EA), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text('Planifier une réunion', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text('Remplissez les informations ci-dessous', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
          const SizedBox(height: 20),
          _inputField(titleCtrl, 'Titre de la réunion *', Icons.title_rounded),
          const SizedBox(height: 12),
          _inputField(descCtrl, 'Description (optionnel)', Icons.notes_rounded),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(context: ctx, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
              if (date != null && ctx.mounted) {
                final time = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(selectedDate));
                if (time != null) setS(() => selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute));
              }
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFF0F6FB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFBDD4EA))),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF94A3B8)),
                const SizedBox(width: 10),
                Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year} à ${selectedDate.hour.toString().padLeft(2, '0')}:${selectedDate.minute.toString().padLeft(2, '0')}',
                  style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A))),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: const Color(0xFFF0F6FB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFBDD4EA))),
            child: DropdownButtonFormField<int>(
              value: duration,
              decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.timer_outlined, size: 18, color: Color(0xFF94A3B8))),
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
              items: const [
                DropdownMenuItem(value: 30, child: Text('30 minutes')),
                DropdownMenuItem(value: 60, child: Text('1 heure')),
                DropdownMenuItem(value: 90, child: Text('1h30')),
                DropdownMenuItem(value: 120, child: Text('2 heures')),
              ],
              onChanged: (v) => setS(() => duration = v ?? 60),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              final r = await _api.createMeeting({
                'title': titleCtrl.text.trim(),
                'description': descCtrl.text.trim(),
                'scheduled_at': selectedDate.toIso8601String(),
                'duration_minutes': duration,
                'invitees': [],
              });
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (r['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Réunion "${titleCtrl.text}" planifiée !'), backgroundColor: const Color(0xFF059669)));
                _load();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A3A5C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Planifier la réunion', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          )),
        ]),
      )),
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint, IconData icon) => Container(
    decoration: BoxDecoration(color: const Color(0xFFF0F6FB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFBDD4EA))),
    child: TextField(
      controller: ctrl,
      style: GoogleFonts.inter(fontSize: 14),
      decoration: InputDecoration(hintText: hint, hintStyle: GoogleFonts.inter(color: const Color(0xFFBDD4EA)),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 14)),
    ),
  );
}
