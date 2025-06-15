import 'dart:math';

/// Generates fake names using adjectives and animals in different languages
class FakeNameGenerator {
  static final Random _random = Random();

  // English
  static const List<String> _adjectivesEn = [
    "Brave", "Clever", "Swift", "Gentle", "Fierce", "Mighty", "Nimble", "Quiet", "Lively", "Bold",
    "Curious", "Daring", "Eager", "Friendly", "Gallant", "Happy", "Jolly", "Kind", "Lucky", "Merry",
    "Noble", "Playful", "Quick", "Silly", "Witty", "Zany", "Charming", "Dazzling", "Energetic", "Fearless",
    "Graceful", "Humble", "Inventive", "Jovial", "Keen", "Loyal", "Mysterious", "Nifty", "Optimistic", "Patient",
    "Quirky", "Radiant", "Sincere", "Thoughtful", "Upbeat", "Vivid", "Wise", "Youthful", "Zealous", "Adventurous",
    "Bouncy", "Calm", "Dreamy", "Excited", "Funky", "Gleeful", "Heroic", "Imaginative", "Jazzy", "Kindhearted",
    "Magnificent", "Brilliant", "Creative", "Delightful", "Fantastic", "Gorgeous", "Inspiring", "Joyful", "Luminous", "Magical"
  ];

  static const List<String> _animalsEn = [
    "Lion", "Tiger", "Bear", "Wolf", "Fox", "Eagle", "Hawk", "Falcon", "Panther", "Leopard",
    "Jaguar", "Cheetah", "Otter", "Beaver", "Rabbit", "Hare", "Squirrel", "Deer", "Moose", "Elk",
    "Buffalo", "Bison", "Horse", "Zebra", "Giraffe", "Elephant", "Rhino", "Hippo", "Monkey", "Gorilla",
    "Chimpanzee", "Orangutan", "Koala", "Kangaroo", "Wallaby", "Wombat", "Sloth", "Armadillo", "Opossum", "Raccoon",
    "Badger", "Weasel", "Mink", "Ferret", "Skunk", "Porcupine", "Hedgehog", "Bat", "Mole", "Shrew",
    "Dog", "Cat", "Mouse", "Rat", "Hamster", "Gerbil", "GuineaPig", "Goat", "Sheep", "Pig",
    "Cow", "Bull", "Ox", "Camel", "Llama", "Alpaca", "Antelope", "Gazelle", "Reindeer", "Caribou",
    "Seal", "Walrus", "SeaLion", "Dolphin", "Whale", "Shark", "Octopus", "Squid", "Crab", "Lobster",
    "Shrimp", "Jellyfish", "Starfish", "Seahorse", "Penguin", "Puffin", "Albatross", "Pelican", "Swan", "Goose",
    "Duck", "Chicken", "Rooster", "Turkey", "Peacock", "Pigeon", "Dove", "Crow", "Raven", "Magpie"
  ];

  // Spanish
  static const List<String> _adjectivesEs = [
    "Valiente", "Inteligente", "Rápido", "Gentil", "Feroz", "Poderoso", "Ágil", "Tranquilo", "Vivaz", "Audaz",
    "Curioso", "Atrevido", "Ansioso", "Amigable", "Galante", "Feliz", "Alegre", "Amable", "Afortunado", "Divertido",
    "Noble", "Juguetón", "Veloz", "Gracioso", "Ingenioso", "Loco", "Encantador", "Deslumbrante", "Energético", "Intrépido",
    "Elegante", "Humilde", "Inventivo", "Jovial", "Perspicaz", "Leal", "Misterioso", "Genial", "Optimista", "Paciente",
    "Peculiar", "Radiante", "Sincero", "Reflexivo", "Animado", "Vívido", "Sabio", "Juvenil", "Entusiasta", "Aventurero",
    "Saltarín", "Calmado", "Soñador", "Emocionado", "Funky", "Gozoso", "Heroico", "Imaginativo", "Musical", "Bondadoso",
    "Magnífico", "Brillante", "Creativo", "Encantador", "Fantástico", "Hermoso", "Inspirador", "Gozoso", "Luminoso", "Mágico"
  ];

