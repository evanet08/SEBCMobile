import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';

/// Meetings Screen — Liste et planification des réunions
class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key});
  @override State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  final _api = ApiService();
  List<Meeting> _meetings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await _api.getMeetings();
    if (r['success'] == true) {
      setState(() {
        _meetings = (r['meetings'] as List? ?? []).map((m) => Meeting.fromJson(m)).toList();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _meetings.where((m) => m.status == 'scheduled' || m.status == 'live').toList();
    final past = _meetings.where((m) => m.status == 'ended' || m.status == 'cancelled').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Réunions', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showScheduleDialog,
        backgroundColor: SEBCColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Planifier', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: _meetings.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.event_busy_rounded, size: 64, color: SEBCColors.textTertiary.withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  Text('Aucune réunion', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: SEBCColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text('Cliquez sur + pour planifier', style: GoogleFonts.inter(fontSize: 13, color: SEBCColors.textTertiary)),
                ]))
              : ListView(padding: const EdgeInsets.all(16), children: [
                  if (upcoming.isNotEmpty) ...[
                    _sectionLabel('À venir / En cours', Icons.event_available_rounded, SEBCColors.success),
                    ...upcoming.map((m) => _MeetingCard(meeting: m, onJoin: () => _joinMeeting(m), onCancel: () => _cancelMeeting(m), onCopy: () => _copyLink(m))),
                    const SizedBox(height: 16),
                  ],
                  if (past.isNotEmpty) ...[
                    _sectionLabel('Terminées', Icons.history_rounded, SEBCColors.textTertiary),
                    ...past.map((m) => _MeetingCard(meeting: m)),
                  ],
                ]),
          ),
    );
  }

  Widget _sectionLabel(String label, IconData icon, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 6),
      Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
    ]),
  );

  void _joinMeeting(Meeting m) async {
    final url = 'https://meet.jit.si/${m.roomName}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _cancelMeeting(Meeting m) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Annuler la réunion ?'),
      content: Text('Voulez-vous annuler "${m.title}" ?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: SEBCColors.error),
          child: const Text('Oui, annuler')),
      ],
    ));
    if (confirm == true) {
      await _api.cancelMeeting(m.id);
      _load();
    }
  }

  void _copyLink(Meeting m) {
    Clipboard.setData(ClipboardData(text: m.shareUrl));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lien copié !')));
  }

  void _showScheduleDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 1));
    int duration = 60;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: SEBCColors.textTertiary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Planifier une réunion', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: 'Titre de la réunion *', prefixIcon: Icon(Icons.title))),
          const SizedBox(height: 12),
          TextField(controller: descCtrl, decoration: const InputDecoration(hintText: 'Description (optionnel)', prefixIcon: Icon(Icons.notes))),
          const SizedBox(height: 12),
          // Date picker
          InkWell(
            onTap: () async {
              final date = await showDatePicker(context: ctx, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
              if (date != null && ctx.mounted) {
                final time = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(selectedDate));
                if (time != null) {
                  setS(() => selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                }
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.calendar_today), hintText: 'Date et heure'),
              child: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year} à ${selectedDate.hour.toString().padLeft(2, '0')}:${selectedDate.minute.toString().padLeft(2, '0')}',
                style: GoogleFonts.inter(fontSize: 14)),
            ),
          ),
          const SizedBox(height: 12),
          // Duration
          DropdownButtonFormField<int>(
            value: duration,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.timer), hintText: 'Durée'),
            items: const [
              DropdownMenuItem(value: 30, child: Text('30 minutes')),
              DropdownMenuItem(value: 60, child: Text('1 heure')),
              DropdownMenuItem(value: 90, child: Text('1h30')),
              DropdownMenuItem(value: 120, child: Text('2 heures')),
              DropdownMenuItem(value: 180, child: Text('3 heures')),
            ],
            onChanged: (v) => setS(() => duration = v ?? 60),
          ),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(
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
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Réunion "${titleCtrl.text}" planifiée !')));
                _load();
                // Show share dialog
                if (r['meeting'] != null) _showShareDialog(r['meeting']);
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('Planifier'),
          )),
        ]),
      )),
    );
  }

  void _showShareDialog(Map<String, dynamic> meeting) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Row(children: [
        const Icon(Icons.link, color: SEBCColors.primary),
        const SizedBox(width: 8),
        Text('Réunion planifiée !', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: SEBCColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(meeting['title'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('📅 ${meeting['scheduled_at']}', style: GoogleFonts.inter(fontSize: 12, color: SEBCColors.textSecondary)),
            Text('⏱ ${meeting['duration_minutes']} min', style: GoogleFonts.inter(fontSize: 12, color: SEBCColors.textSecondary)),
          ]),
        ),
        const SizedBox(height: 12),
        SelectableText(meeting['share_url'] ?? '', style: GoogleFonts.inter(fontSize: 12, color: SEBCColors.primary)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
        ElevatedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: meeting['share_url'] ?? ''));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lien copié !')));
            Navigator.pop(ctx);
          },
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('Copier le lien'),
        ),
      ],
    ));
  }
}

