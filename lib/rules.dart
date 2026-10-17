/// Règles de bien-être de l'immeuble (reprises de l'application d'origine).
/// Modifier ce fichier pour adapter les règles à une autre gérance.
class WellbeingSection {
  const WellbeingSection(this.title, this.items);
  final String title;
  final List<String> items;
}

const wellbeingIntro = 'Pour assurer un environnement harmonieux et agréable pour tous les résidents, veuillez respecter les règles suivantes:';
const wellbeingOutro = 'Ces règles sont établies pour assurer le bien-être de tous les résidents. Merci de votre coopération pour maintenir un environnement agréable dans notre immeuble.';
const wellbeingSections = <WellbeingSection>[
  WellbeingSection('Dispositions générales', [
    'Tolérance/tolérance zéro: nous nous engageons pour une cohabitation empreinte de tolérance. Nous pratiquons la tolérance zéro à l\'égard de toute forme de harcelement, de discrimination ou de comportement inapproprié.',
    'Service clients: utilisez nos canaux numériques (service ticketing/application si disponible) pour vos demandes générales.',
    'Cas d\'urgence: appelez immédiatement les numéros d\'urgence 117 (police)/118 (pompiers)/144 (ambulance) et informez les voisins.',
    'Prévention: gardez les accès géné raux et les portes d\'entrée toujours fermés. Signalez les comportements suspects à la police. Les cages d\'escalier et les sorties de secours doivent toujours être dégagées. Sur les balcons, n\'installez pas d\'objets tels que des meubles ou constructions/installations dont la hauteur dépasse la balustrade. Les pots de fleurs peuvent être installés uniquement à l\'intérieur du balcon.',
    'Installations techniques des bâtiments: il est interdit d\'enlever ou de manipuler les capteurs et les installations,',
    'Travaux de jardinage: respectez les régies locales en matière de bruit.',
    'Déchets: éliminez vos déchets conformément aux prescriptions en vigueur.',
  ]),
  WellbeingSection('Bruit', [
    'Heures de repos: 22h00 à 07h00.',
    'Protection contre le bruit: évitez les bruits excessifs, surtout lorsque vos fenêtres sont ouvertes. Vous pouvez écouter de la musique à un niveau sonore normal.',
    'Instruments de musique: vous pouvez jouer d\'un instrument en dehors des heures de repos, jusqu\'à 20h00 au plus tard, dans le respect de vos voisins sauf les dimanches et jours fériés.',
    'Aide aux voisins: les gens de tout age apprécient l\'échange avec leurs voisins. Un petit coup de main peut avoir de grands effets.',
    'Chaleur/intempéries: veuillez consulter les prévisions météorologiques, les avis de tempête et les recommandations locales. En cas de précipitations et de vent fort, il faut remonter les stores extérieurs et les stores à lamelles et fermer les fenêtres.',
  ]),
  WellbeingSection('Espaces communs', [
    'Alentours: prenez soin des espaces verts, des plantes et des arbres. Annoncez les dommages au service d\'immeuble.',
    'Places de jeux: laissez les aires de jeux et de séjour propres.',
    'Buanderie: utilisez-la de manière responsable. Pensez à vos voisins. L\'utilisation du lave-linge et du sèche-linge est interdite pendant la nuit (de 22h00 à 07h00),',
  ]),
  WellbeingSection('Mobilité', [
    'Mobilité électrique: nous soutenons activement la mobilité électrique. N\'hésitez pas à nous contacter au besoin.',
    'Visiteurs: les visiteurs doivent garer leur véhicule sur les places visiteurs ou des places de sta-tionnement publiques pour des périodes courtes uniquement. Les locataires ne sont pas autorisés à y parquer leurs propres véhicules.',
    'Vélos et scooters: garez vos véhicules dans les zones réservées à cet effet.',
    'Ascenseur: respectez les consignes. Les enfants de moins de 10 ans doivent être accom-pagnés d\'un adulte.',
  ]),
  WellbeingSection('Entretien/nettoyage', [
    'Nettoyage: gardez votre appartement, la cave, les espaces.communs et les alentours propres.',
    'Entretien: les appareils électroménagers et les lave-linge doivent être entretenus régulièrement. Cela permet d\'économiser de l\'énergie et de prolonger leur durée de vie.',
    'Aération: aérez régulièrement votre appartement. Consultez notre site web pour des conseils.',
  ]),
];