  static const List<String> _animalsEs = [
    "León", "Tigre", "Oso", "Lobo", "Zorro", "Águila", "Halcón", "Halcón", "Pantera", "Leopardo",
    "Jaguar", "Guepardo", "Nutria", "Castor", "Conejo", "Liebre", "Ardilla", "Ciervo", "Alce", "Alce",
    "Búfalo", "Bisonte", "Caballo", "Cebra", "Jirafa", "Elefante", "Rinoceronte", "Hipopótamo", "Mono", "Gorila",
    "Chimpancé", "Orangután", "Koala", "Canguro", "Wallaby", "Wombat", "Perezoso", "Armadillo", "Zarigüeya", "Mapache",
    "Tejón", "Comadreja", "Visón", "Hurón", "Mofeta", "Puercoespín", "Erizo", "Murciélago", "Topo", "Musaraña",
    "Perro", "Gato", "Ratón", "Rata", "Hámster", "Gerbil", "Cobaya", "Cabra", "Oveja", "Cerdo",
    "Vaca", "Toro", "Buey", "Camello", "Llama", "Alpaca", "Antílope", "Gacela", "Reno", "Caribú",
    "Foca", "Morsa", "León Marino", "Delfín", "Ballena", "Tiburón", "Pulpo", "Calamar", "Cangrejo", "Langosta",
    "Camarón", "Medusa", "Estrella de Mar", "Caballito de Mar", "Pingüino", "Frailecillo", "Albatros", "Pelícano", "Cisne", "Ganso",
    "Pato", "Pollo", "Gallo", "Pavo", "Pavo Real", "Paloma", "Paloma", "Cuervo", "Cuervo", "Urraca"
  ];

  // French
  static const List<String> _adjectivesFr = [
    "Brave", "Intelligent", "Rapide", "Gentil", "Féroce", "Puissant", "Agile", "Tranquille", "Vivant", "Audacieux",
    "Curieux", "Osé", "Impatient", "Amical", "Galant", "Heureux", "Joyeux", "Gentil", "Chanceux", "Joyeux",
    "Noble", "Joueur", "Rapide", "Drôle", "Spirituel", "Fou", "Charmant", "Éblouissant", "Énergique", "Intrépide",
    "Gracieux", "Humble", "Inventif", "Jovial", "Perspicace", "Loyal", "Mystérieux", "Formidable", "Optimiste", "Patient",
    "Bizarre", "Radieux", "Sincère", "Réfléchi", "Optimiste", "Vif", "Sage", "Jeune", "Zélé", "Aventureux",
    "Bondissant", "Calme", "Rêveur", "Excité", "Funky", "Joyeux", "Héroïque", "Imaginatif", "Musical", "Bienveillant"
  ];

  static const List<String> _animalsFr = [
    "Lion", "Tigre", "Ours", "Loup", "Renard", "Aigle", "Faucon", "Faucon", "Panthère", "Léopard",
    "Jaguar", "Guépard", "Loutre", "Castor", "Lapin", "Lièvre", "Écureuil", "Cerf", "Élan", "Élan",
    "Buffle", "Bison", "Cheval", "Zèbre", "Girafe", "Éléphant", "Rhinocéros", "Hippopotame", "Singe", "Gorille",
    "Chimpanzé", "Orang-outan", "Koala", "Kangourou", "Wallaby", "Wombat", "Paresseux", "Tatou", "Opossum", "Raton Laveur",
    "Blaireau", "Belette", "Vison", "Furet", "Mouffette", "Porc-épic", "Hérisson", "Chauve-souris", "Taupe", "Musaraigne",
    "Chien", "Chat", "Souris", "Rat", "Hamster", "Gerbille", "Cochon d'Inde", "Chèvre", "Mouton", "Porc",
    "Vache", "Taureau", "Bœuf", "Chameau", "Lama", "Alpaga", "Antilope", "Gazelle", "Renne", "Caribou",
    "Phoque", "Morse", "Lion de Mer", "Dauphin", "Baleine", "Requin", "Pieuvre", "Calmar", "Crabe", "Homard"
  ];

