/// SEBC Mobile — Configuration API
class ApiConfig {
  // ═══ BASE URL — PRODUCTION ═══
  static const String baseUrl = 'https://sebc-dushigikirane.pro/api/mobile';

  // ═══ ENDPOINTS ═══
  // Auth
  static const String checkEmail = '$baseUrl/auth/check-email/';
  static const String login = '$baseUrl/auth/login/';
  static const String requestOtp = '$baseUrl/auth/request-otp/';
  static const String verifyOtp = '$baseUrl/auth/verify-otp/';
  static const String setPassword = '$baseUrl/auth/set-password/';
  static const String logout = '$baseUrl/auth/logout/';

  // Candidature
  static const String checkParrain = '$baseUrl/candidature/check-parrain/';
  static const String submitCandidature = '$baseUrl/candidature/submit/';

  // Membre
  static const String membreProfile = '$baseUrl/membre/profile/';
  static const String membreUpdateProfile = '$baseUrl/membre/update-profile/';
  static const String membreAyantsDroits = '$baseUrl/membre/ayants-droits/';
  static const String membreDocuments = '$baseUrl/membre/documents/';
  static const String validerFilleul = '$baseUrl/membre/valider-filleul/';
  static const String relancerParrain = '$baseUrl/membre/relancer-parrain/';

  // Communication
  static const String commContacts = '$baseUrl/communication/contacts/';
  static const String commThreads = '$baseUrl/communication/threads/';
  static const String commMessages = '$baseUrl/communication/messages/';
  static const String commSend = '$baseUrl/communication/send/';
  static const String commSendFile = '$baseUrl/communication/send-file/';
  static const String commUnread = '$baseUrl/communication/unread/';
  static const String commVisio = '$baseUrl/communication/visio/';
  static const String commGroupCreate = '$baseUrl/communication/groups/create/';
  static const String commGroupDelete = '$baseUrl/communication/groups/delete/';

  // Meetings
  static const String meetingsList = '$baseUrl/communication/meetings/';
  static const String meetingsCreate = '$baseUrl/communication/meetings/create/';
  static const String meetingsCancel = '$baseUrl/communication/meetings/cancel/';
  static const String meetingsJoin = '$baseUrl/communication/meetings/join/';

  // Reference Data
  static const String refData = '$baseUrl/ref-data/';
}
