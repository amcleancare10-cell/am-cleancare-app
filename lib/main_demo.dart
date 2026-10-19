// Versão de DEMONSTRAÇÃO (só para ver o design e testar): corre a app verdadeira com um "servidor" falso,
// sem nenhuma ligação ao Supabase. Nada é gravado em lado nenhum. Não faz parte da app publicada.
//   flutter run -d chrome -t lib/main_demo.dart        ou        flutter build web -t lib/main_demo.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';
import 'main.dart';
import 'l10n.dart';

String _b64(Object o) => base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');

final _now = DateTime.now().toUtc();
String _ago(int minutes) => _now.subtract(Duration(minutes: minutes)).toIso8601String();

final Map<String, List<Map<String, dynamic>>> _db = {
  'login_view': [{'user_id': 'T1', 'role': 'tenant', 'name': 'Ana Silva', 'email': 'ana@exemple.ch', 'phone': '+41 79 123 45 67'}],
  'tenants': [{'user_id': 'T1', 'apartment_id': 37, 'full_name': 'Ana Silva', 'email': 'ana@exemple.ch', 'phone': '+41 79 123 45 67', 'apartNum': '3B', 'floor': 3, 'statusAproved': 'Accepté', 'created_at': '2023-01-12T10:00:00Z'}],
  'batiment': [{'id': 37, 'address': 'Avenue des Alpes 12, 1020 Renens', 'description': 'Résidence Les Fleurs', 'manager_id': 'M1', 'floors': 5, 'imgBatiment': 'http://localhost:8800/demo/immeuble1.png', 'whatsapp_group': 'https://chat.whatsapp.com/exemple'}],
  'managers': [{'user_id': 'M1', 'manager_name': 'Sophie Exemple', 'agency_name': 'Gérance Modèle SA', 'email': 'gerance@exemple.ch', 'phone': '+41 21 000 00 01', 'agency_img': 'http://localhost:8800/demo/logo-gerance.png', 'team_phone': '+41 79 000 00 02', 'team_whatsapp': '+41 79 000 00 02'}],
  'tickets': [
    {'id': 101, 'title': 'Fuite sous l\'évier', 'description': 'Il y a de l\'eau sous l\'évier de la cuisine depuis ce matin.', 'status': 'En Cours', 'created_at': _ago(60 * 5), 'tenant_id': 'T1', 'photos': []},
    {'id': 98, 'title': 'Ampoule du couloir', 'description': 'Le couloir du 3e étage est sombre.', 'status': 'En Attente', 'created_at': _ago(60 * 30), 'tenant_id': 'T1', 'photos': []},
    {'id': 90, 'title': 'Porte de la cave', 'description': 'La serrure est cassée.', 'status': 'Fermé', 'created_at': _ago(60 * 24 * 12), 'tenant_id': 'T1', 'photos': []},
  ],
  'ticket_chats': [
    {'id': 1, 'ticket_id': 101, 'author_id': 'T1', 'author_name': 'Ana Silva', 'message': 'Bonjour, il y a une fuite sous l\'évier.', 'sent_at': _ago(290)},
    {'id': 2, 'ticket_id': 101, 'author_id': 'M1', 'author_name': 'Sophie Exemple', 'message': 'Bonjour Ana, un plombier passera demain matin.', 'sent_at': _ago(240)},
  ],
  'last_ticket_message_view': [
    {'ticket_id': 101, 'author_name': 'Sophie Exemple', 'message': 'Bonjour Ana, un plombier passera demain matin.', 'sent_at': _ago(240), 'status': 'En Cours', 'ticket_creator_id': 'T1'},
    {'ticket_id': 98, 'author_name': 'Ana Silva', 'message': 'Le couloir du 3e étage est sombre.', 'sent_at': _ago(60 * 30), 'status': 'En Attente', 'ticket_creator_id': 'T1'},
  ],
  'Notification New': [
    {'id': 1, 'userid': 'T1', 'Tittle': 'Maintenance programmée', 'Description': 'Nettoyage des vitres prévu le 15 juin', 'Read': 'Unread', 'created_at': _ago(120), 'type': 'All'},
    {'id': 2, 'userid': 'T1', 'Tittle': 'Colis reçu', 'Description': 'Votre colis est disponible à la loge', 'Read': 'Unread', 'created_at': _ago(300), 'type': 'null'},
    {'id': 3, 'userid': 'T1', 'Tittle': 'Ticket #90', 'Description': 'Votre ticket a été fermé.', 'Read': 'Read', 'created_at': _ago(60 * 24 * 11), 'type': 'null'},
  ],
  'announcements': [
    {'id': 1, 'description': 'Vélo enfant 16 pouces, très bon état. À retirer au 2e étage.', 'photo': [], 'price': 40, 'free': false, 'contact': '+41 79 111 22 33', 'created_at': _ago(180), 'apartamentID': 37, 'tenantID': 'T1'},
    {'id': 2, 'description': 'Je donne une table basse en bois et deux chaises.', 'photo': [], 'price': 0, 'free': true, 'contact': 'marie@exemple.ch', 'created_at': _ago(60 * 26), 'apartamentID': 37, 'tenantID': 'T9'},
  ],
  'announcements_likes': [{'announcementsID': 1, 'user_ID': 'T1'}, {'announcementsID': 1, 'user_ID': 'T9'}, {'announcementsID': 2, 'user_ID': 'T1'}],
  'announcements_chat': [{'announcementsID': 1}, {'announcementsID': 1}],
  'codesReduction': [
    {'id': 1, 'title': '-15 % nettoyage', 'code': 'AMCLEAN15', 'description': 'Réduction sur tous les services de nettoyage.', 'img': '', 'created_at': _ago(500)},
    {'id': 2, 'title': 'Pressing du quartier', 'code': 'PRESS10', 'description': '10 % sur votre premier dépôt.', 'img': '', 'created_at': _ago(900)},
  ],
  'ticket_event': [
    {'id': 1, 'ticket_id': 101, 'step': 'analyse', 'note': null, 'planned_at': null, 'created_at': _ago(60 * 4)},
    {'id': 2, 'ticket_id': 101, 'step': 'planifie', 'note': "Merci de laisser l'accès à la cuisine.", 'planned_at': _now.add(const Duration(days: 1, hours: 9)).toIso8601String(), 'created_at': _ago(60 * 3)},
  ],
  'buanderie': [
    {'id': 1, 'batiment_id': 37, 'nom': 'Entrées 1 à 3', 'machines': ['Lave-linge 1', 'Lave-linge 2', 'Séchoir'], 'jours': [1, 2, 3, 4, 5], 'heure_debut': 7, 'heure_fin': 22, 'duree_creneau': 5, 'regles': 'Merci de laisser la buanderie propre et de retirer votre linge à la fin de votre créneau. Silence après 22 h.', 'batiments_acces': [], 'actif': true, 'ordre': 0},
    {'id': 2, 'batiment_id': 37, 'nom': 'Entrées 4 à 6', 'machines': ['Lave-linge', 'Séchoir'], 'jours': [1, 2, 3, 4, 5], 'heure_debut': 7, 'heure_fin': 22, 'duree_creneau': 5, 'regles': '', 'batiments_acces': [], 'actif': true, 'ordre': 1},
  ],
  'buanderie_planning': [
    {'id': 1, 'buanderie_id': 1, 'jour': 1, 'debut': 7, 'machine': 'Lave-linge 1', 'apartment_num': '1A'},
    {'id': 2, 'buanderie_id': 1, 'jour': 1, 'debut': 12, 'machine': 'Lave-linge 1', 'apartment_num': '2B'},
    {'id': 3, 'buanderie_id': 1, 'jour': 1, 'debut': 17, 'machine': 'Lave-linge 2', 'apartment_num': '4A'},
    {'id': 4, 'buanderie_id': 1, 'jour': 2, 'debut': 7, 'machine': 'Lave-linge 1', 'apartment_num': '5C'},
    {'id': 5, 'buanderie_id': 1, 'jour': 2, 'debut': 12, 'machine': 'Lave-linge 1', 'apartment_num': '3B'},
    {'id': 6, 'buanderie_id': 1, 'jour': 2, 'debut': 12, 'machine': 'Séchoir', 'apartment_num': '3B'},
    {'id': 7, 'buanderie_id': 1, 'jour': 2, 'debut': 17, 'machine': 'Lave-linge 2', 'apartment_num': '1A'},
    {'id': 8, 'buanderie_id': 1, 'jour': 3, 'debut': 7, 'machine': 'Lave-linge 2', 'apartment_num': '2B'},
    {'id': 9, 'buanderie_id': 1, 'jour': 3, 'debut': 12, 'machine': 'Lave-linge 1', 'apartment_num': '4A'},
    {'id': 10, 'buanderie_id': 1, 'jour': 3, 'debut': 17, 'machine': 'Séchoir', 'apartment_num': '5C'},
    {'id': 11, 'buanderie_id': 1, 'jour': 4, 'debut': 7, 'machine': 'Lave-linge 1', 'apartment_num': '1A'},
    {'id': 12, 'buanderie_id': 1, 'jour': 4, 'debut': 12, 'machine': 'Lave-linge 2', 'apartment_num': '5C'},
    {'id': 13, 'buanderie_id': 1, 'jour': 4, 'debut': 17, 'machine': 'Lave-linge 1', 'apartment_num': '2B'},
    {'id': 14, 'buanderie_id': 1, 'jour': 5, 'debut': 7, 'machine': 'Lave-linge 1', 'apartment_num': '4A'},
    {'id': 15, 'buanderie_id': 1, 'jour': 5, 'debut': 12, 'machine': 'Lave-linge 2', 'apartment_num': '2B'},
  ],
  'batiment_presence': [
    {'id': 1, 'batiment_id': 37, 'jour': 1, 'debut': '08:00', 'fin': '12:00'},
    {'id': 2, 'batiment_id': 37, 'jour': 3, 'debut': '14:00', 'fin': '18:00'},
    {'id': 3, 'batiment_id': 37, 'jour': 5, 'debut': '08:00', 'fin': '12:00'},
  ],
  'locations': [{'id': 1, 'description': 'Cuisine', 'categorie': 'appartement'}, {'id': 2, 'description': 'Salle de bain', 'categorie': 'appartement'}, {'id': 3, 'description': 'Salle de séjour', 'categorie': 'appartement'}, {'id': 11, 'description': 'Cave', 'categorie': 'immeuble'}, {'id': 12, 'description': 'Jardin', 'categorie': 'immeuble'}, {'id': 13, 'description': 'Parking et garage', 'categorie': 'immeuble'}, {'id': 14, 'description': 'Escalier et hall', 'categorie': 'immeuble'}, {'id': 15, 'description': 'Ascenseur', 'categorie': 'immeuble'}, {'id': 16, 'description': 'Buanderie', 'categorie': 'immeuble'}, {'id': 17, 'description': 'Façade et toiture', 'categorie': 'immeuble'}, {'id': 18, 'description': 'Poubelles et vélos', 'categorie': 'immeuble'}],
  'problem_types': [{'id': 1, 'name': 'Fuite', 'locationID': 1}, {'id': 2, 'name': 'Électricité', 'locationID': 1}, {'id': 3, 'name': 'Humidité', 'locationID': 2}, {'id': 31, 'name': 'Porte et serrure', 'locationID': 11}, {'id': 32, 'name': 'Humidité / eau', 'locationID': 11}, {'id': 33, 'name': 'Éclairage', 'locationID': 11}, {'id': 34, 'name': 'Propreté / encombrement', 'locationID': 11}, {'id': 35, 'name': 'Nuisibles', 'locationID': 11}],
  'admin_chats': [
    {'id': 1, 'author_id': 'T1', 'user_id': 'M1', 'message': 'Bonjour, puis-je avoir un double de clé ?', 'sent_at': _ago(400)},
    {'id': 2, 'author_id': 'M1', 'user_id': 'T1', 'message': 'Bien sûr, passez à la loge demain.', 'sent_at': _ago(380)},
  ],
};

