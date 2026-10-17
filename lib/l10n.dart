import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Idiomas da app. O texto-base está em francês; as outras línguas traduzem-se por esta tabela.
/// Texto sem tradução aparece em francês (nunca fica vazio).
class L {
  static const langs = <String, String>{'fr': 'Français', 'en': 'English', 'de': 'Deutsch', 'pt': 'Português', 'sq': 'Shqip'};
  static const flags = <String, String>{'fr': '🇫🇷', 'en': '🇬🇧', 'de': '🇩🇪', 'pt': '🇵🇹', 'sq': '🇦🇱'};
  // A app abre SEMPRE em francês; cada pessoa pode escolher outra língua e a app grava a escolha (L.set).
  static final ValueNotifier<String> lang = ValueNotifier<String>('fr');

  static Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final s = p.getString('lang');
      if (s != null && langs.containsKey(s)) lang.value = s;
    } catch (_) {}
  }

  static Future<void> set(String code) async {
    lang.value = code;
    try { (await SharedPreferences.getInstance()).setString('lang', code); } catch (_) {}
  }

  static final messengerKey = GlobalKey<m.ScaffoldMessengerState>();
  static const _done = <String, String>{
    'fr': 'Langue changée avec succès',
    'en': 'Language changed successfully',
    'de': 'Sprache erfolgreich geändert',
    'pt': 'Idioma alterado com sucesso',
    'sq': 'Gjuha u ndryshua me sukses',
  };

  /// Muda o idioma e confirma, já na nova língua.
  static Future<void> change(String code) async {
    await set(code);
    messengerKey.currentState
      ?..clearSnackBars()
      ..showSnackBar(m.SnackBar(
        behavior: m.SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        content: Row(children: [const m.Icon(m.Icons.check_circle_rounded, color: m.Colors.white), const SizedBox(width: 10), Expanded(child: m.Text('${flags[code]}  ${_done[code]}', style: const TextStyle(fontWeight: FontWeight.w600)))]),
      ));
  }

  static String get name => langs[lang.value] ?? 'Français';
}

/// Traduz um texto francês para o idioma escolhido.
String tr(String fr) {
  final l = L.lang.value;
  if (l == 'fr') return fr;
  final row = _t[fr];
  if (row == null) return fr;
  return row[l] ?? fr;
}

/// Substitui o Text do Flutter: traduz sozinho e reage à mudança de idioma.
class Text extends StatelessWidget {
  const Text(this.data, {super.key, this.style, this.textAlign, this.maxLines, this.overflow, this.softWrap});
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
        valueListenable: L.lang,
        builder: (_, _, _) => m.Text(tr(data), style: style, textAlign: textAlign, maxLines: maxLines, overflow: overflow, softWrap: softWrap),
      );
}

