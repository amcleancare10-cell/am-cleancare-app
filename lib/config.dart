/// Configuração da app. A chave "anon" é pública (a mesma da app original).
/// Pode ser definida no código ou ao compilar: --dart-define=SUPABASE_ANON_KEY=...
class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://uxxjvwvqhaeepmmdkior.supabase.co');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV4eGp2d3ZxaGFlZXBtbWRraW9yIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIzMTA4NDUsImV4cCI6MjA1Nzg4Njg0NX0.JyVxb5ad1p9fIJF8INjbbRcRi4mA5CFZYM36e_1lGLE');

  // Marca: para reaproveitar a app noutra gerência basta mudar estas linhas (e o ícone em assets).
  static const appName = 'AM Clean Care';
  // Atualização SEMPRE pelas lojas. `buildNumber` sobe em cada versão nova; o número em apk/version.json do plugin só sobe DEPOIS de a versão estar publicada nas lojas.
  static const buildNumber = 109;
  static const updateInfoUrl = 'https://amcleancare.ch/apk/version.json';
  static const playStoreUrl = 'https://play.google.com/store/apps/details?id=com.amcleancare.propertyissues';
  static const appStoreUrl = 'https://apps.apple.com/app/am-cleancare/id6756571666';
  static const supportEmail = 'info@ambox.ch';
  static const logoAsset = ''; // ex.: assets/logo.png
  static const webPanelUrl = 'amcleancare.ch/gerance';

  // Conciergerie (os mesmos contactos da app original)
  static const phoneConcierge = '+41 78 329 38 49';
  static const phoneGerance = ''; // se vazio usa o telefone do gestor do edifício
  static const whatsappUrl = 'https://wa.me/41783293849?text=Bonjour%2C%20je%20souhaiterais%20faire%20appel%20au%20service%20de%20conciergerie.';

  // Ajuda da lavandaria (os mesmos links da app original)
  static const helpGuideUrl = 'https://ambox.ch/guides-daide/';
  static const helpVideosUrl = 'https://www.youtube.com/@AMCleanCare';
  static const helpManualUrl = 'https://d1ei86x16ftk6v.cloudfront.net/media/BNQ11-Manual-de-Instru%C3%A7%C3%A3o.pdf';

  // Pastas de imagens no Supabase Storage (as mesmas da app original)
  static const bucketTickets = 'imgtickets';
  static const bucketAnnonce = 'annonce';

  static bool get configured => !anonKey.startsWith('COLE_');
}