  // German
  static const List<String> _adjectivesDe = [
    "Mutig", "Klug", "Schnell", "Sanft", "Wild", "Mächtig", "Flink", "Ruhig", "Lebhaft", "Kühn",
    "Neugierig", "Gewagt", "Eifrig", "Freundlich", "Galant", "Glücklich", "Fröhlich", "Freundlich", "Glücklich", "Munter",
    "Edel", "Verspielt", "Schnell", "Lustig", "Witzig", "Verrückt", "Charmant", "Blendend", "Energisch", "Furchtlos",
    "Anmutig", "Bescheiden", "Erfinderisch", "Jovial", "Scharfsinnig", "Treu", "Geheimnisvoll", "Toll", "Optimistisch", "Geduldig",
    "Eigenartig", "Strahlend", "Aufrichtig", "Nachdenklich", "Heiter", "Lebhaft", "Weise", "Jugendlich", "Eifrig", "Abenteuerlustig"
  ];

  static const List<String> _animalsDe = [
    "Löwe", "Tiger", "Bär", "Wolf", "Fuchs", "Adler", "Falke", "Falke", "Panther", "Leopard",
    "Jaguar", "Gepard", "Otter", "Biber", "Kaninchen", "Hase", "Eichhörnchen", "Hirsch", "Elch", "Elch",
    "Büffel", "Bison", "Pferd", "Zebra", "Giraffe", "Elefant", "Nashorn", "Nilpferd", "Affe", "Gorilla",
    "Schimpanse", "Orang-Utan", "Koala", "Känguru", "Wallaby", "Wombat", "Faultier", "Gürteltier", "Opossum", "Waschbär",
    "Dachs", "Wiesel", "Nerz", "Frettchen", "Stinktier", "Stachelschwein", "Igel", "Fledermaus", "Maulwurf", "Spitzmaus",
    "Hund", "Katze", "Maus", "Ratte", "Hamster", "Rennmaus", "Meerschweinchen", "Ziege", "Schaf", "Schwein",
    "Kuh", "Stier", "Ochse", "Kamel", "Lama", "Alpaka", "Antilope", "Gazelle", "Rentier", "Karibu"
  ];

  // Japanese (in romaji for easier display)
  static const List<String> _adjectivesJa = [
    "Yuukan", "Kashikoi", "Hayai", "Yasashii", "Hageshii", "Tsuyoi", "Subayai", "Shizuka", "Genki", "Daitan",
    "Koukishin", "Yuukan", "Nesshin", "Shinsetsu", "Rippa", "Shiawase", "Tanoshii", "Shinsetsu", "Kōun", "Yukai",
    "Kōkō", "Asobizuki", "Subayai", "Okashii", "Kichi", "Okashi", "Miryoku", "Kagayaku", "Genki", "Daitan",
    "Yūga", "Kenkyo", "Sōzō", "Yōki", "Surudoi", "Chūjitsu", "Shinpi", "Subarashii", "Rakkan", "Nintai"
  ];

  static const List<String> _animalsJa = [
    "Raion", "Tora", "Kuma", "Ōkami", "Kitsune", "Washi", "Taka", "Hayabusa", "Hyō", "Hyō",
    "Jagā", "Chīta", "Kawauso", "Bībā", "Usagi", "Nousagi", "Risu", "Shika", "Hera-jika", "Hera-jika",
    "Baffaro", "Baison", "Uma", "Shima-uma", "Kirin", "Zō", "Sai", "Kaba", "Saru", "Gorira",
    "Chinpanjī", "Ōran-utan", "Koara", "Kangarū", "Warabī", "Wonbatto", "Namakemono", "Arumadjiro", "Fukuro-nezumi", "Araiguma"
  ];