// ═══ Meeting Card ═══
class _MeetingCard extends StatelessWidget {
  final Meeting meeting;
  final VoidCallback? onJoin;
  final VoidCallback? onCancel;
  final VoidCallback? onCopy;

  const _MeetingCard({required this.meeting, this.onJoin, this.onCancel, this.onCopy});

  @override
  Widget build(BuildContext context) {
    final isActive = meeting.status == 'scheduled' || meeting.status == 'live';
    final statusColor = meeting.status == 'live' ? SEBCColors.success
      : meeting.status == 'scheduled' ? SEBCColors.info
      : meeting.status == 'cancelled' ? SEBCColors.error : SEBCColors.textTertiary;
    final statusLabel = meeting.status == 'live' ? '🟢 En cours'
      : meeting.status == 'scheduled' ? '📅 Planifiée'
      : meeting.status == 'cancelled' ? 'Annulée' : 'Terminée';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: SEBCColors.textTertiary.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(meeting.title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: SEBCColors.textPrimary))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(statusLabel, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
            ),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.access_time, size: 14, color: SEBCColors.textTertiary),
            const SizedBox(width: 4),
            Text(meeting.scheduledDisplay, style: GoogleFonts.inter(fontSize: 12, color: SEBCColors.textSecondary)),
            const SizedBox(width: 10),
            Icon(Icons.timer_outlined, size: 14, color: SEBCColors.textTertiary),
            const SizedBox(width: 4),
            Text('${meeting.durationMinutes} min', style: GoogleFonts.inter(fontSize: 12, color: SEBCColors.textSecondary)),
            const SizedBox(width: 10),
            Icon(Icons.people_outline, size: 14, color: SEBCColors.textTertiary),
            const SizedBox(width: 4),
            Text('${meeting.nInvitees}', style: GoogleFonts.inter(fontSize: 12, color: SEBCColors.textSecondary)),
          ]),
          const SizedBox(height: 4),
          Text('Organisé par ${meeting.creatorName}', style: GoogleFonts.inter(fontSize: 11, color: SEBCColors.textTertiary)),
          if (isActive) ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: ElevatedButton.icon(
                onPressed: onJoin,
                icon: const Icon(Icons.videocam, size: 18),
                label: const Text('Rejoindre'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
              )),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copier'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12)),
              ),
              if (meeting.isOwner) ...[
                const SizedBox(width: 6),
                IconButton(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close, size: 18, color: SEBCColors.error),
                  style: IconButton.styleFrom(backgroundColor: SEBCColors.error.withValues(alpha: 0.1)),
                ),
              ],
            ]),
          ],
        ]),
      ),
    );
  }
}
