import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'chat_screen.dart';

/// Communication Screen — Liste des contacts WhatsApp-style
class CommunicationScreen extends StatefulWidget {
  const CommunicationScreen({super.key});
  @override State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> {
  final _api = ApiService();
  final _searchCtrl = TextEditingController();
  List<Contact> _contacts = [];
  Map<String, Map<String, dynamic>> _threads = {};
  bool _loading = true;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _loading = true);
    final auth = AuthProvider.instance;
    final membreId = auth.membre?.id ?? 0;
    final isGest = auth.membre?.isGestionnaire ?? false;

    List<Contact> contacts = [];
    // National & General channels
    if (isGest) {
      contacts.add(Contact(id: 'grp_national', type: 'national_group', name: '📢 Tous les Membres',
        sub: 'Communication nationale', scope: 'national', icon: 'globe', colorIndex: 3));
    }
    contacts.add(Contact(id: 'grp_general', type: 'general_group', name: '💬 Général',
      sub: 'Discussion ouverte à tous', scope: 'national', icon: 'chat', colorIndex: 0));

    try {
      final r = await _api.getContacts();
      if (r['success'] == true) {
        // Cellules
        final cellules = (r['cellules'] as List? ?? []);
        for (var i = 0; i < cellules.length; i++) {
          final c = cellules[i];
          contacts.add(Contact(id: 'cell_${c['id']}', type: 'cellule', name: c['nom'] ?? c['code'],
            sub: '${c['count']} membres', scope: 'cellule', celluleId: c['id'],
            icon: 'grid', colorIndex: i % 10));
        }
        // Custom groups
        for (final g in (r['custom_groups'] as List? ?? [])) {
          contacts.add(Contact(id: 'cgrp_${g['id']}', type: 'custom_group', name: g['nom'],
            sub: '${g['count']} membres', scope: 'custom_group', groupId: g['id'],
            icon: 'group', colorIndex: 8));
        }
        // Types membres
        for (final t in (r['types_membres'] as List? ?? [])) {
          contacts.add(Contact(id: 'type_${t['id']}', type: 'type_membre', name: '👥 ${t['libelle']}',
            sub: '${t['count']} membres', scope: 'type_membre', typeMembreId: t['id'],
            icon: 'layers', colorIndex: 5));
        }
        // Individual members
        for (var i = 0; i < (r['members'] as List? ?? []).length; i++) {
          final m = r['members'][i];
          if (m['id'] == membreId) continue;
          contacts.add(Contact(id: 'mbr_${m['id']}', type: 'individual', name: m['nom_complet'],
            sub: m['email'] ?? '', scope: 'individual', membreId: m['id'],
            icon: 'person', colorIndex: i % 10));
        }
      }
    } catch (_) {}

    // Threads
    try {
      final r = await _api.getThreads();
      if (r['success'] == true) {
        for (final t in (r['threads'] as List? ?? [])) {
          _threads[t['thread_id']] = t;
          // Set unread on matching contact
          final matching = contacts.where((c) => c.threadId == t['thread_id']);
          for (final c in matching) { c.unread = t['unread'] ?? 0; }
        }
      }
    } catch (_) {}

    setState(() { _contacts = contacts; _loading = false; });
  }

  List<Contact> get _filteredContacts {
    if (_filter.isEmpty) return _contacts;
    return _contacts.where((c) =>
      c.name.toLowerCase().contains(_filter) || c.sub.toLowerCase().contains(_filter)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.group_add_rounded), onPressed: _showCreateGroupDialog, tooltip: 'Nouveau groupe'),
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadContacts),
        ],
      ),
      body: Column(children: [
        // Search
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          color: const Color(0xFFFFFFFF),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _filter = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Rechercher un membre...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _filter.isNotEmpty
                ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () { _searchCtrl.clear(); setState(() => _filter = ''); })
                : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              isDense: true,
            ),
          ),
        ),

        // Contacts list
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadContacts,
                child: ListView.builder(
                  itemCount: _filteredContacts.length,
                  itemBuilder: (_, i) => _ContactTile(
                    contact: _filteredContacts[i],
                    thread: _threads[_filteredContacts[i].threadId],
                    onTap: () => _openChat(_filteredContacts[i]),
                  ),
                ),
              ),
        ),
      ]),
    );
  }

  void _openChat(Contact contact) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(contact: contact)));
  }

  void _showCreateGroupDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Row(children: [
        const Icon(Icons.group_add, color: SEBCColors.primary),
        const SizedBox(width: 8),
        Text('Nouveau Groupe', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'Nom du groupe')),
        const SizedBox(height: 12),
        TextField(controller: descCtrl, decoration: const InputDecoration(hintText: 'Description (optionnel)')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () async {
            if (nameCtrl.text.trim().isEmpty) return;
            final r = await _api.createGroup({'nom': nameCtrl.text.trim(), 'description': descCtrl.text.trim(), 'membres': [], 'couleur': '#1a3a5c'});
            if (!ctx.mounted) return;
            Navigator.pop(ctx);
            if (r['success'] == true) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Groupe "${nameCtrl.text}" créé')));
              _loadContacts();
            }
          },
          child: const Text('Créer'),
        ),
      ],
    ));
  }
}

// ═══ Contact Tile ═══
class _ContactTile extends StatelessWidget {
  final Contact contact;
  final Map<String, dynamic>? thread;
  final VoidCallback onTap;

  const _ContactTile({required this.contact, this.thread, required this.onTap});

  IconData get _icon {
    switch (contact.icon) {
      case 'globe': return Icons.public_rounded;
      case 'chat': return Icons.chat_rounded;
      case 'grid': return Icons.grid_view_rounded;
      case 'group': return Icons.groups_rounded;
      case 'layers': return Icons.layers_rounded;
      default: return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = SEBCColors.avatarColors[contact.colorIndex % SEBCColors.avatarColors.length];
    final lastMsg = thread?['last_message'] ?? contact.sub;
    final lastTime = thread?['last_time'] ?? '';
    final unread = contact.unread;

    return Material(
      color: const Color(0xFFFFFFFF),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            // Avatar
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(_icon, color: const Color(0xFFFFFFFF), size: 22),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(contact.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: SEBCColors.textPrimary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(lastMsg, style: GoogleFonts.inter(fontSize: 12, color: SEBCColors.textSecondary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            // Meta
            Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
              if (lastTime.isNotEmpty) Text(lastTime, style: GoogleFonts.inter(fontSize: 11, color: SEBCColors.textTertiary)),
              if (unread > 0) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: SEBCColors.accent, borderRadius: BorderRadius.circular(10)),
                  child: Text('$unread', style: GoogleFonts.inter(color: const Color(0xFFFFFFFF), fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ],
            ]),
          ]),
        ),
      ),
    );
  }
}