  // Korean (in romanized form)
  static const List<String> _adjectivesKo = [
    "Yongmanghan", "Ttokttokhan", "Ppareun", "Chakan", "Sanaun", "Himssen", "Nallaen", "Joyonghan", "Hwalgihan", "Damdamhan",
    "Gunggeumhan", "Gwagamhan", "Yeolsimhan", "Chinhan", "Meotjin", "Haengbokhan", "Jeulgeo-un", "Chakan", "Unjoheun", "Jeulgeo-un",
    "Gwijunghan", "Jangnanseureo-un", "Ppareun", "Useun", "Jaeminneun", "Michin", "Maeryeokjeok", "Nunbusin", "Energetic", "Yongmanghan"
  ];

  static const List<String> _animalsKo = [
    "Saja", "Horangi", "Gom", "Neukdae", "Yeou", "Doksu-ri", "Mae", "Songol-mae", "Pyo-beom", "表豹",
    "Jagueo", "Chita", "Su-dal", "Bibe", "Tokki", "San-tokki", "Daramjwi", "Sasum", "Keun-sasum", "Keun-sasum",
    "Mulgwi", "들소", "Mal", "Eolruk-mal", "Girin", "Kokkiri", "Ppul-so", "Hama", "Wonsung-i", "Gorilla"
  ];

  // Arabic (transliterated)
  static const List<String> _adjectivesAr = [
    "Shujaa", "Dhaki", "Sari", "Latif", "Qawi", "Azim", "Rashi", "Hadi", "Nashit", "Jari",
    "Fadil", "Muqdam", "Harees", "Wadud", "Najib", "Farih", "Bahij", "Karim", "Mubarak", "Munis",
    "Sharif", "Lahib", "Sari", "Zarif", "Aqil", "Ajib", "Fattin", "Bahir", "Qawi", "Miqdam",
    "Jamil", "Mutawadi", "Mubtakir", "Bashar", "Fatin", "Wafi", "Ghareeb", "Ajib", "Mutafail", "Sabur"
  ];

  static const List<String> _animalsAr = [
    "Asad", "Nimr", "Dubb", "Dhib", "Thalab", "Nisr", "Baz", "Saqr", "Fahd", "Namr",
    "Jaguar", "Fahd", "Qundus", "Qastor", "Arnab", "Arnab", "Sinjab", "Ayil", "Ayil", "Ayil",
    "Jamusة", "Bisun", "Hisan", "Himar", "Zarafة", "Fil", "Karkadan", "Faras", "Qird", "Ghurillaة",
    "Shimpanzi", "Urangutan", "Kuwala", "Kanghar", "Walabi", "Wumbat", "Kasal", "Madara", "Jarf", "Rakun"
  ];

  // Chinese (Pinyin)
  static const List<String> _adjectivesZh = [
    "Yǒnggǎn", "Cōngmíng", "Kuài", "Wēnróu", "Měngliè", "Qiáng", "Mǐnjié", "Ānjìng", "Huólì", "Dàdǎn",
    "Hàoqí", "Dàdǎn", "Rèqíng", "Yǒuhǎo", "Yīngxióng", "Kuàilè", "Huānlè", "Shànliáng", "Xìngyùn", "Huānlè",
    "Gāoshàng", "Wánpí", "Kuài", "Yǒuqù", "Jīzhì", "Fēngkuáng", "Mírén", "Xuànyì", "Jīngqí", "Wúwèi",
    "Yōuyǎ", "Qiānxū", "Fāmíng", "Kuàilè", "Mǐnruì", "Zhōngchéng", "Shénmì", "Bàng", "Lèguān", "Nàixīn"
  ];