// fr -> {en, de, pt, sq}
const Map<String, Map<String, String>> _t = {
  "Vivre ensemble dans l'immeuble": {'en': 'Living together in the building', 'de': 'Zusammenleben im Haus', 'pt': 'Viver em conjunto no edifício', 'sq': 'Të jetojmë së bashku në ndërtesë'},
  'Gestion des problèmes': {'en': 'Problem management', 'de': 'Problemverwaltung', 'pt': 'Gestão de problemas', 'sq': 'Menaxhimi i problemeve'},
  "Demande d'information": {'en': 'Information request', 'de': 'Informationsanfrage', 'pt': 'Pedido de informação', 'sq': 'Kërkesë për informacion'},
  'Concierge': {'en': 'Concierge', 'de': 'Concierge', 'pt': 'Concierge', 'sq': 'Konsierzh'},
  'Accepté': {'en': 'Accepted', 'de': 'Akzeptiert', 'pt': 'Aceite', 'sq': 'Pranuar'},
  'Refusé': {'en': 'Refused', 'de': 'Abgelehnt', 'pt': 'Recusado', 'sq': 'Refuzuar'},
  'Aucun bâtiment associé à votre compte.': {'en': 'No building linked to your account.', 'de': 'Ihrem Konto ist kein Gebäude zugeordnet.', 'pt': 'Nenhum edifício associado à sua conta.', 'sq': 'Asnjë ndërtesë e lidhur me llogarinë tuaj.'},
  'Aucun message pour le moment.': {'en': 'No messages yet.', 'de': 'Noch keine Nachrichten.', 'pt': 'Ainda sem mensagens.', 'sq': 'Ende pa mesazhe.'},
  'Bienvenue dans notre immeuble': {'en': 'Welcome to our building', 'de': 'Willkommen in unserem Haus', 'pt': 'Bem-vindo ao nosso edifício', 'sq': 'Mirë se vini në ndërtesën tonë'},
  'Boîte aux lettres': {'en': 'Mailbox', 'de': 'Briefkasten', 'pt': 'Caixa de correio', 'sq': 'Kutia postare'},
  'Choisissez le code demandé.': {'en': 'Choose the requested code.', 'de': 'Wählen Sie den gewünschten Code.', 'pt': 'Escolha o código pedido.', 'sq': 'Zgjidhni kodin e kërkuar.'},
  'Choisissez un lieu pour voir les types.': {'en': 'Choose a place to see the types.', 'de': 'Wählen Sie einen Ort, um die Arten zu sehen.', 'pt': 'Escolha um local para ver os tipos.', 'sq': 'Zgjidhni një vend për të parë llojet.'},
  'Code': {'en': 'Code', 'de': 'Code', 'pt': 'Código', 'sq': 'Kodi'},
  'Compte créé. Votre inscription doit être validée par la gérance.': {'en': 'Account created. Your registration must be approved by management.', 'de': 'Konto erstellt. Ihre Registrierung muss von der Verwaltung bestätigt werden.', 'pt': 'Conta criada. O seu registo tem de ser validado pela administração.', 'sq': 'Llogaria u krijua. Regjistrimi juaj duhet të miratohet nga administrata.'},
  "Contactez votre gérance pour plus d'informations.": {'en': 'Contact your management for more information.', 'de': 'Kontaktieren Sie Ihre Verwaltung für weitere Informationen.', 'pt': 'Contacte a sua administração para mais informações.', 'sq': 'Kontaktoni administratën për më shumë informacion.'},
  'Création du compte impossible.': {'en': 'Could not create the account.', 'de': 'Konto konnte nicht erstellt werden.', 'pt': 'Não foi possível criar a conta.', 'sq': 'Nuk u krijua dot llogaria.'},
  'Description': {'en': 'Description', 'de': 'Beschreibung', 'pt': 'Descrição', 'sq': 'Përshkrimi'},
  'Description *': {'en': 'Description *', 'de': 'Beschreibung *', 'pt': 'Descrição *', 'sq': 'Përshkrimi *'},
  'E-mail invalide.': {'en': 'Invalid email.', 'de': 'Ungültige E-Mail.', 'pt': 'E-mail inválido.', 'sq': 'Email i pavlefshëm.'},
  'Indiquez un prix ou cochez « Gratuit ».': {'en': 'Enter a price or tick "Free".', 'de': 'Geben Sie einen Preis an oder wählen Sie „Gratis“.', 'pt': 'Indique um preço ou marque «Grátis».', 'sq': 'Vendosni një çmim ose zgjidhni «Falas».'},
  'Indiquez un titre et un type de problème.': {'en': 'Enter a title and a type of problem.', 'de': 'Geben Sie einen Titel und eine Problemart an.', 'pt': 'Indique um título e um tipo de problema.', 'sq': 'Vendosni një titull dhe një lloj problemi.'},
  'Informations de base': {'en': 'Basic information', 'de': 'Grundangaben', 'pt': 'Informações básicas', 'sq': 'Informacioni bazë'},
  'Infos': {'en': 'Info', 'de': 'Infos', 'pt': 'Info', 'sq': 'Info'},
  'Inscription refusée': {'en': 'Registration refused', 'de': 'Registrierung abgelehnt', 'pt': 'Registo recusado', 'sq': 'Regjistrimi u refuzua'},
  'Le nom est obligatoire.': {'en': 'The name is required.', 'de': 'Der Name ist erforderlich.', 'pt': 'O nome é obrigatório.', 'sq': 'Emri është i detyrueshëm.'},
  'Nouvelle publication': {'en': 'New post', 'de': 'Neuer Beitrag', 'pt': 'Nova publicação', 'sq': 'Postim i ri'},
  'Précisions (facultatif)': {'en': 'Details (optional)', 'de': 'Details (optional)', 'pt': 'Detalhes (opcional)', 'sq': 'Detaje (opsionale)'},
  'Remplissez les champs obligatoires.': {'en': 'Fill in the required fields.', 'de': 'Füllen Sie die Pflichtfelder aus.', 'pt': 'Preencha os campos obrigatórios.', 'sq': 'Plotësoni fushat e detyrueshme.'},
  'Saisissez le code.': {'en': 'Enter the code.', 'de': 'Geben Sie den Code ein.', 'pt': 'Introduza o código.', 'sq': 'Shkruani kodin.'},
  'Succès': {'en': 'Success', 'de': 'Erfolg', 'pt': 'Sucesso', 'sq': 'Sukses'},
  'Sélectionnez le problème rencontré.': {'en': 'Select the problem encountered.', 'de': 'Wählen Sie das aufgetretene Problem.', 'pt': 'Selecione o problema encontrado.', 'sq': 'Zgjidhni problemin e hasur.'},
  'Voir': {'en': 'View', 'de': 'Ansehen', 'pt': 'Ver', 'sq': 'Shih'},
  'Vos informations': {'en': 'Your information', 'de': 'Ihre Angaben', 'pt': 'As suas informações', 'sq': 'Të dhënat tuaja'},
  'Vous devez charger une image.': {'en': 'You must upload an image.', 'de': 'Sie müssen ein Bild hochladen.', 'pt': 'Tem de carregar uma imagem.', 'sq': 'Duhet të ngarkoni një imazh.'},
  'Demande de code': {'en': 'Code request', 'de': 'Code-Anfrage', 'pt': 'Pedido de código', 'sq': 'Kërkesë për kod'},
  "Aucun gestionnaire n'est associé à votre bâtiment.": {'en': 'No manager is linked to your building.', 'de': 'Ihrem Gebäude ist kein Verwalter zugeordnet.', 'pt': 'Nenhum gestor está associado ao seu edifício.', 'sq': 'Asnjë menaxher nuk është i lidhur me ndërtesën tuaj.'},
  "Aucune annonce pour l'instant.\nPubliez la première !": {'en': 'No listings yet.\nPost the first one!', 'de': 'Noch keine Anzeigen.\nVeröffentlichen Sie die erste!', 'pt': 'Ainda sem anúncios.\nPublique o primeiro!', 'sq': 'Ende pa njoftime.\nPublikoni të parin!'},
  "Code d'inscription invalide.": {'en': 'Invalid registration code.', 'de': 'Ungültiger Registrierungscode.', 'pt': 'Código de registo inválido.', 'sq': 'Kod regjistrimi i pavlefshëm.'},
  "Indiquez l'objet de votre demande.": {'en': 'Enter the subject of your request.', 'de': 'Geben Sie den Betreff Ihrer Anfrage an.', 'pt': 'Indique o assunto do seu pedido.', 'sq': 'Shkruani lëndën e kërkesës suaj.'},
  "J'accepte les conditions d'utilisation et la politique de confidentialité.": {'en': 'I accept the terms of use and the privacy policy.', 'de': 'Ich akzeptiere die Nutzungsbedingungen und die Datenschutzrichtlinie.', 'pt': 'Aceito os termos de utilização e a política de privacidade.', 'sq': 'Pranoj kushtet e përdorimit dhe politikën e privatësisë.'},
  "Numéros d'urgence": {'en': 'Emergency numbers', 'de': 'Notrufnummern', 'pt': 'Números de emergência', 'sq': 'Numrat e urgjencës'},
  "N° d'appartement": {'en': 'Apartment no.', 'de': 'Wohnungsnr.', 'pt': 'N.º do apartamento', 'sq': 'Nr. i apartamentit'},
  "N° d'appartement *": {'en': 'Apartment no. *', 'de': 'Wohnungsnr. *', 'pt': 'N.º do apartamento *', 'sq': 'Nr. i apartamentit *'},
  'Étage': {'en': 'Floor', 'de': 'Stockwerk', 'pt': 'Andar', 'sq': 'Kati'},
  "Porte d'entrée": {'en': 'Entrance door', 'de': 'Eingangstür', 'pt': 'Porta de entrada', 'sq': 'Dera e hyrjes'},
  "Publier l'annonce": {'en': 'Publish listing', 'de': 'Anzeige veröffentlichen', 'pt': 'Publicar anúncio', 'sq': 'Publiko njoftimin'},
  "Saisissez d'abord votre e-mail.": {'en': 'Enter your email first.', 'de': 'Geben Sie zuerst Ihre E-Mail ein.', 'pt': 'Introduza primeiro o seu e-mail.', 'sq': 'Shkruani fillimisht email-in.'},
  "Sélectionnez le type d'appareil concerné": {'en': 'Select the type of appliance concerned', 'de': 'Wählen Sie das betroffene Gerät', 'pt': 'Selecione o tipo de aparelho em causa', 'sq': 'Zgjidhni llojin e pajisjes'},
  "Sélectionnez le type d'appareil concerné.": {'en': 'Select the type of appliance concerned.', 'de': 'Wählen Sie das betroffene Gerät.', 'pt': 'Selecione o tipo de aparelho em causa.', 'sq': 'Zgjidhni llojin e pajisjes.'},
  "Un e-mail contenant votre demande a été envoyé à l'administrateur. Veuillez patienter jusqu'à ce que vous receviez une réponse.": {'en': 'An email with your request has been sent to the administrator. Please wait for a reply.', 'de': 'Eine E-Mail mit Ihrer Anfrage wurde an den Administrator gesendet. Bitte warten Sie auf eine Antwort.', 'pt': 'Foi enviado um e-mail com o seu pedido ao administrador. Aguarde uma resposta.', 'sq': 'Një email me kërkesën tuaj iu dërgua administratorit. Ju lutemi prisni përgjigjen.'},
  'Veuillez accepter les conditions d\'utilisation.': {'en': 'Please accept the terms of use.', 'de': 'Bitte akzeptieren Sie die Nutzungsbedingungen.', 'pt': 'Aceite os termos de utilização.', 'sq': 'Ju lutemi pranoni kushtet e përdorimit.'},
  "Veuillez ajouter des captures d'écran de votre preuve de livraison.": {'en': 'Please add screenshots of your proof of delivery.', 'de': 'Bitte fügen Sie Screenshots Ihres Liefernachweises hinzu.', 'pt': 'Adicione capturas de ecrã da sua prova de entrega.', 'sq': 'Ju lutemi shtoni pamje ekrani të provës së dorëzimit.'},
  "Veuillez saisir le code de sécurité fourni par l'administrateur.": {'en': 'Please enter the security code provided by the administrator.', 'de': 'Bitte geben Sie den vom Administrator erhaltenen Sicherheitscode ein.', 'pt': 'Introduza o código de segurança fornecido pelo administrador.', 'sq': 'Ju lutemi shkruani kodin e sigurisë të dhënë nga administratori.'},
  "Vous n'avez encore rien publié.": {'en': "You haven't posted anything yet.", 'de': 'Sie haben noch nichts veröffentlicht.', 'pt': 'Ainda não publicou nada.', 'sq': 'Nuk keni publikuar ende asgjë.'},
  'Étape': {'en': 'Step', 'de': 'Schritt', 'pt': 'Passo', 'sq': 'Hapi'},
  'sur': {'en': 'of', 'de': 'von', 'pt': 'de', 'sq': 'nga'},
  "Groupe WhatsApp de l'immeuble": {'en': 'Building WhatsApp group', 'de': 'WhatsApp-Gruppe des Hauses', 'pt': 'Grupo de WhatsApp do edifício', 'sq': 'Grupi WhatsApp i ndërtesës'},
  'Discutez avec vos voisins': {'en': 'Chat with your neighbours', 'de': 'Chatten Sie mit Ihren Nachbarn', 'pt': 'Converse com os seus vizinhos', 'sq': 'Bisedoni me fqinjët tuaj'},
  'Rejoindre': {'en': 'Join', 'de': 'Beitreten', 'pt': 'Entrar', 'sq': 'Bashkohu'},
  'Bonjour': {'en': 'Hello', 'de': 'Hallo', 'pt': 'Olá', 'sq': 'Përshëndetje'},
  'en cours': {'en': 'in progress', 'de': 'in Bearbeitung', 'pt': 'em curso', 'sq': 'në proces'},
  'en attente': {'en': 'pending', 'de': 'wartend', 'pt': 'em espera', 'sq': 'në pritje'},
  'Langue': {'en': 'Language', 'de': 'Sprache', 'pt': 'Idioma', 'sq': 'Gjuha'},
  "Écrivez pour obtenir de l'aide": {'en': 'Type to get help', 'de': 'Schreiben Sie, um Hilfe zu erhalten', 'pt': 'Escreva para obter ajuda', 'sq': 'Shkruani për ndihmë'},
  'Répond en quelques secondes': {'en': 'Replies in seconds', 'de': 'Antwortet in Sekunden', 'pt': 'Responde em segundos', 'sq': 'Përgjigjet brenda sekondave'},
  'Contacter par WhatsApp': {'en': 'Contact via WhatsApp', 'de': 'Per WhatsApp kontaktieren', 'pt': 'Contactar por WhatsApp', 'sq': 'Kontakto në WhatsApp'},
  "Aujourd'hui": {'en': 'Today', 'de': 'Heute', 'pt': 'Hoje', 'sq': 'Sot'},
  'Accueil': {'en': 'Home', 'de': 'Start', 'pt': 'Início', 'sq': 'Kryefaqja'},
  'Messages': {'en': 'Messages', 'de': 'Chat', 'pt': 'Mensagens', 'sq': 'Mesazhet'},
  'Annonces': {'en': 'Listings', 'de': 'Anzeigen', 'pt': 'Anúncios', 'sq': 'Njoftimet'},
  'Réductions': {'en': 'Deals', 'de': 'Rabatte', 'pt': 'Descontos', 'sq': 'Zbritjet'},
  'Profil': {'en': 'Profile', 'de': 'Profil', 'pt': 'Perfil', 'sq': 'Profili'},
  'Bienvenue': {'en': 'Welcome', 'de': 'Willkommen', 'pt': 'Bem-vindo', 'sq': 'Mirë se vini'},
  'Votre partenaire de confiance en gestion immobilière': {'en': 'Your trusted partner in property management', 'de': 'Ihr vertrauensvoller Partner in der Immobilienverwaltung', 'pt': 'O seu parceiro de confiança na gestão imobiliária', 'sq': 'Partneri juaj i besuar në administrimin e pronave'},
  'E-mail': {'en': 'Email', 'de': 'E-Mail', 'pt': 'E-mail', 'sq': 'Email'},
  'E-mail *': {'en': 'Email *', 'de': 'E-Mail *', 'pt': 'E-mail *', 'sq': 'Email *'},
  'Email': {'en': 'Email', 'de': 'E-Mail', 'pt': 'E-mail', 'sq': 'Email'},
  'Mot de passe': {'en': 'Password', 'de': 'Passwort', 'pt': 'Palavra-passe', 'sq': 'Fjalëkalimi'},
  'Mot de passe oublié ? Cliquez ici': {'en': 'Forgot your password? Click here', 'de': 'Passwort vergessen? Hier klicken', 'pt': 'Esqueceu a palavra-passe? Clique aqui', 'sq': 'Harruat fjalëkalimin? Kliko këtu'},
  'Se connecter': {'en': 'Log in', 'de': 'Anmelden', 'pt': 'Entrar', 'sq': 'Hyr'},
  "S'inscrire": {'en': 'Sign up', 'de': 'Registrieren', 'pt': 'Registar', 'sq': 'Regjistrohu'},
  'Se déconnecter': {'en': 'Log out', 'de': 'Abmelden', 'pt': 'Terminar sessão', 'sq': 'Dil'},
  'Supprimer mon compte': {'en': 'Delete my account', 'de': 'Mein Konto löschen', 'pt': 'Eliminar a minha conta', 'sq': 'Fshij llogarinë time'},
  'Inscription': {'en': 'Sign-up', 'de': 'Registrierung', 'pt': 'Registo', 'sq': 'Regjistrimi'},
  'Entrez le code': {'en': 'Enter the code', 'de': 'Code eingeben', 'pt': 'Introduza o código', 'sq': 'Shkruaj kodin'},
  'Continuer': {'en': 'Continue', 'de': 'Weiter', 'pt': 'Continuar', 'sq': 'Vazhdo'},
  'Confirmer': {'en': 'Confirm', 'de': 'Bestätigen', 'pt': 'Confirmar', 'sq': 'Konfirmo'},
  'Confirmer le mot de passe': {'en': 'Confirm password', 'de': 'Passwort bestätigen', 'pt': 'Confirmar palavra-passe', 'sq': 'Konfirmo fjalëkalimin'},
  'Créer un mot de passe': {'en': 'Create a password', 'de': 'Passwort erstellen', 'pt': 'Criar palavra-passe', 'sq': 'Krijo fjalëkalim'},
  'Nom complet': {'en': 'Full name', 'de': 'Vollständiger Name', 'pt': 'Nome completo', 'sq': 'Emri i plotë'},
  'Nom complet *': {'en': 'Full name *', 'de': 'Vollständiger Name *', 'pt': 'Nome completo *', 'sq': 'Emri i plotë *'},
  'Téléphone': {'en': 'Phone', 'de': 'Telefon', 'pt': 'Telefone', 'sq': 'Telefoni'},
  'Adresse': {'en': 'Address', 'de': 'Adresse', 'pt': 'Morada', 'sq': 'Adresa'},
  'Appartement': {'en': 'Apartment', 'de': 'Wohnung', 'pt': 'Apartamento', 'sq': 'Apartamenti'},
  'Bâtiment': {'en': 'Building', 'de': 'Gebäude', 'pt': 'Edifício', 'sq': 'Ndërtesa'},
  'Résident': {'en': 'Resident', 'de': 'Bewohner', 'pt': 'Residente', 'sq': 'Banori'},
  'Informations du résident': {'en': 'Resident information', 'de': 'Angaben zum Bewohner', 'pt': 'Informações do residente', 'sq': 'Informacioni i banorit'},
  'Que souhaitez-vous faire ?': {'en': 'What would you like to do?', 'de': 'Was möchten Sie tun?', 'pt': 'O que pretende fazer?', 'sq': 'Çfarë dëshironi të bëni?'},
  'Concierge virtuel': {'en': 'Virtual concierge', 'de': 'Virtueller Concierge', 'pt': 'Concierge virtual', 'sq': 'Konsierzh virtual'},
  'Posez votre question, je parle votre langue.': {'en': 'Ask your question, I speak your language.', 'de': 'Stellen Sie Ihre Frage, ich spreche Ihre Sprache.', 'pt': 'Faça a sua pergunta, falo a sua língua.', 'sq': 'Bëni pyetjen tuaj, flas gjuhën tuaj.'},
  'En ligne': {'en': 'Online', 'de': 'Online', 'pt': 'Online', 'sq': 'Online'},
  'Ouvrir un ticket': {'en': 'Open a ticket', 'de': 'Ticket erstellen', 'pt': 'Abrir um ticket', 'sq': 'Hap një tiketë'},
  'Vous avez des problèmes ?': {'en': 'Having problems?', 'de': 'Haben Sie Probleme?', 'pt': 'Tem problemas?', 'sq': 'Keni probleme?'},
  'Tickets ouverts': {'en': 'Open tickets', 'de': 'Offene Tickets', 'pt': 'Tickets abertos', 'sq': 'Tiketa të hapura'},
  'Aucun ticket en cours': {'en': 'No ticket in progress', 'de': 'Kein Ticket in Bearbeitung', 'pt': 'Nenhum ticket em curso', 'sq': 'Asnjë tiketë në proces'},
  'Conciergerie': {'en': 'Concierge desk', 'de': 'Concierge-Dienst', 'pt': 'Conciergerie', 'sq': 'Shërbimi i konsierzhit'},
  'Parler avec le Service de Conciergerie': {'en': 'Talk to the Concierge Service', 'de': 'Mit dem Concierge-Service sprechen', 'pt': 'Falar com o Serviço de Conciergerie', 'sq': 'Bisedo me Shërbimin e Konsierzhit'},
  'Service de conciergerie': {'en': 'Concierge service', 'de': 'Concierge-Service', 'pt': 'Serviço de conciergerie', 'sq': 'Shërbimi i konsierzhit'},
  'Buanderie': {'en': 'Laundry room', 'de': 'Waschküche', 'pt': 'Lavandaria', 'sq': 'Lavanderia'},
  'Il y a un problème dans la buanderie ?': {'en': 'Is there a problem in the laundry room?', 'de': 'Gibt es ein Problem in der Waschküche?', 'pt': 'Há um problema na lavandaria?', 'sq': 'A ka problem në lavanderi?'},
  'Colis volé ?': {'en': 'Stolen parcel?', 'de': 'Paket gestohlen?', 'pt': 'Encomenda roubada?', 'sq': 'Pako e vjedhur?'},
  'Nous sommes là pour vous aider': {'en': "We're here to help", 'de': 'Wir helfen Ihnen gerne', 'pt': 'Estamos aqui para ajudar', 'sq': 'Jemi këtu për t\'ju ndihmuar'},
  'Notifications': {'en': 'Notifications', 'de': 'Mitteilungen', 'pt': 'Notificações', 'sq': 'Njoftimet'},
  'Notifications récentes': {'en': 'Recent notifications', 'de': 'Neueste Benachrichtigungen', 'pt': 'Notificações recentes', 'sq': 'Njoftimet e fundit'},
  'Aucune notification pour le moment.': {'en': 'No notifications yet.', 'de': 'Noch keine Benachrichtigungen.', 'pt': 'Ainda sem notificações.', 'sq': 'Ende pa njoftime.'},
  'Aucune notification.': {'en': 'No notifications.', 'de': 'Keine Benachrichtigungen.', 'pt': 'Sem notificações.', 'sq': 'Pa njoftime.'},
  'Tout voir': {'en': 'See all', 'de': 'Alle anzeigen', 'pt': 'Ver tudo', 'sq': 'Shih të gjitha'},
  'Tout lire': {'en': 'Mark all read', 'de': 'Alle gelesen', 'pt': 'Marcar tudo como lido', 'sq': 'Shëno të gjitha si të lexuara'},
  'Urgences': {'en': 'Emergencies', 'de': 'Notfälle', 'pt': 'Emergências', 'sq': 'Urgjencat'},
  'Contacts importants': {'en': 'Important contacts', 'de': 'Wichtige Kontakte', 'pt': 'Contactos importantes', 'sq': 'Kontakte të rëndësishme'},
  'Police': {'en': 'Police', 'de': 'Polizei', 'pt': 'Polícia', 'sq': 'Policia'},
  'Pompiers': {'en': 'Fire brigade', 'de': 'Feuerwehr', 'pt': 'Bombeiros', 'sq': 'Zjarrfikësit'},
  'Ambulance': {'en': 'Ambulance', 'de': 'Ambulanz', 'pt': 'Ambulância', 'sq': 'Ambulanca'},
  'Gérance': {'en': 'Property management', 'de': 'Verwaltung', 'pt': 'Administração', 'sq': 'Administrata'},
  'Nouveau ticket': {'en': 'New ticket', 'de': 'Neues Ticket', 'pt': 'Novo ticket', 'sq': 'Tiketë e re'},
  'Où est le problème ?': {'en': 'Where is the problem?', 'de': 'Wo ist das Problem?', 'pt': 'Onde está o problema?', 'sq': 'Ku është problemi?'},
  'Type de problème': {'en': 'Type of problem', 'de': 'Art des Problems', 'pt': 'Tipo de problema', 'sq': 'Lloji i problemit'},
  'Détails du problème': {'en': 'Problem details', 'de': 'Details zum Problem', 'pt': 'Detalhes do problema', 'sq': 'Detajet e problemit'},
  'Titre du problème *': {'en': 'Problem title *', 'de': 'Titel des Problems *', 'pt': 'Título do problema *', 'sq': 'Titulli i problemit *'},
  'Description détaillée': {'en': 'Detailed description', 'de': 'Ausführliche Beschreibung', 'pt': 'Descrição detalhada', 'sq': 'Përshkrim i detajuar'},
  'Photos': {'en': 'Photos', 'de': 'Fotos', 'pt': 'Fotografias', 'sq': 'Fotot'},
  'Envoyer le ticket': {'en': 'Send ticket', 'de': 'Ticket senden', 'pt': 'Enviar ticket', 'sq': 'Dërgo tiketën'},
  'Ticket créé. La gérance a été prévenue.': {'en': 'Ticket created. Management has been notified.', 'de': 'Ticket erstellt. Die Verwaltung wurde benachrichtigt.', 'pt': 'Ticket criado. A administração foi avisada.', 'sq': 'Tiketa u krijua. Administrata u njoftua.'},
  'Gestionnaire de tickets': {'en': 'Ticket manager', 'de': 'Ticketverwaltung', 'pt': 'Gestor de tickets', 'sq': 'Menaxheri i tiketave'},
  'Aucun ticket ici.\nSignalez un problème en quelques secondes.': {'en': 'No tickets here.\nReport a problem in seconds.', 'de': 'Keine Tickets.\nMelden Sie ein Problem in Sekunden.', 'pt': 'Sem tickets.\nReporte um problema em segundos.', 'sq': 'Asnjë tiketë.\nRaportoni një problem për pak sekonda.'},
  'Tous': {'en': 'All', 'de': 'Alle', 'pt': 'Todos', 'sq': 'Të gjitha'},
  'En Attente': {'en': 'Pending', 'de': 'Wartend', 'pt': 'Em espera', 'sq': 'Në pritje'},
  'En attente': {'en': 'Pending', 'de': 'Wartend', 'pt': 'Em espera', 'sq': 'Në pritje'},
  'En Cours': {'en': 'In progress', 'de': 'In Bearbeitung', 'pt': 'Em curso', 'sq': 'Në proces'},
  'En cours': {'en': 'In progress', 'de': 'In Bearbeitung', 'pt': 'Em curso', 'sq': 'Në proces'},
  'Fermé': {'en': 'Closed', 'de': 'Geschlossen', 'pt': 'Fechado', 'sq': 'I mbyllur'},
  'Conversation': {'en': 'Conversation', 'de': 'Unterhaltung', 'pt': 'Conversa', 'sq': 'Biseda'},
  'Votre message': {'en': 'Your message', 'de': 'Ihre Nachricht', 'pt': 'A sua mensagem', 'sq': 'Mesazhi juaj'},
  'Écrivez votre message': {'en': 'Write your message', 'de': 'Nachricht schreiben', 'pt': 'Escreva a sua mensagem', 'sq': 'Shkruani mesazhin tuaj'},
  'Écrire un message': {'en': 'Write a message', 'de': 'Nachricht schreiben', 'pt': 'Escrever uma mensagem', 'sq': 'Shkruaj një mesazh'},
  'Messages récents': {'en': 'Recent messages', 'de': 'Letzte Nachrichten', 'pt': 'Mensagens recentes', 'sq': 'Mesazhet e fundit'},
  'Écrire à votre gestionnaire': {'en': 'Write to your manager', 'de': 'An Ihren Verwalter schreiben', 'pt': 'Escrever ao seu gestor', 'sq': 'Shkruaj menaxherit tuaj'},
  'Aucune conversation pour le moment.\nLes échanges de vos tickets apparaissent ici.': {'en': 'No conversations yet.\nYour ticket exchanges appear here.', 'de': 'Noch keine Unterhaltungen.\nDer Austausch zu Ihren Tickets erscheint hier.', 'pt': 'Ainda sem conversas.\nAs trocas dos seus tickets aparecem aqui.', 'sq': 'Ende pa biseda.\nNdërveprimet e tiketave shfaqen këtu.'},
  'Écrivez à votre gestionnaire.\nVous recevrez sa réponse ici.': {'en': 'Write to your manager.\nYou will get the reply here.', 'de': 'Schreiben Sie Ihrem Verwalter.\nDie Antwort erscheint hier.', 'pt': 'Escreva ao seu gestor.\nA resposta aparece aqui.', 'sq': 'Shkruani menaxherit.\nPërgjigjen do ta merrni këtu.'},
  'Locataire Connect': {'en': 'Tenant Connect', 'de': 'Mieter-Connect', 'pt': 'Locatário Connect', 'sq': 'Qiramarrës Connect'},
  'Quoi de neuf dans le bâtiment ?': {'en': "What's new in the building?", 'de': 'Was gibt es Neues im Gebäude?', 'pt': 'O que há de novo no edifício?', 'sq': 'Çfarë ka të re në ndërtesë?'},
  'Mes publications': {'en': 'My posts', 'de': 'Meine Beiträge', 'pt': 'As minhas publicações', 'sq': 'Postimet e mia'},
  'Publier': {'en': 'Post', 'de': 'Veröffentlichen', 'pt': 'Publicar', 'sq': 'Publiko'},
  'Créer une annonce': {'en': 'Create a listing', 'de': 'Anzeige erstellen', 'pt': 'Criar um anúncio', 'sq': 'Krijo një njoftim'},
  'Partager': {'en': 'Share', 'de': 'Teilen', 'pt': 'Partilhar', 'sq': 'Ndaj'},
  'Gratuit': {'en': 'Free', 'de': 'Gratis', 'pt': 'Grátis', 'sq': 'Falas'},
  'Prix': {'en': 'Price', 'de': 'Preis', 'pt': 'Preço', 'sq': 'Çmimi'},
  'Prix (CHF)': {'en': 'Price (CHF)', 'de': 'Preis (CHF)', 'pt': 'Preço (CHF)', 'sq': 'Çmimi (CHF)'},
  'Commentaires': {'en': 'Comments', 'de': 'Kommentare', 'pt': 'Comentários', 'sq': 'Komentet'},
  'Votre commentaire': {'en': 'Your comment', 'de': 'Ihr Kommentar', 'pt': 'O seu comentário', 'sq': 'Komenti juaj'},
  'Aucun commentaire. Soyez le premier !': {'en': 'No comments. Be the first!', 'de': 'Keine Kommentare. Seien Sie der Erste!', 'pt': 'Sem comentários. Seja o primeiro!', 'sq': 'Pa komente. Bëhu i pari!'},
  'Soyez le premier à publier une annonce.': {'en': 'Be the first to post a listing.', 'de': 'Veröffentlichen Sie als Erster eine Anzeige.', 'pt': 'Seja o primeiro a publicar um anúncio.', 'sq': 'Bëhu i pari që publikon një njoftim.'},
  'Annonce publiée.': {'en': 'Listing published.', 'de': 'Anzeige veröffentlicht.', 'pt': 'Anúncio publicado.', 'sq': 'Njoftimi u publikua.'},
  'Supprimer': {'en': 'Delete', 'de': 'Löschen', 'pt': 'Eliminar', 'sq': 'Fshij'},
  'Supprimer la publication': {'en': 'Delete post', 'de': 'Beitrag löschen', 'pt': 'Eliminar publicação', 'sq': 'Fshij postimin'},
  'Êtes-vous sûr de vouloir supprimer cette publication ?': {'en': 'Are you sure you want to delete this post?', 'de': 'Möchten Sie diesen Beitrag wirklich löschen?', 'pt': 'Tem a certeza de que quer eliminar esta publicação?', 'sq': 'Jeni i sigurt që doni ta fshini këtë postim?'},
  'Annuler': {'en': 'Cancel', 'de': 'Abbrechen', 'pt': 'Cancelar', 'sq': 'Anulo'},
  'Décrivez votre annonce.': {'en': 'Describe your listing.', 'de': 'Beschreiben Sie Ihre Anzeige.', 'pt': 'Descreva o seu anúncio.', 'sq': 'Përshkruani njoftimin tuaj.'},
  'Téléphone ou e-mail': {'en': 'Phone or email', 'de': 'Telefon oder E-Mail', 'pt': 'Telefone ou e-mail', 'sq': 'Telefon ose email'},
  'Codes de réduction': {'en': 'Discount codes', 'de': 'Rabattcodes', 'pt': 'Códigos de desconto', 'sq': 'Kodet e zbritjes'},
  'Aucun code de réduction pour le moment.\nRevenez bientôt !': {'en': 'No discount codes yet.\nCome back soon!', 'de': 'Noch keine Rabattcodes.\nSchauen Sie bald wieder vorbei!', 'pt': 'Ainda sem códigos de desconto.\nVolte em breve!', 'sq': 'Ende pa kode zbritjeje.\nKthehuni së shpejti!'},
  'Copier': {'en': 'Copy', 'de': 'Kopieren', 'pt': 'Copiar', 'sq': 'Kopjo'},
  'Code copié': {'en': 'Code copied', 'de': 'Code kopiert', 'pt': 'Código copiado', 'sq': 'Kodi u kopjua'},
  'Compte actif': {'en': 'Active account', 'de': 'Aktives Konto', 'pt': 'Conta ativa', 'sq': 'Llogari aktive'},
  'Informations personnelles': {'en': 'Personal information', 'de': 'Persönliche Angaben', 'pt': 'Informações pessoais', 'sq': 'Të dhëna personale'},
  'Paramètres du compte': {'en': 'Account settings', 'de': 'Kontoeinstellungen', 'pt': 'Definições da conta', 'sq': 'Cilësimet e llogarisë'},
  'Membre depuis': {'en': 'Member since', 'de': 'Mitglied seit', 'pt': 'Membro desde', 'sq': 'Anëtar që nga'},
  'Dernière connexion': {'en': 'Last login', 'de': 'Letzte Anmeldung', 'pt': 'Última ligação', 'sq': 'Hyrja e fundit'},
  'Statut du compte': {'en': 'Account status', 'de': 'Kontostatus', 'pt': 'Estado da conta', 'sq': 'Gjendja e llogarisë'},
  'Actif': {'en': 'Active', 'de': 'Aktiv', 'pt': 'Ativo', 'sq': 'Aktiv'},
  'Modifier mes informations': {'en': 'Edit my information', 'de': 'Meine Angaben ändern', 'pt': 'Editar as minhas informações', 'sq': 'Ndrysho të dhënat e mia'},
  'Plus': {'en': 'More', 'de': 'Mehr', 'pt': 'Mais', 'sq': 'Më shumë'},
  'Règles de bien-être': {'en': 'Well-being rules', 'de': 'Hausordnung', 'pt': 'Regras de bem-estar', 'sq': 'Rregullat e mirëqenies'},
  'Changer le mot de passe': {'en': 'Change password', 'de': 'Passwort ändern', 'pt': 'Alterar palavra-passe', 'sq': 'Ndrysho fjalëkalimin'},
  'Enregistrer': {'en': 'Save', 'de': 'Speichern', 'pt': 'Guardar', 'sq': 'Ruaj'},
  'Informations mises à jour.': {'en': 'Information updated.', 'de': 'Angaben aktualisiert.', 'pt': 'Informações atualizadas.', 'sq': 'Të dhënat u përditësuan.'},
  'Signaler un problème': {'en': 'Report a problem', 'de': 'Problem melden', 'pt': 'Reportar um problema', 'sq': 'Raporto një problem'},
  'Machine à laver': {'en': 'Washing machine', 'de': 'Waschmaschine', 'pt': 'Máquina de lavar', 'sq': 'Lavatriçe'},
  'Sèche-linge': {'en': 'Dryer', 'de': 'Wäschetrockner', 'pt': 'Secador', 'sq': 'Tharëse'},
  'Sélectionnez le problème rencontré': {'en': 'Select the problem encountered', 'de': 'Wählen Sie das aufgetretene Problem', 'pt': 'Selecione o problema encontrado', 'sq': 'Zgjidhni problemin e hasur'},
  'Ne démarre pas': {'en': "Won't start", 'de': 'Startet nicht', 'pt': 'Não arranca', 'sq': 'Nuk ndizet'},
  'Fuite d\'eau': {'en': 'Water leak', 'de': 'Wasserleck', 'pt': 'Fuga de água', 'sq': 'Rrjedhje uji'},
  'Bruit anormal': {'en': 'Unusual noise', 'de': 'Ungewöhnliches Geräusch', 'pt': 'Ruído anormal', 'sq': 'Zhurmë e pazakontë'},
  'Cycle incomplet': {'en': 'Cycle incomplete', 'de': 'Zyklus unvollständig', 'pt': 'Ciclo incompleto', 'sq': 'Cikël i paplotë'},
  'Erreur sur l\'écran': {'en': 'Screen error', 'de': 'Fehler auf dem Display', 'pt': 'Erro no ecrã', 'sq': 'Gabim në ekran'},
  'Porte bloquée': {'en': 'Door stuck', 'de': 'Tür blockiert', 'pt': 'Porta bloqueada', 'sq': 'Dera e bllokuar'},
  'Ajouter une photo du problème': {'en': 'Add a photo of the problem', 'de': 'Foto des Problems hinzufügen', 'pt': 'Adicionar uma foto do problema', 'sq': 'Shto një foto të problemit'},
  'Une photo nous aide à intervenir plus vite.': {'en': 'A photo helps us act faster.', 'de': 'Ein Foto hilft uns, schneller zu helfen.', 'pt': 'Uma foto ajuda-nos a intervir mais depressa.', 'sq': 'Një foto na ndihmon të ndërhyjmë më shpejt.'},
  'Ajouter': {'en': 'Add', 'de': 'Hinzufügen', 'pt': 'Adicionar', 'sq': 'Shto'},
  '* Vous devez télécharger une image.': {'en': '* You must upload an image.', 'de': '* Sie müssen ein Bild hochladen.', 'pt': '* Tem de carregar uma imagem.', 'sq': '* Duhet të ngarkoni një imazh.'},
  'Détails (facultatif)': {'en': 'Details (optional)', 'de': 'Details (optional)', 'pt': 'Detalhes (opcional)', 'sq': 'Detaje (opsionale)'},
  'Décrivez le problème': {'en': 'Describe the problem', 'de': 'Beschreiben Sie das Problem', 'pt': 'Descreva o problema', 'sq': 'Përshkruani problemin'},
  'Aide': {'en': 'Help', 'de': 'Hilfe', 'pt': 'Ajuda', 'sq': 'Ndihmë'},
  'Guide': {'en': 'Guide', 'de': 'Anleitung', 'pt': 'Guia', 'sq': 'Udhëzues'},
  'Manuel': {'en': 'Manual', 'de': 'Handbuch', 'pt': 'Manual', 'sq': 'Manuali'},
  'Vidéos': {'en': 'Videos', 'de': 'Videos', 'pt': 'Vídeos', 'sq': 'Video'},
  'Envoyer le signalement': {'en': 'Send report', 'de': 'Meldung senden', 'pt': 'Enviar reporte', 'sq': 'Dërgo raportin'},
  'Votre signalement sera traité dans les plus brefs délais.': {'en': 'Your report will be handled as soon as possible.', 'de': 'Ihre Meldung wird schnellstmöglich bearbeitet.', 'pt': 'O seu reporte será tratado o mais depressa possível.', 'sq': 'Raporti juaj do të trajtohet sa më shpejt.'},
  'Demande envoyée': {'en': 'Request sent', 'de': 'Anfrage gesendet', 'pt': 'Pedido enviado', 'sq': 'Kërkesa u dërgua'},
  'Votre demande a été transmise à la gérance. Vous serez contacté rapidement.': {'en': 'Your request has been sent to management. You will be contacted shortly.', 'de': 'Ihre Anfrage wurde an die Verwaltung weitergeleitet. Sie werden bald kontaktiert.', 'pt': 'O seu pedido foi enviado à administração. Será contactado em breve.', 'sq': 'Kërkesa juaj iu përcoll administratës. Do t\'ju kontaktojmë shpejt.'},
  'Colis volé ?\nNous sommes là pour vous aider.': {'en': 'Stolen parcel?\nWe are here to help.', 'de': 'Paket gestohlen?\nWir helfen Ihnen gerne.', 'pt': 'Encomenda roubada?\nEstamos aqui para ajudar.', 'sq': 'Pako e vjedhur?\nJemi këtu për t\'ju ndihmuar.'},
  'Détails de la demande': {'en': 'Request details', 'de': 'Details der Anfrage', 'pt': 'Detalhes do pedido', 'sq': 'Detajet e kërkesës'},
  'Objet *': {'en': 'Subject *', 'de': 'Betreff *', 'pt': 'Assunto *', 'sq': 'Lënda *'},
  'Description (lieu, objet, circonstances)': {'en': 'Description (place, item, circumstances)', 'de': 'Beschreibung (Ort, Gegenstand, Umstände)', 'pt': 'Descrição (local, objeto, circunstâncias)', 'sq': 'Përshkrimi (vendi, objekti, rrethanat)'},
  'Preuve de livraison': {'en': 'Proof of delivery', 'de': 'Liefernachweis', 'pt': 'Prova de entrega', 'sq': 'Prova e dorëzimit'},
  'Date et heure': {'en': 'Date and time', 'de': 'Datum und Uhrzeit', 'pt': 'Data e hora', 'sq': 'Data dhe ora'},
  'Contact': {'en': 'Contact', 'de': 'Kontakt', 'pt': 'Contacto', 'sq': 'Kontakti'},
  'E-mail ou téléphone': {'en': 'Email or phone', 'de': 'E-Mail oder Telefon', 'pt': 'E-mail ou telefone', 'sq': 'Email ose telefon'},
  'Envoyer la demande': {'en': 'Send request', 'de': 'Anfrage senden', 'pt': 'Enviar pedido', 'sq': 'Dërgo kërkesën'},
  'Demander les images': {'en': 'Request footage', 'de': 'Aufnahmen anfordern', 'pt': 'Pedir as imagens', 'sq': 'Kërko pamjet'},
  'Open a ticket': {'en': 'Open a ticket', 'de': 'Ticket erstellen', 'pt': 'Abrir um ticket', 'sq': 'Hap një tiketë'},
  'Réponse copiée.': {'en': 'Reply copied.', 'de': 'Antwort kopiert.', 'pt': 'Resposta copiada.', 'sq': 'Përgjigjja u kopjua.'},
  'En train de réfléchir…': {'en': 'Thinking…', 'de': 'Denke nach…', 'pt': 'A pensar…', 'sq': 'Po mendoj…'},
  'Nouvelle conversation': {'en': 'New conversation', 'de': 'Neue Unterhaltung', 'pt': 'Nova conversa', 'sq': 'Bisedë e re'},
  'Nouvelle conversation ?': {'en': 'New conversation?', 'de': 'Neue Unterhaltung?', 'pt': 'Nova conversa?', 'sq': 'Bisedë e re?'},
  'La conversation actuelle sera effacée.': {'en': 'The current conversation will be erased.', 'de': 'Die aktuelle Unterhaltung wird gelöscht.', 'pt': 'A conversa atual será apagada.', 'sq': 'Biseda aktuale do të fshihet.'},
  'Effacer': {'en': 'Erase', 'de': 'Löschen', 'pt': 'Apagar', 'sq': 'Fshij'},
  "J'ai une fuite d'eau": {'en': 'I have a water leak', 'de': 'Ich habe ein Wasserleck', 'pt': 'Tenho uma fuga de água', 'sq': 'Kam një rrjedhje uji'},
  'Problème de chauffage': {'en': 'Heating problem', 'de': 'Heizungsproblem', 'pt': 'Problema de aquecimento', 'sq': 'Problem me ngrohjen'},
  'Bruit des voisins': {'en': 'Noisy neighbours', 'de': 'Lärm der Nachbarn', 'pt': 'Barulho dos vizinhos', 'sq': 'Zhurma e fqinjëve'},
  "L'ascenseur est en panne": {'en': 'The lift is broken', 'de': 'Der Aufzug ist defekt', 'pt': 'O elevador está avariado', 'sq': 'Ashensori është prishur'},
  "J'ai perdu mon colis": {'en': 'I lost my parcel', 'de': 'Ich habe mein Paket verloren', 'pt': 'Perdi a minha encomenda', 'sq': 'Kam humbur pakon'},
  'Bonjour, je suis votre concierge virtuel 👋\nJe suis là pour vous aider à trouver la solution à votre problème.\nJe parle votre langue ainsi que plusieurs autres.\n\nComment puis-je vous aider ?': {
    'en': "Hello, I'm your virtual concierge 👋\nI'm here to help you find a solution to your problem.\nI speak your language and several others.\n\nHow can I help you?",
    'de': 'Hallo, ich bin Ihr virtueller Concierge 👋\nIch helfe Ihnen, eine Lösung für Ihr Problem zu finden.\nIch spreche Ihre Sprache und noch einige mehr.\n\nWie kann ich Ihnen helfen?',
    'pt': 'Olá, sou o seu concierge virtual 👋\nEstou aqui para o ajudar a encontrar a solução para o seu problema.\nFalo a sua língua e várias outras.\n\nComo posso ajudar?',
    'sq': 'Përshëndetje, jam konsierzhi juaj virtual 👋\nJam këtu t\'ju ndihmoj të gjeni zgjidhjen e problemit.\nFlas gjuhën tuaj dhe disa të tjera.\n\nSi mund t\'ju ndihmoj?'
  },
  'Nouveau sur AM Clean Care ?': {'en': 'New to AM Clean Care?', 'de': 'Neu bei AM Clean Care?', 'pt': 'Novo na AM Clean Care?', 'sq': 'I ri në AM Clean Care?'},
  'Inscription en attente': {'en': 'Registration pending', 'de': 'Registrierung ausstehend', 'pt': 'Registo pendente', 'sq': 'Regjistrimi në pritje'},
  "La gérance doit valider votre compte. Vous pourrez ensuite utiliser toute l'application.": {'en': 'Management must approve your account. You can then use the whole app.', 'de': 'Die Verwaltung muss Ihr Konto freigeben. Danach können Sie die ganze App nutzen.', 'pt': 'A administração tem de validar a sua conta. Depois poderá usar toda a aplicação.', 'sq': 'Administrata duhet të miratojë llogarinë tuaj. Pastaj mund të përdorni të gjithë aplikacionin.'},
  'Actualiser': {'en': 'Refresh', 'de': 'Aktualisieren', 'pt': 'Atualizar', 'sq': 'Rifresko'},
  'Saisissez votre e-mail et votre mot de passe.': {'en': 'Enter your email and password.', 'de': 'Geben Sie E-Mail und Passwort ein.', 'pt': 'Introduza o e-mail e a palavra-passe.', 'sq': 'Shkruani email-in dhe fjalëkalimin.'},
  'E-mail ou mot de passe incorrect.': {'en': 'Incorrect email or password.', 'de': 'E-Mail oder Passwort falsch.', 'pt': 'E-mail ou palavra-passe incorretos.', 'sq': 'Email ose fjalëkalim i gabuar.'},
  'E-mail de réinitialisation envoyé.': {'en': 'Reset email sent.', 'de': 'E-Mail zum Zurücksetzen gesendet.', 'pt': 'E-mail de recuperação enviado.', 'sq': 'Email-i i rivendosjes u dërgua.'},
  'Mot de passe : 6 caractères minimum.': {'en': 'Password: at least 6 characters.', 'de': 'Passwort: mindestens 6 Zeichen.', 'pt': 'Palavra-passe: mínimo 6 caracteres.', 'sq': 'Fjalëkalimi: të paktën 6 karaktere.'},
  'Les mots de passe ne correspondent pas.': {'en': 'Passwords do not match.', 'de': 'Die Passwörter stimmen nicht überein.', 'pt': 'As palavras-passe não coincidem.', 'sq': 'Fjalëkalimet nuk përputhen.'},
  'Une erreur est survenue.': {'en': 'An error occurred.', 'de': 'Ein Fehler ist aufgetreten.', 'pt': 'Ocorreu um erro.', 'sq': 'Ndodhi një gabim.'},
  'Réserver un créneau ou signaler un problème': {'en': 'Book a slot or report a problem', 'de': 'Zeit buchen oder Problem melden', 'pt': 'Reservar um horário ou comunicar um problema', 'sq': 'Rezervo një orar ose raporto një problem'},
  'Choisissez votre buanderie': {'en': 'Choose your laundry room', 'de': 'Wählen Sie Ihre Waschküche', 'pt': 'Escolha a sua lavandaria', 'sq': 'Zgjidhni lavanderinë tuaj'},
  'Votre prochain créneau': {'en': 'Your next slot', 'de': 'Ihr nächster Termin', 'pt': 'O seu próximo horário', 'sq': 'Orari juaj i radhës'},
  'Aucune réservation. Choisissez un créneau ci-dessous.': {'en': 'No booking yet. Pick a slot below.', 'de': 'Keine Reservierung. Wählen Sie unten einen Termin.', 'pt': 'Sem reservas. Escolha um horário abaixo.', 'sq': 'Asnjë rezervim. Zgjidhni një orar më poshtë.'},
  'Libre': {'en': 'Free', 'de': 'Frei', 'pt': 'Livre', 'sq': 'E lirë'},
  'Occupé': {'en': 'Taken', 'de': 'Belegt', 'pt': 'Ocupado', 'sq': 'E zënë'},
  'Ma réservation': {'en': 'My booking', 'de': 'Meine Reservierung', 'pt': 'A minha reserva', 'sq': 'Rezervimi im'},
  'Mes réservations': {'en': 'My bookings', 'de': 'Meine Reservierungen', 'pt': 'As minhas reservas', 'sq': 'Rezervimet e mia'},
  'Aucune réservation pour le moment.': {'en': 'No bookings at the moment.', 'de': 'Derzeit keine Reservierungen.', 'pt': 'Sem reservas de momento.', 'sq': 'Asnjë rezervim për momentin.'},
  'Annuler la réservation': {'en': 'Cancel booking', 'de': 'Reservierung stornieren', 'pt': 'Cancelar reserva', 'sq': 'Anulo rezervimin'},
  'Garder': {'en': 'Keep', 'de': 'Behalten', 'pt': 'Manter', 'sq': 'Mbaj'},
  'Réserver': {'en': 'Book', 'de': 'Reservieren', 'pt': 'Reservar', 'sq': 'Rezervo'},
  'Réserver ce créneau ?': {'en': 'Book this slot?', 'de': 'Diesen Termin reservieren?', 'pt': 'Reservar este horário?', 'sq': 'Të rezervohet ky orar?'},
  'Annuler cette réservation ?': {'en': 'Cancel this booking?', 'de': 'Diese Reservierung stornieren?', 'pt': 'Cancelar esta reserva?', 'sq': 'Të anulohet ky rezervim?'},
  'Créneau réservé.': {'en': 'Slot booked.', 'de': 'Termin reserviert.', 'pt': 'Horário reservado.', 'sq': 'Orari u rezervua.'},
  'Réservation annulée.': {'en': 'Booking cancelled.', 'de': 'Reservierung storniert.', 'pt': 'Reserva cancelada.', 'sq': 'Rezervimi u anulua.'},
  'Indisponible': {'en': 'Unavailable', 'de': 'Nicht verfügbar', 'pt': 'Indisponível', 'sq': 'Jo i disponueshëm'},
  'La buanderie est fermée ce jour.': {'en': 'The laundry room is closed this day.', 'de': 'Die Waschküche ist an diesem Tag geschlossen.', 'pt': 'A lavandaria está fechada neste dia.', 'sq': 'Lavanderia është e mbyllur këtë ditë.'},
  "Aucune machine n'est configurée.": {'en': 'No machine is set up.', 'de': 'Keine Maschine eingerichtet.', 'pt': 'Nenhuma máquina configurada.', 'sq': 'Asnjë makinë nuk është konfiguruar.'},
  "La réservation de la buanderie n'est pas encore activée.": {'en': 'Laundry booking is not active yet.', 'de': 'Die Waschküchenreservierung ist noch nicht aktiviert.', 'pt': 'A reserva da lavandaria ainda não está ativa.', 'sq': 'Rezervimi i lavanderisë nuk është aktivizuar ende.'},
  "Aucune buanderie n'est configurée pour votre immeuble. Contactez votre gérance.": {'en': 'No laundry room is set up for your building. Contact your property manager.', 'de': 'Für Ihr Gebäude ist keine Waschküche eingerichtet. Kontaktieren Sie Ihre Verwaltung.', 'pt': 'Não há lavandaria configurada para o seu prédio. Contacte a sua gerência.', 'sq': 'Nuk ka lavanderi të konfiguruar për ndërtesën tuaj. Kontaktoni administratën.'},
  'Limite atteinte': {'en': 'Limit reached', 'de': 'Limit erreicht', 'pt': 'Limite atingido', 'sq': 'Kufiri u arrit'},
  'créneaux par semaine': {'en': 'slots per week', 'de': 'Termine pro Woche', 'pt': 'horários por semana', 'sq': 'orare në javë'},
  'cette semaine': {'en': 'this week', 'de': 'diese Woche', 'pt': 'esta semana', 'sq': 'këtë javë'},
  'Maximum': {'en': 'Maximum', 'de': 'Maximal', 'pt': 'Máximo', 'sq': 'Maksimumi'},
  "annulation possible jusqu'à": {'en': 'cancellation possible up to', 'de': 'Stornierung möglich bis', 'pt': 'cancelamento possível até', 'sq': 'anulimi i mundshëm deri në'},
  'avant': {'en': 'before', 'de': 'vorher', 'pt': 'antes', 'sq': 'para'},
  'Annulation impossible moins de': {'en': 'Cancellation not possible less than', 'de': 'Stornierung nicht möglich weniger als', 'pt': 'Cancelamento impossível menos de', 'sq': 'Anulimi nuk është i mundur më pak se'},
  'avant le créneau': {'en': 'before the slot', 'de': 'vor dem Termin', 'pt': 'antes do horário', 'sq': 'para orarin'},
  "Ce créneau vient d'être pris par quelqu'un d'autre.": {'en': 'This slot was just taken by someone else.', 'de': 'Dieser Termin wurde gerade von jemand anderem gebucht.', 'pt': 'Este horário acabou de ser reservado por outra pessoa.', 'sq': 'Ky orar sapo u rezervua nga dikush tjetër.'},
  "Notre équipe est présente dans l'immeuble": {'en': 'Our team is on site in the building', 'de': 'Unser Team ist im Gebäude vor Ort', 'pt': 'A nossa equipa está presente no prédio', 'sq': 'Ekipi ynë është i pranishëm në ndërtesë'},
  'Planning de la buanderie ou signaler un problème': {'en': 'Laundry schedule or report a problem', 'de': 'Waschplan oder Problem melden', 'pt': 'Horário da lavandaria ou comunicar um problema', 'sq': 'Orari i lavanderisë ose raporto një problem'},
  'Chaque': {'en': 'Every', 'de': 'Jeden', 'pt': 'Todas as', 'sq': 'Çdo'},
  'Mon créneau': {'en': 'My slot', 'de': 'Mein Termin', 'pt': 'O meu horário', 'sq': 'Orari im'},
  'Mon horaire fixe': {'en': 'My fixed schedule', 'de': 'Mein fester Termin', 'pt': 'O meu horário fixo', 'sq': 'Orari im i përhershëm'},
  "Aucun jour n'est attribué à votre appartement. Contactez la gérance.": {'en': 'No day is assigned to your apartment. Contact your property manager.', 'de': 'Ihrer Wohnung ist kein Tag zugewiesen. Kontaktieren Sie Ihre Verwaltung.', 'pt': 'Não há nenhum dia atribuído ao seu apartamento. Contacte a gerência.', 'sq': 'Asnjë ditë nuk i është caktuar apartamentit tuaj. Kontaktoni administratën.'},
  "Aucun jour n'est attribué à votre appartement pour le moment.": {'en': 'No day is assigned to your apartment yet.', 'de': 'Ihrer Wohnung ist noch kein Tag zugewiesen.', 'pt': 'Ainda não há dia atribuído ao seu apartamento.', 'sq': 'Apartamentit tuaj nuk i është caktuar ende asnjë ditë.'},
  'La buanderie est fermée.': {'en': 'The laundry room is closed.', 'de': 'Die Waschküche ist geschlossen.', 'pt': 'A lavandaria está fechada.', 'sq': 'Lavanderia është e mbyllur.'},
  'Le planning est géré par la gérance. Pour changer de jour, contactez-la.': {'en': 'The schedule is managed by the property manager. To change your day, contact them.', 'de': 'Der Plan wird von der Verwaltung verwaltet. Für einen anderen Tag kontaktieren Sie sie.', 'pt': 'O planning é gerido pela gerência. Para mudar de dia, contacte-a.', 'sq': 'Planifikimi menaxhohet nga administrata. Për të ndryshuar ditën, kontaktojeni.'},
  "Le planning de la buanderie n'est pas encore activé.": {'en': 'The laundry schedule is not active yet.', 'de': 'Der Waschplan ist noch nicht aktiviert.', 'pt': 'O planning da lavandaria ainda não está ativo.', 'sq': 'Planifikimi i lavanderisë nuk është aktivizuar ende.'},
  'Suivi de votre demande': {'en': 'Your request status', 'de': 'Status Ihrer Anfrage', 'pt': 'Estado do seu pedido', 'sq': 'Gjendja e kërkesës suaj'},
  'Reçu': {'en': 'Received', 'de': 'Eingegangen', 'pt': 'Recebido', 'sq': 'Pranuar'},
  'En analyse': {'en': 'Under review', 'de': 'In Prüfung', 'pt': 'Em análise', 'sq': 'Në shqyrtim'},
  'Technicien planifié': {'en': 'Technician scheduled', 'de': 'Techniker geplant', 'pt': 'Técnico agendado', 'sq': 'Teknik i planifikuar'},
  'Résolu': {'en': 'Resolved', 'de': 'Gelöst', 'pt': 'Resolvido', 'sq': 'Zgjidhur'},
  'Passage prévu le': {'en': 'Visit planned on', 'de': 'Besuch geplant am', 'pt': 'Visita prevista em', 'sq': 'Vizita e planifikuar më'},
  'Les notifications sont désactivées : vous ne recevrez pas les alertes sur votre téléphone.': {'en': 'Notifications are off: you will not receive alerts on your phone.', 'de': 'Benachrichtigungen sind aus: Sie erhalten keine Hinweise auf Ihrem Handy.', 'pt': 'As notificações estão desligadas: não receberá os avisos no telemóvel.', 'sq': 'Njoftimet janë të çaktivizuara: nuk do të merrni paralajmërime në telefon.'},
  'Activer': {'en': 'Turn on', 'de': 'Aktivieren', 'pt': 'Ativar', 'sq': 'Aktivizo'},
  'WhatsApp conciergerie': {'en': 'Concierge WhatsApp', 'de': 'WhatsApp Concierge', 'pt': 'WhatsApp da conciergerie', 'sq': 'WhatsApp i konsjerzhit'},
  'Parler au service de conciergerie': {'en': 'Talk to the concierge service', 'de': 'Mit dem Concierge-Service sprechen', 'pt': 'Falar com o serviço de conciergerie', 'sq': 'Flisni me shërbimin e konsjerzhit'},
  "Envie de laver une autre fois ? Consultez le planning : si un créneau est libre (+), vous pouvez vous inscrire. Un seul créneau par jour : matin, après-midi ou soir. Respectez le planning : le non-respect peut entraîner le blocage de l'accès à la buanderie.": {'en': 'Want to wash again? Check the schedule: if a slot is free (+), you can sign up. Only one slot per day: morning, afternoon or evening. Respect the schedule: not doing so may lead to your laundry access being blocked.', 'de': 'Möchten Sie nochmals waschen? Prüfen Sie den Plan: Ist ein Termin frei (+), können Sie sich eintragen. Nur ein Termin pro Tag: morgens, nachmittags oder abends. Bitte halten Sie den Plan ein: Bei Verstößen kann der Zugang zur Waschküche gesperrt werden.', 'pt': 'Quer lavar outra vez? Veja o planning: se houver um horário livre (+), pode inscrever-se. Só um horário por dia: manhã, tarde ou noite. Respeite o planning: o incumprimento pode levar ao bloqueio do acesso à lavandaria.', 'sq': 'Doni të lani përsëri? Shikoni planifikimin: nëse një orar është i lirë (+), mund të regjistroheni. Vetëm një orar në ditë: mëngjes, pasdite ose mbrëmje. Respektoni planifikimin: mosrespektimi mund të çojë në bllokimin e hyrjes në lavanderi.'},
  'Le planning fixe est géré par la gérance. Pour changer votre jour fixe, contactez-la.': {'en': 'The fixed schedule is managed by the property manager. To change your fixed day, contact them.', 'de': 'Der feste Plan wird von der Verwaltung verwaltet. Für einen anderen festen Tag kontaktieren Sie sie.', 'pt': 'O planning fixo é gerido pela gerência. Para mudar o seu dia fixo, contacte-a.', 'sq': 'Planifikimi i përhershëm menaxhohet nga administrata. Për të ndryshuar ditën tuaj, kontaktojeni.'},
  'Mon appartement': {'en': 'My apartment', 'de': 'Meine Wohnung', 'pt': 'O meu apartamento', 'sq': 'Apartamenti im'},
  'Immeuble': {'en': 'Building', 'de': 'Gebäude', 'pt': 'Prédio', 'sq': 'Ndërtesa'},
  "Nous sommes présents dans l'immeuble": {'en': 'We are on site in the building', 'de': 'Wir sind im Gebäude vor Ort', 'pt': 'Estamos presentes no prédio', 'sq': 'Jemi të pranishëm në ndërtesë'},
  'matin': {'en': 'morning', 'de': 'vormittags', 'pt': 'manhã', 'sq': 'mëngjes'},
  'après-midi': {'en': 'afternoon', 'de': 'nachmittags', 'pt': 'tarde', 'sq': 'pasdite'},
  'journée': {'en': 'all day', 'de': 'ganztägig', 'pt': 'dia todo', 'sq': 'gjithë ditën'},
  'Demander ce créneau ?': {'en': 'Request this slot?', 'de': 'Diesen Termin anfragen?', 'pt': 'Pedir este horário?', 'sq': 'Të kërkohet ky orar?'},
  "L'administrateur vous attribuera ce créneau dans le planning et vous serez prévenu(e).": {'en': 'The administrator will assign you this slot in the schedule and let you know.', 'de': 'Der Administrator weist Ihnen diesen Termin im Plan zu und benachrichtigt Sie.', 'pt': 'O administrador atribui-lhe este horário no planning e avisa-o.', 'sq': "Administratori do t'ju caktojë këtë orar në planifikim dhe do t'ju njoftojë."},
  'Demandé': {'en': 'Requested', 'de': 'Angefragt', 'pt': 'Pedido', 'sq': 'Kërkuar'},
  'Demander': {'en': 'Request', 'de': 'Anfragen', 'pt': 'Pedir', 'sq': 'Kërko'},
  'Demande envoyée. Vous serez prévenu(e) quand le créneau sera attribué.': {'en': 'Request sent. You will be notified once the slot is assigned.', 'de': 'Anfrage gesendet. Sie werden benachrichtigt, sobald der Termin zugewiesen ist.', 'pt': 'Pedido enviado. Será avisado quando o horário for atribuído.', 'sq': 'Kërkesa u dërgua. Do të njoftoheni kur orari të caktohet.'},
  "Vous n'avez pas encore de créneau : touchez le + sur un créneau libre pour le demander. L'administrateur l'attribuera dans le planning et vous préviendra. ": {'en': 'You do not have a slot yet: tap + on a free slot to request it. The administrator will assign it in the schedule and notify you. ', 'de': 'Sie haben noch keinen Termin: tippen Sie auf + bei einem freien Termin, um ihn anzufragen. Der Administrator weist ihn im Plan zu und benachrichtigt Sie. ', 'pt': 'Ainda não tem horário: toque no + num horário livre para o pedir. O administrador atribui-o no planning e avisa-o. ', 'sq': "Nuk keni ende orar: prekni + në një orar të lirë për ta kërkuar. Administratori do ta caktojë dhe do t'ju njoftojë. "},
  "Un créneau libre du planning peut être utilisé ; un créneau occupé par un autre locataire ne peut pas l'être. Le non-respect du planning peut entraîner votre retrait du système.": {'en': 'A free slot in the schedule may be used; a slot taken by another tenant may not. Not respecting the schedule may lead to your removal from the system.', 'de': 'Ein freier Termin im Plan darf genutzt werden; ein von einem anderen Mieter belegter nicht. Bei Nichtbeachtung kann Ihr Zugang zum System entzogen werden.', 'pt': 'Um horário livre no planning pode ser utilizado; um horário ocupado por outro locatário não pode. O incumprimento do planning pode levar à sua remoção do sistema.', 'sq': 'Një orar i lirë në planifikim mund të përdoret; një orar i zënë nga një qiramarrës tjetër jo. Mosrespektimi mund të çojë në heqjen tuaj nga sistemi.'},
};

