import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

/// Chat Screen — Conversation WhatsApp-style
class ChatScreen extends StatefulWidget {
  final Contact contact;
  const ChatScreen({super.key, required this.contact});
  @override State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _api = ApiService();
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<ChatMessage> _messages = [];
  bool _loading = true;
  File? _pendingFile;
  String? _pendingFileName;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    final r = await _api.getMessages(widget.contact.threadId);
    if (r['success'] == true) {
      setState(() {
        _messages = (r['messages'] as List? ?? []).map((m) => ChatMessage.fromJson(m)).toList();
        _loading = false;
      });
      _scrollToBottom();
    } else {
      setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty && _pendingFile == null) return;
    _msgCtrl.clear();

    // Optimistic UI
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    setState(() {
      _messages.add(ChatMessage(
        id: -1, senderId: AuthProvider.instance.membre?.id ?? 0,
        senderName: AuthProvider.instance.membre?.nomComplet ?? '',
        message: text.isNotEmpty ? text : '📎 ${_pendingFileName ?? 'Fichier'}',
        createdAt: '', time: timeStr,
      ));
    });
    _scrollToBottom();

    if (_pendingFile != null) {
      final fields = {
        'thread_id': widget.contact.threadId,
        'scope': widget.contact.scope,
        'message': text,
        if (widget.contact.membreId != null) 'target_membre_id': '${widget.contact.membreId}',
        if (widget.contact.celluleId != null) 'target_cellule_id': '${widget.contact.celluleId}',
        if (widget.contact.groupId != null) 'target_group_id': '${widget.contact.groupId}',
        if (widget.contact.typeMembreId != null) 'target_type_membre_id': '${widget.contact.typeMembreId}',
      };
      await _api.sendFileMessage(_pendingFile!, fields);
      setState(() { _pendingFile = null; _pendingFileName = null; });
    } else {
      await _api.sendMessage({
        'thread_id': widget.contact.threadId,
        'scope': widget.contact.scope,
        'message': text,
        'target_membre_id': widget.contact.membreId,
        'target_cellule_id': widget.contact.celluleId,
        'target_group_id': widget.contact.groupId,
        'target_type_membre_id': widget.contact.typeMembreId,
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: false);
    if (result != null && result.files.isNotEmpty) {
      final f = result.files.first;
      if (f.path == null) return;
      if (f.size > 10 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fichier trop volumineux (max 10MB)')));
        return;
      }
      setState(() { _pendingFile = File(f.path!); _pendingFileName = f.name; });
    }
  }

  Future<void> _startVisio() async {
    final r = await _api.startVisio(widget.contact.threadId, widget.contact.name);
    if (r['success'] == true) {
      final url = r['share_link'] ?? r['jitsi_url'];
      // Send auto message
      await _api.sendMessage({
        'thread_id': widget.contact.threadId,
        'scope': widget.contact.scope,
        'message': '📹 Appel vidéo démarré — Rejoignez ici : $url',
        'target_membre_id': widget.contact.membreId,
      });
      if (url != null) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      _loadMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    final membreId = AuthProvider.instance.membre?.id ?? 0;
    final color = SEBCColors.avatarColors[widget.contact.colorIndex % SEBCColors.avatarColors.length];

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 30,
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.8), shape: BoxShape.circle),
            child: const Icon(Icons.person, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.contact.name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(widget.contact.sub, style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.videocam_rounded), onPressed: _startVisio, tooltip: 'Appel vidéo'),
        ],
      ),
      body: Container(
        color: SEBCColors.chatBg,
        child: Column(children: [
          // Messages
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.chat_bubble_outline, size: 60, color: SEBCColors.textTertiary.withValues(alpha: 0.3)),
                    const SizedBox(height: 8),
                    Text('Démarrez une conversation', style: GoogleFonts.inter(color: SEBCColors.textSecondary, fontSize: 14)),
                  ]))
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final msg = _messages[i];
                      final isSent = msg.senderId == membreId;
                      String? prevDate = i > 0 ? _messages[i - 1].createdAt.split(' ').first : null;
                      String curDate = msg.createdAt.split(' ').first;
                      bool showDateSep = prevDate != curDate && curDate.isNotEmpty;

                      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        if (showDateSep) Center(child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(8)),
                          child: Text(curDate, style: GoogleFonts.inter(fontSize: 11, color: SEBCColors.textSecondary, fontWeight: FontWeight.w600)),
                        )),
                        Align(
                          alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
                            decoration: BoxDecoration(
                              color: isSent ? SEBCColors.chatSent : SEBCColors.chatRecv,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(12), topRight: const Radius.circular(12),
                                bottomLeft: Radius.circular(isSent ? 12 : 3),
                                bottomRight: Radius.circular(isSent ? 3 : 12),
                              ),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 3)],
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              if (!isSent && msg.senderName.isNotEmpty) Text(msg.senderName,
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: SEBCColors.primary)),
                              if (msg.subject != null && msg.subject!.isNotEmpty) Text('📌 ${msg.subject!}',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: SEBCColors.primary)),
                              // Attachment
                              if (msg.attachment != null) _AttachmentWidget(attachment: msg.attachment!),
                              if (msg.message.isNotEmpty && !msg.message.startsWith('📎'))
                                Padding(padding: const EdgeInsets.only(top: 2), child: Text(msg.message,
                                  style: GoogleFonts.inter(fontSize: 13.5, color: SEBCColors.textPrimary, height: 1.4))),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Text(msg.time, style: GoogleFonts.inter(fontSize: 10, color: SEBCColors.textTertiary)),
                                    if (isSent) ...[
                                      const SizedBox(width: 3),
                                      Icon(Icons.done_all, size: 13, color: Colors.blue.shade300),
                                    ],
                                  ]),
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ]);
                    },
                  ),
          ),

          // Attachment preview
          if (_pendingFile != null) Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: SEBCColors.surfaceVariant,
            child: Row(children: [
              const Icon(Icons.attach_file, size: 18, color: SEBCColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(_pendingFileName ?? '', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
              GestureDetector(
                onTap: () => setState(() { _pendingFile = null; _pendingFileName = null; }),
                child: const Icon(Icons.close, size: 18, color: SEBCColors.error),
              ),
            ]),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            color: const Color(0xFFF0F2F5),
            child: SafeArea(
              top: false,
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.attach_file_rounded, color: SEBCColors.textSecondary),
                  onPressed: _pickFile,
                  iconSize: 22,
                ),
                Expanded(child: TextField(
                  controller: _msgCtrl,
                  decoration: InputDecoration(
                    hintText: 'Écrivez un message...',
                    filled: true, fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                  textInputAction: TextInputAction.send,
                )),
                const SizedBox(width: 6),
                Container(
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: SEBCColors.primaryGradient),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ═══ Attachment Widget ═══
class _AttachmentWidget extends StatelessWidget {
  final Map<String, dynamic> attachment;
  const _AttachmentWidget({required this.attachment});

  @override
  Widget build(BuildContext context) {
    final type = attachment['type'] ?? 'file';
    final name = attachment['name'] ?? 'Fichier';
    final url = attachment['url'] ?? '';

    if (type == 'image' && url.isNotEmpty) {
      return GestureDetector(
        onTap: () => _openUrl(url),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(url, width: 200, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fileBlock(name, type)),
        ),
      );
    }
    return GestureDetector(onTap: () => _openUrl(url), child: _fileBlock(name, type));
  }

  Widget _fileBlock(String name, String type) {
    IconData icon = Icons.insert_drive_file;
    Color color = SEBCColors.textSecondary;
    if (type == 'pdf') { icon = Icons.picture_as_pdf; color = SEBCColors.error; }
    else if (type == 'document') { icon = Icons.description; color = SEBCColors.info; }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 8),
        Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('Cliquez pour ouvrir', style: GoogleFonts.inter(fontSize: 10, color: SEBCColors.textTertiary)),
        ])),
        const SizedBox(width: 6),
        const Icon(Icons.download_rounded, size: 18, color: SEBCColors.textTertiary),
      ]),
    );
  }

  void _openUrl(String url) async {
    if (url.isEmpty) return;
    final fullUrl = url.startsWith('http') ? url : 'https://sebc-dushigikirane.pro$url';
    final uri = Uri.parse(fullUrl);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