  static const List<String> _animalsZh = [
    "Shīzi", "Lǎohǔ", "Xióng", "Láng", "Húli", "Lǎoyīng", "Lǎoyīng", "Sǔnjiǎo", "Huābào", "Huābào",
    "Měizhōu Bào", "Liè Bào", "Shuǐtǎ", "Hǎilí", "Tùzi", "Yětù", "Sōngshǔ", "Lù", "Tuólù", "Tuólù",
    "Shuǐniú", "Yěniú", "Mǎ", "Bānmǎ", "Chángjǐnglù", "Dàxiàng", "Xīniú", "Hémǎ", "Hóuzi", "Dàxīngxīng",
    "Hēixīngxīng", "Hóngmáoxīngxīng", "Kǎolā", "Dàishǔ", "Xiǎo Dàishǔ", "Wōngbā", "Shùlǎn", "Cìwèi", "Fùshǔ", "Huànxióng"
  ];

  // Hindi (transliterated)
  static const List<String> _adjectivesHi = [
    "Bahadur", "Hoshiyar", "Tez", "Komal", "Takkatvar", "Majboot", "Phurteela", "Shaant", "Jinda-dil", "Himmatwala",
    "Jigyasu", "Diler", "Utsuk", "Mittra", "Shahsawar", "Khush", "Khushi", "Dayalu", "Khushkismat", "Masti",
    "Shriman", "Khelmaan", "Tej", "Hasaane", "Chalak", "Paagal", "Mohak", "Chamakdaar", "Urjawaan", "Nidar"
  ];

  static const List<String> _animalsHi = [
    "Sher", "Baagh", "Bhaalu", "Bhediya", "Lomdi", "Garud", "Baaj", "Shaheen", "Cheetah", "Tendua",
    "Jaguar", "Cheetah", "Udbilao", "Oondbilao", "Khargosh", "Khargosh", "Gilahri", "Hiran", "Barasingha", "Barasingha",
    "Bhains", "Jangli Bhains", "Ghoda", "Zebra", "Jiraaf", "Haathi", "Gainda", "Dariyaai Ghoda", "Bandar", "Gorilla"
  ];

  /// Map of language codes to their word lists
  static const Map<String, Map<String, List<String>>> _languageWords = {
    'en': {'adjectives': _adjectivesEn, 'animals': _animalsEn},
    'es': {'adjectives': _adjectivesEs, 'animals': _animalsEs},
    'fr': {'adjectives': _adjectivesFr, 'animals': _animalsFr},
    'de': {'adjectives': _adjectivesDe, 'animals': _animalsDe},
    'ja': {'adjectives': _adjectivesJa, 'animals': _animalsJa},
    'ko': {'adjectives': _adjectivesKo, 'animals': _animalsKo},
    'ar': {'adjectives': _adjectivesAr, 'animals': _animalsAr},
    'zh': {'adjectives': _adjectivesZh, 'animals': _animalsZh},
    'hi': {'adjectives': _adjectivesHi, 'animals': _animalsHi},
  };

  /// Generates a fake name based on the given language code
  static String generateFakeName(String languageCode) {
    // Get the base language code (e.g., 'en' from 'en_US')
    String baseLanguage = languageCode.split('_')[0].toLowerCase();
    
    // Default to English if language not supported
    if (!_languageWords.containsKey(baseLanguage)) {
      baseLanguage = 'en';
    }

    final words = _languageWords[baseLanguage]!;
    final adjectives = words['adjectives']!;
    final animals = words['animals']!;

    final adjective = adjectives[_random.nextInt(adjectives.length)];
    final animal = animals[_random.nextInt(animals.length)];

    return '$adjective $animal';
  }

  /// Get list of supported language codes
  static List<String> getSupportedLanguages() {
    return _languageWords.keys.toList();
  }
}