/// Botão de idioma (canto superior esquerdo). [light] = texto branco sobre o gradiente.
class LangButton extends StatelessWidget {
  const LangButton({super.key, this.light = false});
  final bool light;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
        valueListenable: L.lang,
        builder: (context, code, _) {
          final fg = light ? m.Colors.white : m.Theme.of(context).colorScheme.onSurface;
          return m.PopupMenuButton<String>(
            tooltip: tr('Langue'),
            position: m.PopupMenuPosition.under,
            onSelected: L.change,
            itemBuilder: (_) => [
              for (final e in L.langs.entries)
                m.PopupMenuItem<String>(value: e.key, child: Row(children: [m.Text(L.flags[e.key]!, style: const TextStyle(fontSize: 20)), const SizedBox(width: 12), m.Text(e.value, style: TextStyle(fontWeight: e.key == code ? FontWeight.w800 : FontWeight.w500)), if (e.key == code) ...[const SizedBox(width: 8), const m.Icon(m.Icons.check_rounded, size: 18)]])),
            ],
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 7, 12, 7),
              decoration: BoxDecoration(color: fg.withValues(alpha: .16), borderRadius: BorderRadius.circular(30), border: Border.all(color: fg.withValues(alpha: .25))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                m.Text(L.flags[code]!, style: const TextStyle(fontSize: 17)),
                const SizedBox(width: 6),
                m.Text(code.toUpperCase(), style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(width: 2),
                m.Icon(m.Icons.keyboard_arrow_down_rounded, size: 18, color: fg),
              ]),
            ),
          );
        },
      );
}
