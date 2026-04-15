import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

/// Administration — Grille de modules + vue CRUD détaillée
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _api = ApiService();
  String? _activeSection;
  bool _loading = false;
  List<Map<String, dynamic>> _items = [];

  static const _sections = [
    _Section('parametres', 'Paramètres', Icons.tune_rounded, Color(0xFF0EA5E9)),
    _Section('pays', 'Pays', Icons.public_rounded, Color(0xFF059669)),
    _Section('provinces', 'Provinces', Icons.map_rounded, Color(0xFF7C3AED)),
    _Section('cellules', 'Cellules', Icons.groups_rounded, Color(0xFFD97706)),
    _Section('types_ad', 'Types A.D.', Icons.family_restroom_rounded, Color(0xFFE83350)),
    _Section('types_soutien', 'Types Soutien', Icons.volunteer_activism_rounded, Color(0xFF0D9488)),
    _Section('roles', 'Rôles', Icons.shield_rounded, Color(0xFF1A3A5C)),
    _Section('modules', 'Modules', Icons.extension_rounded, Color(0xFF6366F1)),
  ];

  final Map<String, int> _counts = {};

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    for (final s in _sections) {
      final r = await _apiCall(s.key, 'list');
      if (r['success'] == true && mounted) {
        setState(() => _counts[s.key] = (r['items'] as List?)?.length ?? 0);
      }
    }
  }

  Future<Map<String, dynamic>> _apiCall(String key, String action, [Map<String, dynamic>? extra]) {
    final data = <String, dynamic>{'action': action, ...?extra};
    switch (key) {
      case 'parametres': return _api.adminParametres(data);
      case 'pays': return _api.adminPays(data);
      case 'provinces': return _api.adminProvinces(data);
      case 'cellules': return _api.adminCellules(data);
      case 'types_ad': return _api.adminTypesAD(data);
      case 'types_soutien': return _api.adminTypesSoutien(data);
      case 'roles': return _api.adminRoles(data);
      case 'modules': return _api.adminModules(data);
      default: return Future.value({'success': false});
    }
  }

  Future<void> _openSection(String key) async {
    setState(() { _activeSection = key; _loading = true; });
    final r = await _apiCall(key, 'list');
    if (r['success'] == true && mounted) {
      setState(() { _items = List<Map<String, dynamic>>.from(r['items'] ?? []); _loading = false; });
    } else {
      setState(() => _loading = false);
    }
  }

  void _goBack() => setState(() => _activeSection = null);

  @override
  Widget build(BuildContext context) {
    final isAdmin = AuthProvider.instance.membre?.isGestionnaire ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFD5DDE7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1D35),
        foregroundColor: Colors.white,
        leading: _activeSection != null
          ? IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: _goBack)
          : null,
        title: Row(children: [
          Image.asset('assets/images/logo_sebc.png', height: 26,
            errorBuilder: (_, __, ___) => const Icon(Icons.shield_rounded, size: 22)),
          const SizedBox(width: 10),
          Text(
            _activeSection != null ? _sectionFor(_activeSection!).label : 'Administration',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
          ),
        ]),
        actions: _activeSection != null ? [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => _openSection(_activeSection!)),
        ] : [],
      ),
      body: !isAdmin
        ? _noAccess()
        : _activeSection == null
          ? _buildGrid()
          : _buildCrudView(),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // GRID VIEW — Modules ultra-compacts, centrés
  // ═══════════════════════════════════════════════════════════
  Widget _buildGrid() {
    return Container(
      color: const Color(0xFFD5DDE7),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Mini header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0B1628), Color(0xFF1A3A5C)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset('assets/images/logo_sebc.png', height: 28, width: 28, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.shield_rounded, size: 20, color: Colors.white)),
                  ),
                  const SizedBox(width: 10),
                  Text('Administration SEBC', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                ]),
              ),

              // Grille 4 colonnes ultra-compacte
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 0.85,
                ),
                itemCount: _sections.length,
                itemBuilder: (_, i) => _gridCard(_sections[i], _counts[_sections[i].key] ?? 0),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _gridCard(_Section s, int count) {
    // Gradient pairs per section for premium look
    final gradients = {
      'parametres': [const Color(0xFF0369A1), const Color(0xFF0EA5E9)],
      'pays': [const Color(0xFF047857), const Color(0xFF10B981)],
      'provinces': [const Color(0xFF6D28D9), const Color(0xFFA78BFA)],
      'cellules': [const Color(0xFFB45309), const Color(0xFFFBBF24)],
      'types_ad': [const Color(0xFFBE123C), const Color(0xFFFB7185)],
      'types_soutien': [const Color(0xFF0F766E), const Color(0xFF2DD4BF)],
      'roles': [const Color(0xFF0F1D35), const Color(0xFF334155)],
      'modules': [const Color(0xFF4338CA), const Color(0xFF818CF8)],
    };
    final colors = gradients[s.key] ?? [s.color, s.color.withValues(alpha: 0.7)];

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _openSection(s.key),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: colors[0].withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(s.icon, size: 22, color: Colors.white),
            const SizedBox(height: 4),
            Text(s.label, textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFFF0F3F7), height: 1.1),
              maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(6)),
              child: Text('$count', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ]),
        ),
      ),
    );
  }


  // ═══════════════════════════════════════════════════════════
  // CRUD VIEW — Liste détaillée pour la section active
  // ═══════════════════════════════════════════════════════════
  Widget _buildCrudView() {
    final s = _sectionFor(_activeSection!);
    final showAdd = _activeSection != 'roles' && _activeSection != 'modules';

    return Column(children: [
      // Action bar
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(color: const Color(0xFFF0F3F7), border: Border(bottom: BorderSide(color: Color(0xFFCBD5E1)))),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: s.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(s.icon, size: 16, color: s.color),
          ),
          const SizedBox(width: 10),
          Text('${_items.length} élément(s)', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
          const Spacer(),
          if (showAdd)
            Material(
              color: const Color(0xFF1A3A5C),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _showAddDialog(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.add_rounded, size: 15, color: Colors.white),
                    const SizedBox(width: 4),
                    Text('Nouveau', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                  ]),
                ),
              ),
            ),
        ]),
      ),

      // List
      Expanded(
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(s.icon, size: 48, color: const Color(0xFFCBD5E1)),
                const SizedBox(height: 12),
                Text('Aucun élément', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14)),
              ]))
            : RefreshIndicator(
                onRefresh: () => _openSection(_activeSection!),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _items.length,
                  itemBuilder: (_, i) => _buildItemCard(_items[i], i),
                ),
              ),
      ),
    ]);
  }

  Widget _buildItemCard(Map<String, dynamic> item, int index) {
    final key = _activeSection!;
    final s = _sectionFor(key);

    // Build display fields based on section type
    final title = _itemTitle(key, item);
    final subtitle = _itemSubtitle(key, item);
    final trailing = _itemTrailing(key, item);
    final canEdit = true;
    final canDelete = key != 'roles' && key != 'modules';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: index.isEven ? const Color(0xFFF0F3F7) : const Color(0xFFE8EDF3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: s.color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(9)),
            child: Icon(s.icon, size: 16, color: s.color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
            if (subtitle.isNotEmpty)
              Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
          ])),
          if (trailing != null) ...[trailing, const SizedBox(width: 8)],
          if (canEdit)
            _iconBtn(Icons.edit_rounded, const Color(0xFF1A3A5C), () => _showEditDialog(item)),
          if (canDelete) ...[
            const SizedBox(width: 4),
            _iconBtn(Icons.delete_outline_rounded, const Color(0xFFDC2626), () => _confirmDelete(item)),
          ],
        ]),
      ),
    );
  }

  // ═══ Item rendering per section ═══
  String _itemTitle(String key, Map<String, dynamic> item) {
    switch (key) {
      case 'parametres': return item['libelle'] ?? '';
      case 'pays': return item['nom'] ?? '';
      case 'provinces': return item['nom'] ?? '';
      case 'cellules': return '${item['code'] ?? ''} — ${item['nom'] ?? '-'}';
      case 'types_ad': return item['libelle'] ?? '';
      case 'types_soutien': return item['libelle'] ?? '';
      case 'roles': return '${item['prenom'] ?? ''} ${item['nom'] ?? ''}';
      case 'modules': return item['nom'] ?? '';
      default: return '';
    }
  }

  String _itemSubtitle(String key, Map<String, dynamic> item) {
    switch (key) {
      case 'parametres': return '${item['cle']} = ${item['valeur']} • ${item['categorie']}';
      case 'pays': return 'ISO: ${item['code_iso'] ?? '-'} • Tel: ${item['indicatif_tel'] ?? '-'}';
      case 'provinces': return 'Pays: ${item['pays__nom'] ?? '-'}';
      case 'cellules': return 'Pays: ${item['pays__nom'] ?? '-'}';
      case 'types_ad': return item['description'] ?? '';
      case 'types_soutien': return '${item['montant'] ?? 0} CAD • ${item['nombre_temoins_requis'] ?? 3} témoins';
      case 'roles': return item['email'] ?? '';
      case 'modules': return '${item['url'] ?? ''} • Ordre: ${item['ordre'] ?? 0}';
      default: return '';
    }
  }

  Widget? _itemTrailing(String key, Map<String, dynamic> item) {
    switch (key) {
      case 'parametres':
        return _typeBadge(item['type_valeur'] ?? 'STRING');
      case 'pays':
      case 'provinces':
        return _activeBadge(item['est_actif'] ?? false);
      case 'cellules':
        return _activeBadge(item['est_active'] ?? false);
      case 'types_ad':
      case 'types_soutien':
        return _activeBadge(item['est_actif'] ?? false);
      case 'roles':
        return _roleBadge(item['role'] ?? 'MEMBRE');
      case 'modules':
        return _activeBadge(item['visible_sidebar'] ?? false);
      default:
        return null;
    }
  }

  // ═══ Editable fields per section ═══
  Map<String, String> _editableFields(String key) {
    switch (key) {
      case 'parametres': return {'cle': 'Clé', 'libelle': 'Libellé', 'valeur': 'Valeur', 'type_valeur': 'Type (STRING/INTEGER/DECIMAL)', 'categorie': 'Catégorie'};
      case 'pays': return {'nom': 'Nom', 'code_iso': 'Code ISO', 'indicatif_tel': 'Indicatif téléphonique'};
      case 'provinces': return {'nom': 'Nom', 'pays_id': 'ID Pays'};
      case 'cellules': return {'code': 'Code', 'nom': 'Nom'};
      case 'types_ad': return {'libelle': 'Libellé', 'description': 'Description'};
      case 'types_soutien': return {'libelle': 'Libellé', 'montant': 'Montant (CAD)', 'nombre_temoins_requis': 'Témoins requis'};
      case 'roles': return {};
      case 'modules': return {'nom': 'Nom', 'url': 'URL', 'ordre': 'Ordre'};
      default: return {};
    }
  }

  // ═══ DIALOGS ═══
  void _showAddDialog() {
    final fields = _editableFields(_activeSection!);
    final ctrls = Map.fromEntries(fields.keys.map((k) => MapEntry(k, TextEditingController())));
    _showFormDialog('Nouveau', ctrls, fields, (data) async {
      if (_activeSection == 'types_soutien') {
        data['montant'] = double.tryParse('${data['montant']}') ?? 0;
        data['nombre_temoins_requis'] = int.tryParse('${data['nombre_temoins_requis']}') ?? 3;
      }
      await _apiCall(_activeSection!, 'create', data);
      _openSection(_activeSection!);
      _loadCounts();
    });
  }

  void _showEditDialog(Map<String, dynamic> item) {
    final key = _activeSection!;
    if (key == 'roles') { _showRoleDialog(item); return; }
    final fields = _editableFields(key);
    final ctrls = Map.fromEntries(fields.keys.map((k) =>
      MapEntry(k, TextEditingController(text: '${item[k] ?? ''}'))));
    _showFormDialog('Modifier', ctrls, fields, (data) async {
      if (key == 'types_soutien' && data.containsKey('montant')) {
        data['montant'] = double.tryParse('${data['montant']}') ?? 0;
      }
      await _apiCall(key, 'update', {...data, 'id': item['id']});
      _openSection(key);
    });
  }

  void _showFormDialog(String action, Map<String, TextEditingController> ctrls, Map<String, String> labels, Function(Map<String, dynamic>) onSave) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(action, style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
          const SizedBox(height: 16),
          ...labels.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              controller: ctrls[e.key],
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                labelText: e.value,
                labelStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                filled: true, fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          )),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, height: 46, child: ElevatedButton(
            onPressed: () {
              final data = Map.fromEntries(ctrls.entries.map((e) => MapEntry(e.key, e.value.text.trim())));
              Navigator.pop(ctx);
              onSave(data);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A3A5C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Sauvegarder', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          )),
        ]),
      ),
    );
  }

  void _showRoleDialog(Map<String, dynamic> item) {
    String role = item['role'] ?? 'MEMBRE';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Modifier le rôle', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('${item['prenom']} ${item['nom']}', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
          const SizedBox(height: 16),
          ...['MEMBRE', 'TRESORIER', 'SECRETAIRE', 'PRESIDENT', 'ADMIN'].map((r) => RadioListTile<String>(
            value: r, groupValue: role,
            title: Text(r, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
            onChanged: (v) => setS(() => role = v!),
            activeColor: const Color(0xFF1A3A5C), dense: true,
          )),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, height: 46, child: ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _apiCall('roles', 'update_role', {'membre_id': item['id'], 'role': role});
              _openSection('roles');
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A3A5C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Appliquer', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          )),
        ]),
      )),
    );
  }

  void _confirmDelete(Map<String, dynamic> item) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Supprimer ?', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
      content: Text('Cette action est irréversible.', style: GoogleFonts.inter(fontSize: 13)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await _apiCall(_activeSection!, 'delete', {'id': item['id']});
            _openSection(_activeSection!);
            _loadCounts();
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
          child: const Text('Supprimer'),
        ),
      ],
    ));
  }

  // ═══ WIDGETS UTILITAIRES ═══
  Widget _noAccess() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.lock_outline_rounded, size: 64, color: Color(0xFFCBD5E1)),
    const SizedBox(height: 16),
    Text('Accès réservé aux administrateurs', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
  ]));

  _Section _sectionFor(String key) => _sections.firstWhere((s) => s.key == key);

  Widget _typeBadge(String type) {
    final c = {'INTEGER': const Color(0xFF0EA5E9), 'DECIMAL': const Color(0xFF7C3AED), 'STRING': const Color(0xFF059669)}[type] ?? const Color(0xFF94A3B8);
    final l = {'INTEGER': 'Entier', 'DECIMAL': 'Décimal', 'STRING': 'Texte'}[type] ?? type;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(l, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: c)),
    );
  }

  Widget _activeBadge(bool a) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(color: (a ? const Color(0xFF059669) : const Color(0xFFDC2626)).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
    child: Text(a ? '✓' : '✗', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: a ? const Color(0xFF059669) : const Color(0xFFDC2626))),
  );

  Widget _roleBadge(String r) {
    final c = r == 'ADMIN' || r == 'PRESIDENT' ? const Color(0xFF7C3AED) : const Color(0xFF1A3A5C);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
      child: Text(r, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: c)),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) => Material(
    color: color.withValues(alpha: 0.06),
    borderRadius: BorderRadius.circular(7),
    child: InkWell(borderRadius: BorderRadius.circular(7), onTap: onTap,
      child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, size: 15, color: color))),
  );
}

class _Section {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  const _Section(this.key, this.label, this.icon, this.color);
}