http.Response _json(Object body, [int code = 200]) => http.Response(jsonEncode(body), code, headers: {'content-type': 'application/json'});

Future<http.Response> _handle(http.Request r) async {
  final res = await _route(r);
  // o cliente Postgrest lê response.request!.method
  return http.Response.bytes(res.bodyBytes, res.statusCode, headers: res.headers, request: r);
}

Future<http.Response> _route(http.Request r) async {
  final path = r.url.path;
  if (path == '/auth/v1/user') return _json(_user());
  if (path.startsWith('/auth/')) return _json({'access_token': _jwt(), 'refresh_token': 'demo', 'expires_in': 86400, 'token_type': 'bearer', 'user': _user()});
  if (path.startsWith('/functions/v1/ai-chat')) {
    String lg = 'fr';
    try { lg = '${(jsonDecode(r.body) as Map)['lang'] ?? 'fr'}'; } catch (_) {}
    const R = {
      'fr': "Je suis désolé pour cette fuite. Où se situe-t-elle exactement ? Si c'est urgent, contactez-nous sur WhatsApp ; sinon, ouvrez un Ticket pour que l'équipe intervienne.",
      'en': "I'm sorry about that leak. Where exactly is it? If it is urgent, contact us on WhatsApp; otherwise, open a Ticket so the team can step in.",
      'de': "Das tut mir leid mit dem Leck. Wo genau befindet es sich? Wenn es dringend ist, schreiben Sie uns per WhatsApp; sonst eröffnen Sie ein Ticket, damit das Team eingreift.",
      'pt': "Lamento a fuga de água. Onde fica exatamente? Se for urgente, contacte-nos por WhatsApp; caso contrário, abra um Ticket para a equipa intervir.",
    };
    return _json({'reply': R[lg] ?? R['fr']});
  }
  if (path.startsWith('/functions/')) return _json({'ok': true});
  if (path.startsWith('/storage/')) return _json({'Key': 'demo'});
  if (path.startsWith('/rest/v1/rpc/')) return _json([]);
  if (path.startsWith('/rest/v1/')) {
    final table = Uri.decodeComponent(path.substring('/rest/v1/'.length));
    final rows = _db[table];
    if (rows == null) return _json({'message': 'not found'}, 404);
    if (r.method == 'GET' || r.method == 'HEAD') {
      if ((r.headers['accept'] ?? '').contains('vnd.pgrst.object')) return rows.isEmpty ? _json({'message': 'none'}, 406) : _json(rows.first);
      return _json(rows);
    }
    // gravações: devolve a linha enviada (para .select().single()) sem guardar nada
    Object body = {};
    try { body = jsonDecode(r.body); } catch (_) {}
    final row = body is List ? (body.isEmpty ? {} : body.first) : body;
    final out = {'id': 999, ...(row as Map)};
    return (r.headers['accept'] ?? '').contains('vnd.pgrst.object') ? _json(out, 201) : _json([out], 201);
  }
  return _json({});
}

Map<String, dynamic> _user() => {'id': 'T1', 'aud': 'authenticated', 'role': 'authenticated', 'email': 'ana@exemple.ch', 'app_metadata': {}, 'user_metadata': {}, 'created_at': '2023-01-12T10:00:00Z', 'last_sign_in_at': DateTime.now().toIso8601String()};

String _jwt() {
  final exp = DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch ~/ 1000;
  return '${_b64({'alg': 'HS256', 'typ': 'JWT'})}.${_b64({'sub': 'T1', 'role': 'authenticated', 'exp': exp, 'aud': 'authenticated'})}.demo';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: 'https://demo.supabase.co', publishableKey: AppConfig.anonKey, httpClient: MockClient(_handle));
  final exp = DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch ~/ 1000;
  if (!Uri.base.queryParameters.containsKey('login')) await Supabase.instance.client.auth.recoverSession(jsonEncode({'access_token': _jwt(), 'refresh_token': 'demo', 'expires_in': 86400, 'expires_at': exp, 'token_type': 'bearer', 'user': _user()}));
  await L.load();
  runApp(const App());
}
