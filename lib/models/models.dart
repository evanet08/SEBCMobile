/// SEBC Mobile — Models
class Membre {
  final int id;
  final String nom;
  final String prenom;
  final String email;
  final String? telephone;
  final String? telephoneCanada;
  final String? ville;
  final String? celluleCode;
  final String? typeMembre;
  final String statut;
  final String role;
  final bool estActif;
  final bool isGestionnaire;

  Membre({
    required this.id, required this.nom, required this.prenom,
    required this.email, this.telephone, this.telephoneCanada,
    this.ville, this.celluleCode, this.typeMembre,
    required this.statut, required this.role, required this.estActif,
    this.isGestionnaire = false,
  });

  String get nomComplet => '$prenom $nom';

  factory Membre.fromJson(Map<String, dynamic> j) => Membre(
    id: j['id'] ?? 0,
    nom: j['nom'] ?? '',
    prenom: j['prenom'] ?? '',
    email: j['email'] ?? '',
    telephone: j['telephone'],
    telephoneCanada: j['telephone_canada'],
    ville: j['ville'],
    celluleCode: j['cellule_code'],
    typeMembre: j['type_membre'],
    statut: j['statut'] ?? 'EN_ATTENTE',
    role: j['role'] ?? 'MEMBRE',
    estActif: j['est_actif'] ?? true,
    isGestionnaire: j['is_gestionnaire'] ?? false,
  );
}

class Contact {
  final String id;
  final String type; // individual, national_group, general_group, cellule, custom_group, type_membre
  final String name;
  final String sub;
  final String scope;
  final int? membreId;
  final int? celluleId;
  final int? groupId;
  final int? typeMembreId;
  final String? icon;
  final int colorIndex;
  int unread;

  Contact({
    required this.id, required this.type, required this.name,
    required this.sub, required this.scope, this.membreId,
    this.celluleId, this.groupId, this.typeMembreId,
    this.icon, this.colorIndex = 0, this.unread = 0,
  });

  String get threadId {
    switch (type) {
      case 'national_group': return 'national';
      case 'general_group': return 'general';
      case 'cellule': return 'cell_$celluleId';
      case 'custom_group': return 'cgrp_$groupId';
      case 'type_membre': return 'type_$typeMembreId';
      case 'individual':
        final minId = membreId! < _currentMembreId ? membreId! : _currentMembreId;
        final maxId = membreId! > _currentMembreId ? membreId! : _currentMembreId;
        return 'mbr_${minId}_$maxId';
      default: return 'unknown_$id';
    }
  }

  static int _currentMembreId = 0;
  static void setCurrentMembreId(int id) => _currentMembreId = id;
}

class ChatMessage {
  final int id;
  final int senderId;
  final String senderName;
  final String message;
  final String? subject;
  final String createdAt;
  final String time;
  final Map<String, dynamic>? attachment;

  ChatMessage({
    required this.id, required this.senderId, required this.senderName,
    required this.message, this.subject, required this.createdAt,
    required this.time, this.attachment,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id: j['id'] ?? 0,
    senderId: j['sender_id'] ?? 0,
    senderName: j['sender_name'] ?? '',
    message: j['message'] ?? '',
    subject: j['subject'],
    createdAt: j['created_at'] ?? '',
    time: j['time'] ?? '',
    attachment: j['attachment'],
  );
}

class Meeting {
  final int id;
  final String title;
  final String? description;
  final String roomName;
  final String shareUrl;
  final String status;
  final String scheduledAt;
  final String scheduledDisplay;
  final int durationMinutes;
  final int nInvitees;
  final bool isOwner;
  final String creatorName;

  Meeting({
    required this.id, required this.title, this.description,
    required this.roomName, required this.shareUrl, required this.status,
    required this.scheduledAt, required this.scheduledDisplay,
    required this.durationMinutes, required this.nInvitees,
    required this.isOwner, required this.creatorName,
  });

  factory Meeting.fromJson(Map<String, dynamic> j) => Meeting(
    id: j['id'] ?? 0,
    title: j['title'] ?? '',
    description: j['description'],
    roomName: j['room_name'] ?? '',
    shareUrl: j['share_url'] ?? '',
    status: j['status'] ?? 'scheduled',
    scheduledAt: j['scheduled_at'] ?? '',
    scheduledDisplay: j['scheduled_display'] ?? '',
    durationMinutes: j['duration_minutes'] ?? 60,
    nInvitees: j['n_invitees'] ?? 0,
    isOwner: j['is_owner'] ?? false,
    creatorName: j['creator_name'] ?? '',
  );
}

class AyantDroit {
  final int id;
  final String nom;
  final String prenom;
  final String typeLien;
  final bool estApprouve;

  AyantDroit({
    required this.id, required this.nom, required this.prenom,
    required this.typeLien, this.estApprouve = false,
  });

  factory AyantDroit.fromJson(Map<String, dynamic> j) => AyantDroit(
    id: j['id'] ?? 0,
    nom: j['nom'] ?? '',
    prenom: j['prenom'] ?? '',
    typeLien: j['type_lien'] ?? '',
    estApprouve: j['est_approuve'] ?? false,
  );
}
