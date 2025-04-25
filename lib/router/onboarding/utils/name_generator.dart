import 'dart:math';

/// A service that generates unique and creative usernames with infinite possibilities
class NameGenerator {
  static final Random _random = Random();

  /// Generates a color using HSL color space for infinite possibilities
  static String _generateColor() {
    final hue = _random.nextInt(360); // Full color wheel
    final saturation = 70 + _random.nextInt(31); // 70-100% for vivid colors
    final lightness = 35 + _random.nextInt(31); // 35-65% for visible colors

    // Add luminosity prefix with 30% chance
    String colorName = '';
    if (_random.nextInt(10) < 3) {
      if (lightness < 40)
        colorName += 'Dark';
      else if (lightness > 60)
        colorName += 'Bright';
      else
        colorName += 'Deep';
    }

    // Add saturation prefix with 20% chance
    if (saturation > 90 && _random.nextInt(10) < 2) {
      colorName += 'Vivid';
    }

    // Generate base color name from hue
    if (hue < 15 || hue >= 345)
      colorName += 'Red';
    else if (hue < 45)
      colorName += 'Orange';
    else if (hue < 75)
      colorName += 'Yellow';
    else if (hue < 105)
      colorName += 'Green';
    else if (hue < 135)
      colorName += 'Emerald';
    else if (hue < 165)
      colorName += 'Turquoise';
    else if (hue < 195)
      colorName += 'Cyan';
    else if (hue < 225)
      colorName += 'Blue';
    else if (hue < 255)
      colorName += 'Indigo';
    else if (hue < 285)
      colorName += 'Purple';
    else if (hue < 315)
      colorName += 'Magenta';
    else
      colorName += 'Rose';

    // Add crystal/metal variants with 10% chance
    if (_random.nextInt(10) == 0) {
      final crystals = [
        'Crystal',
        'Gem',
        'Glass',
        'Metal',
        'Steel',
        'Iron',
        'Gold',
        'Silver'
      ];
      return crystals[_random.nextInt(crystals.length)];
    }

    return colorName;
  }

  /// Generates a simple animal name
  static String _generateAnimal() {
    final animals = [
      // Big Cats
      'Lion', 'Tiger', 'Leopard', 'Jaguar', 'Panther', 'Lynx', 'Puma',
      'Cheetah', 'Cougar', 'Ocelot',

      // Canines
      'Wolf', 'Fox', 'Coyote', 'Jackal', 'Dingo', 'Husky', 'Shepherd', 'Hound',
      'Collie', 'Dhole',

      // Birds of Prey
      'Eagle', 'Hawk', 'Falcon', 'Owl', 'Kite', 'Osprey', 'Harrier', 'Vulture',
      'Condor', 'Kestrel',

      // Dragons and Wyrms
      'Dragon', 'Wyrm', 'Drake', 'Wyvern', 'Hydra', 'Serpent', 'Leviathan',
      'Amphiptere', 'Lindworm', 'Salamander',

      // Mythical Equines
      'Unicorn', 'Pegasus', 'Kirin', 'Sleipnir', 'Hippocampus', 'Alicorn',
      'Kelpie', 'Hippogriff', 'Centaur',

      // Bears and Large Mammals
      'Bear', 'Panda', 'Gorilla', 'Bison', 'Moose', 'Elk', 'Deer', 'Boar',
      'Rhino', 'Hippo',

      // Sea Creatures
      'Dolphin', 'Whale', 'Shark', 'Orca', 'Seal', 'Walrus', 'Narwhal', 'Ray',
      'Octopus', 'Turtle',

      // Dragons and Wyrms
      'Dragon', 'Wyrm', 'Drake', 'Wyvern', 'Hydra', 'Serpent', 'Leviathan',
      'Amphiptere', 'Lindworm', 'Salamander',

      // Mythical Equines
      'Unicorn', 'Pegasus', 'Kirin', 'Sleipnir', 'Hippocampus', 'Alicorn',
      'Nightmare', 'Kelpie', 'Hippogriff', 'Centaur',

      // Mythical Felines
      'Sphinx', 'Manticore', 'Nemean', 'Chimera', 'Cait Sith', 'Bastet',
      'Sekhmet', 'Pixiu', 'Tatzelwurm', 'Coeurl',

      // Mythical Birds
      'Phoenix', 'Griffin', 'Roc', 'Thunderbird', 'Garuda', 'Simurgh', 'Feng',
      'Strix', 'Caladrius', 'Bennu',

      // Sea Monsters
      'Kraken', 'Charybdis', 'Scylla', 'Nessie', 'Selkie', 'Siren', 'Cecaelia',
      'Nereid', 'Triton', 'Leviathan',

      // Eastern Mythology
      'Qilin', 'Dragon', 'Fenghuang', 'Baku', 'Kappa', 'Tanuki', 'Kitsune',
      'Nekomata', 'Raiju', 'Byakko',

      // Western Mythology
      'Basilisk', 'Cockatrice', 'Gryphon', 'Minotaur', 'Cerberus', 'Harpy',
      'Medusa', 'Cyclops', 'Satyr', 'Pegasus',

      // Northern Mythology
      'Valkyrie', 'Draugr', 'Fenrir', 'Jormungandr', 'Nidhogg', 'Krampus',
      'Wendigo', 'Banshee', 'Selkie', 'Troll',

      // Guardian Spirits
      'Guardian', 'Sentinel', 'Watcher', 'Keeper', 'Protector', 'Aegis',
      'Golem', 'Gargoyle', 'Familiar', 'Djinn',

      // Mystical Hybrids
      'Chimera', 'Manticore', 'Griffin', 'Sphinx', 'Pegasus', 'Unicorn',
      'Dragon', 'Phoenix', 'Hydra', 'Kirin'
    ];
    return animals[_random.nextInt(animals.length)];
  }

  /// Generates a random username using infinite color + animal + number combinations
  static String generateRandomName() {
    final color = _generateColor();
    final animal = _generateAnimal();
    final number = 1 + _random.nextInt(100); // Range from 1 to 100

    return '$color$animal.$number';
  }

  /// Generates a list of unique random names
  static List<String> generateMultipleNames(int count) {
    final Set<String> names = {};
    while (names.length < count) {
      names.add(generateRandomName());
    }
    return names.toList();
  }
}
