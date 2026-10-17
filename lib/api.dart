import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient get sb => Supabase.instance.client;

typedef Json = Map<String, dynamic>;

/// Perfil do utilizador autenticado (locatário).
class Me {
  Me({required this.uid, required this.authUid, required this.email, this.name = '', this.role = '', this.phone = '', this.apartNum = '', this.floor, this.status = '', this.buildingId, this.building, this.tenantRowId});
  final String uid; // user_id usado nas tabelas (texto)
  final String authUid;
  final String email;
  String name, role, phone, apartNum, status;
  int? floor, buildingId, tenantRowId;
  Json? building;
  bool get approved => status == 'Accepté';
  String get buildingName => (building?['description'] ?? building?['address'] ?? '').toString();
  String get managerId => (building?['manager_id'] ?? '').toString();
}

class Api {
  /// O user_id das tabelas é texto. Contas migradas do Firebase usam a tabela auth_links (opcional).
  static Future<String> legacyUid(String authUid) async {
    try {
      final r = await sb.from('auth_links').select('legacy_user_id').eq('auth_uid', authUid).maybeSingle();
      return (r?['legacy_user_id'] as String?) ?? authUid;
    } catch (_) {
      return authUid;
    }
  }

  static Future<Me?> loadMe() async {
    final u = sb.auth.currentUser;
    if (u == null) return null;
    final uid = await legacyUid(u.id);
    final login = await sb.from('login_view').select().eq('user_id', uid).limit(1);
    final me = Me(uid: uid, authUid: u.id, email: u.email ?? '');
    if (login.isNotEmpty) {
      me.role = (login.first['role'] ?? '').toString();
      me.name = (login.first['name'] ?? '').toString();
    }
    final t = await sb.from('tenants').select().eq('user_id', uid).limit(1);
    if (t.isNotEmpty) {
      final r = t.first;
      me.name = (r['full_name'] ?? me.name).toString();
      me.phone = (r['phone'] ?? '').toString();
      me.apartNum = (r['apartNum'] ?? '').toString();
      me.floor = r['floor'] as int?;
      me.status = (r['statusAproved'] ?? '').toString();
      me.buildingId = r['apartment_id'] as int?;
      if (me.buildingId != null) {
        final b = await sb.from('batiment').select().eq('id', me.buildingId!).limit(1);
        if (b.isNotEmpty) me.building = b.first;
      }
    }
    return me;
  }

  /// Verifica o código de inscrição e devolve os dados do edifício (ou null se o código não existe).
  /// Usa a função segura do servidor; se ainda não existir (antes das regras de segurança), lê as tabelas diretamente.
  static Future<Json?> validateCode(String code) async {
    final raw = code.trim();
    // os códigos curtos são em maiúsculas e sem espaços/hífenes; os antigos (UUID) mantêm-se como estão
    final short = raw.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
    for (final c in {raw, short}) {
      if (c.isEmpty) continue;
      try {
        final r = await sb.rpc('validate_registration_code', params: {'p_code': c});
        if (r is Map) return Map<String, dynamic>.from(r);
      } catch (_) {/* função ainda não instalada */}
      final r = await sb.from('CodeInscription').select('apartID,title').eq('uuidRandom', c).maybeSingle();
      if (r != null) {
        final b = await sb.from('batiment').select().eq('id', r['apartID']).maybeSingle();
        return {...?b, 'apartID': r['apartID'], 'codeTitle': r['title']};
      }
    }
    return null;
  }

  /// Envia imagens para o Storage e devolve os URLs públicos.
  static Future<List<String>> uploadImages(String bucket, List<XFile> files) async {
    final urls = <String>[];
    for (final f in files) {
      final Uint8List bytes = await f.readAsBytes();
      final ext = f.name.contains('.') ? f.name.split('.').last.toLowerCase() : 'jpg';
      final path = '${DateTime.now().millisecondsSinceEpoch}_${urls.length}.$ext';
      await sb.storage.from(bucket).uploadBinary(path, bytes, fileOptions: FileOptions(contentType: f.mimeType ?? 'image/jpeg'));
      urls.add(sb.storage.from(bucket).getPublicUrl(path));
    }
    return urls;
  }

  /// Serviços de servidor (e-mail, push, IA). Falham em silêncio se ainda não estiverem publicados.
  static Future<Map<String, dynamic>?> edge(String fn, Map<String, dynamic> body) async {
    try {
      final r = await sb.functions.invoke(fn, body: body);
      return r.data is Map ? Map<String, dynamic>.from(r.data as Map) : {'data': r.data};
    } catch (_) {
      return null;
    }
  }

  static Future<void> email(String template, String? to, String? name, Map<String, String> params) async {
    if (to == null || to.isEmpty) return;
    await edge('send-email', {'template': template, 'to': to, 'name': name, 'params': params});
  }

  /// Gestor do edifício do locatário (para avisos por e-mail).
  static Future<Json?> managerOf(Me me) async {
    if (me.managerId.isEmpty) return null;
    final r = await sb.from('managers').select().eq('user_id', me.managerId).maybeSingle();
    return r;
  }

  /// Cria notificações dentro da app (tabela "Notification New"), como na app original.
  static Future<void> notify(Iterable<String> userIds, String title, String description, {String type = 'null'}) async {
    final ids = userIds.where((e) => e.isNotEmpty).toSet();
    if (ids.isEmpty) return;
    try {
      await sb.from('Notification New').insert([
        for (final u in ids) {'type': type, 'userid': u, 'Tittle': title, 'Description': description, 'Read': 'Unread'},
      ]);
    } catch (_) {}
    // push no telemóvel dos destinatários
    edge('send-push', {'userIds': ids.toList(), 'title': title, 'message': description, 'data': {'type': type}});
  }

  static String fmtErr(Object e) {
    if (e is AuthException) return e.message;
    if (e is PostgrestException) return e.message;
    return e.toString().replaceFirst('Exception: ', '');
  }
}
