import 'package:fridgeos/domain/value_objects/diet_preference.dart';

/// Offline multilingual ingredient normalization.
///
/// Product names entered in Italian, English, French, Spanish, German, Japanese
/// (and common variants) are mapped to a shared canonical id so recipe matching
/// does not require the user to type English.
final class IngredientLexicon {
  const IngredientLexicon();

  /// Quality adjectives that do not change the underlying food identity.
  static const _qualityModifiers = {
    'fresh',
    'fresco',
    'fresca',
    'frais',
    'fraiche',
    'frisch',
    'dried',
    'secco',
    'secca',
    'ground',
    'whole',
    'intero',
    'intera',
    'entier',
    'organic',
    'bio',
    'biologico',
    'free',
    'range',
    'extra',
    'virgin',
    'skimmed',
    'semi',
    'scremato',
    'parzialmente',
    'raw',
    'crude',
    'crudo',
    'chopped',
    'sliced',
    'diced',
    'minced',
  };

  /// Form words that create a distinct ingredient (sauce ≠ fresh produce).
  static const _formModifiers = {
    'sauce',
    'salsa',
    'paste',
    'concentrato',
    'juice',
    'succo',
    'jus',
    'oil',
    'olio',
    'huile',
    'aceite',
    'ol',
    'milk', // kept for "coconut milk" compound handling via phrase map
    'broth',
    'stock',
    'brodo',
  };

  /// Alias (normalized) → canonical ingredient id.
  static const Map<String, String> _aliases = {
    // Tomato
    'tomato': 'tomato',
    'tomatoes': 'tomato',
    'pomodoro': 'tomato',
    'pomodori': 'tomato',
    'tomate': 'tomato',
    'tomates': 'tomato',
    'tomat': 'tomato',
    'トマト': 'tomato',
    'とまと': 'tomato',
    // Tomato sauce (distinct)
    'tomato sauce': 'tomato_sauce',
    'passata': 'tomato_sauce',
    'salsa di pomodoro': 'tomato_sauce',
    'sauce tomate': 'tomato_sauce',
    'tomatensauce': 'tomato_sauce',
    // Pasta
    'pasta': 'pasta',
    'spaghetti': 'pasta',
    'penne': 'pasta',
    'fusilli': 'pasta',
    'macaroni': 'pasta',
    'noodle': 'pasta',
    'noodles': 'pasta',
    'ラーメン': 'pasta',
    // Olive oil
    'olive oil': 'olive_oil',
    'olio': 'olive_oil',
    'olio doliva': 'olive_oil',
    "olio d'oliva": 'olive_oil',
    'olio di oliva': 'olive_oil',
    'huile dolive': 'olive_oil',
    "huile d'olive": 'olive_oil',
    'aceite de oliva': 'olive_oil',
    'olivenol': 'olive_oil',
    'オリーブオイル': 'olive_oil',
    // Milk
    'milk': 'milk',
    'latte': 'milk',
    'latte intero': 'milk',
    'latte parzialmente scremato': 'milk',
    'lait': 'milk',
    'leche': 'milk',
    'milch': 'milk',
    '牛乳': 'milk',
    'ミルク': 'milk',
    // Cheese
    'cheese': 'cheese',
    'formaggio': 'cheese',
    'fromage': 'cheese',
    'queso': 'cheese',
    'kase': 'cheese',
    'käse': 'cheese',
    'チーズ': 'cheese',
    'parmesan': 'parmesan',
    'parmigiano': 'parmesan',
    'parmigiano reggiano': 'parmesan',
    // Eggs
    'egg': 'egg',
    'eggs': 'egg',
    'uovo': 'egg',
    'uova': 'egg',
    'oeuf': 'egg',
    'œuf': 'egg',
    'huevo': 'egg',
    'huevos': 'egg',
    'ei': 'egg',
    'eier': 'egg',
    '卵': 'egg',
    'たまご': 'egg',
    // Rice
    'rice': 'rice',
    'riso': 'rice',
    'riz': 'rice',
    'arroz': 'rice',
    'reis': 'rice',
    '米': 'rice',
    'ご飯': 'rice',
    'ごはん': 'rice',
    // Garlic
    'garlic': 'garlic',
    'aglio': 'garlic',
    'ail': 'garlic',
    'ajo': 'garlic',
    'knoblauch': 'garlic',
    'ニンニク': 'garlic',
    // Onion
    'onion': 'onion',
    'onions': 'onion',
    'cipolla': 'onion',
    'cipolle': 'onion',
    'oignon': 'onion',
    'cebolla': 'onion',
    'zwiebel': 'onion',
    '玉ねぎ': 'onion',
    // Potato
    'potato': 'potato',
    'potatoes': 'potato',
    'patata': 'potato',
    'patate': 'potato',
    'pomme de terre': 'potato',
    'pommes de terre': 'potato',
    'kartoffel': 'potato',
    'じゃがいも': 'potato',
    // Apple (avoid confusing with pomme de terre — phrase mapped above)
    'apple': 'apple',
    'apples': 'apple',
    'mela': 'apple',
    'mele': 'apple',
    'pomme': 'apple',
    'pommes': 'apple',
    'manzana': 'apple',
    'apfel': 'apple',
    'りんご': 'apple',
    // Butter
    'butter': 'butter',
    'burro': 'butter',
    'beurre': 'butter',
    'mantequilla': 'butter',
    'バター': 'butter',
    // Bread
    'bread': 'bread',
    'pane': 'bread',
    'pain': 'bread',
    'pan': 'bread',
    'brot': 'bread',
    'パン': 'bread',
    // Chicken
    'chicken': 'chicken',
    'pollo': 'chicken',
    'poulet': 'chicken',
    'huhn': 'chicken',
    'チキン': 'chicken',
    '鶏肉': 'chicken',
    // Beef
    'beef': 'beef',
    'manzo': 'beef',
    'boeuf': 'beef',
    'bœuf': 'beef',
    'carne de res': 'beef',
    'rindfleisch': 'beef',
    '牛肉': 'beef',
    // Fish
    'fish': 'fish',
    'pesce': 'fish',
    'poisson': 'fish',
    'pescado': 'fish',
    'fisch': 'fish',
    '魚': 'fish',
    // Tofu
    'tofu': 'tofu',
    '豆腐': 'tofu',
    // Vegetables (generic)
    'vegetables': 'vegetables',
    'vegetable': 'vegetables',
    'verdure': 'vegetables',
    'verdura': 'vegetables',
    'legumes': 'vegetables',
    'légumes': 'vegetables',
    'verduras': 'vegetables',
    'gemuse': 'vegetables',
    'gemüse': 'vegetables',
    '野菜': 'vegetables',
    // Lettuce / salad greens
    'lettuce': 'lettuce',
    'lattuga': 'lettuce',
    'laitue': 'lettuce',
    'lechuga': 'lettuce',
    'salat': 'lettuce',
    // Carrot
    'carrot': 'carrot',
    'carrots': 'carrot',
    'carota': 'carrot',
    'carote': 'carrot',
    'carotte': 'carrot',
    'zanahoria': 'carrot',
    'mohre': 'carrot',
    'にんじん': 'carrot',
    // Yogurt
    'yogurt': 'yogurt',
    'yoghurt': 'yogurt',
    'yogurt greco': 'yogurt',
    'yaourt': 'yogurt',
    'yogur': 'yogurt',
    'joghurt': 'yogurt',
    'ヨーグルト': 'yogurt',
    // Salt
    'salt': 'salt',
    'sale': 'salt',
    'sel': 'salt',
    'sal': 'salt',
    'salz': 'salt',
    '塩': 'salt',
    // Pepper (spice)
    'black pepper': 'black_pepper',
    'pepper': 'black_pepper',
    'pepe': 'black_pepper',
    'pepe nero': 'black_pepper',
    'poivre': 'black_pepper',
    'pimienta': 'black_pepper',
    'pfeffer': 'black_pepper',
    '胡椒': 'black_pepper',
    // Guanciale / bacon family — separate canons; substitutions handle swaps
    'guanciale': 'guanciale',
    'pancetta': 'pancetta',
    'bacon': 'bacon',
    // Soy sauce
    'soy sauce': 'soy_sauce',
    'salsa di soia': 'soy_sauce',
    'sauce soja': 'soy_sauce',
    '醤油': 'soy_sauce',
    // Miso
    'miso': 'miso',
    '味噌': 'miso',
    // Ginger
    'ginger': 'ginger',
    'zenzero': 'ginger',
    'gingembre': 'ginger',
    'jengibre': 'ginger',
    'ingwer': 'ginger',
    'しょうが': 'ginger',
    // Basil
    'basil': 'basil',
    'basilico': 'basil',
    'basilic': 'basil',
    'albahaca': 'basil',
    'basilikum': 'basil',
    // Mushrooms
    'mushroom': 'mushroom',
    'mushrooms': 'mushroom',
    'funghi': 'mushroom',
    'champignon': 'mushroom',
    'champignons': 'mushroom',
    'setas': 'mushroom',
    'pilze': 'mushroom',
    'きのこ': 'mushroom',
    // Beans / lentils
    'lentils': 'lentil',
    'lentil': 'lentil',
    'lenticchie': 'lentil',
    'lentilles': 'lentil',
    'lentejas': 'lentil',
    'linsen': 'lentil',
    // Spinach
    'spinach': 'spinach',
    'spinaci': 'spinach',
    'epinards': 'spinach',
    'épinards': 'spinach',
    'espinacas': 'spinach',
    'spinat': 'spinach',
    'ほうれん草': 'spinach',
  };

  /// Canonical ids that are related (partial match only).
  static const Map<String, Set<String>> _related = {
    'tomato': {'tomato_sauce', 'tomato_paste'},
    'tomato_sauce': {'tomato'},
    'tomato_paste': {'tomato'},
  };

  /// Animal-derived canonical ids for diet filtering.
  static const meatOrFish = {
    'chicken',
    'beef',
    'pork',
    'fish',
    'bacon',
    'guanciale',
    'pancetta',
    'shrimp',
    'lamb',
    'turkey',
  };

  static const animalDerived = {
    ...meatOrFish,
    'milk',
    'cheese',
    'parmesan',
    'butter',
    'egg',
    'yogurt',
    'honey',
    'cream',
  };

  /// Returns a language-agnostic canonical id, or `null` if unknown.
  String? canonicalize(String raw) {
    final normalized = normalize(raw);
    if (normalized.isEmpty) return null;

    final direct = _aliases[normalized];
    if (direct != null) return direct;

    // Prefer longer phrase matches inside the string.
    for (final entry in _aliases.entries) {
      if (entry.key.contains(' ') && normalized.contains(entry.key)) {
        return entry.value;
      }
    }

    final tokens = normalized
        .split(' ')
        .where((t) => t.isNotEmpty && !_qualityModifiers.contains(t))
        .toList();
    if (tokens.isEmpty) return null;

    final formBits = tokens.where(_formModifiers.contains).toList();
    final coreBits = tokens.where((t) => !_formModifiers.contains(t)).toList();

    if (coreBits.isEmpty) return null;

    final corePhrase = coreBits.join(' ');
    final coreCanon =
        _aliases[corePhrase] ??
        (coreBits.length == 1
            ? (_aliases[coreBits.first] ??
                  _aliases[_singular(coreBits.first)] ??
                  coreBits.first)
            : null);

    if (coreCanon == null && coreBits.length > 1) {
      // Map each token; if all map to one food, use it.
      final mapped = <String>{};
      for (final t in coreBits) {
        final c = _aliases[t] ?? _aliases[_singular(t)];
        if (c != null) mapped.add(c);
      }
      if (mapped.length == 1) {
        final base = mapped.single;
        if (formBits.isEmpty) return base;
        return '${base}_${formBits.join('_')}';
      }
      return null;
    }

    if (coreCanon == null) return null;
    if (formBits.isEmpty) return coreCanon;

    // Avoid "milk" form doubling when the core is already milk.
    final forms = formBits.where((f) => f != coreCanon).toList();
    if (forms.isEmpty) return coreCanon;
    return '${coreCanon}_${forms.join('_')}';
  }

  /// True when both names refer to the same canonical ingredient.
  bool isExactMatch(String a, String b) {
    final ca = canonicalize(a);
    final cb = canonicalize(b);
    if (ca != null && cb != null) return ca == cb;
    final na = normalize(a);
    final nb = normalize(b);
    if (na == nb) return true;
    return _singular(na) == _singular(nb);
  }

  /// True when names are related but not identical (e.g. tomato vs tomato sauce).
  bool isRelated(String a, String b) {
    final ca = canonicalize(a);
    final cb = canonicalize(b);
    if (ca == null || cb == null || ca == cb) return false;
    return _related[ca]?.contains(cb) ?? false;
  }

  /// Whether [name] is meat/fish for vegetarian filtering.
  bool isMeatOrFish(String name) {
    final c = canonicalize(name);
    return c != null && meatOrFish.contains(c);
  }

  /// Whether [name] is any animal-derived product for vegan filtering.
  bool isAnimalDerived(String name) {
    final c = canonicalize(name);
    return c != null && animalDerived.contains(c);
  }

  /// Normalize for lookup: lower-case, strip accents, collapse spaces.
  String normalize(String value) {
    var s = value.trim().toLowerCase();
    s = _stripAccents(s);
    s = s.replaceAll(RegExp(r"[’']"), '');
    s = s.replaceAll(RegExp(r'[^a-z0-9\u3040-\u30ff\u4e00-\u9fff\s]'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  String _singular(String normalized) {
    if (normalized.endsWith('ies') && normalized.length > 4) {
      return '${normalized.substring(0, normalized.length - 3)}y';
    }
    if (normalized.endsWith('oes') && normalized.length > 4) {
      return normalized.substring(0, normalized.length - 2);
    }
    if (normalized.endsWith('s') &&
        !normalized.endsWith('ss') &&
        normalized.length > 3) {
      return normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  String _stripAccents(String input) {
    const map = {
      'à': 'a',
      'á': 'a',
      'â': 'a',
      'ä': 'a',
      'è': 'e',
      'é': 'e',
      'ê': 'e',
      'ë': 'e',
      'ì': 'i',
      'í': 'i',
      'î': 'i',
      'ï': 'i',
      'ò': 'o',
      'ó': 'o',
      'ô': 'o',
      'ö': 'o',
      'ù': 'u',
      'ú': 'u',
      'û': 'u',
      'ü': 'u',
      'ñ': 'n',
      'ç': 'c',
      'œ': 'oe',
      'æ': 'ae',
    };
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);
      buffer.write(map[ch] ?? ch);
    }
    return buffer.toString();
  }
}

/// Diet compatibility helpers using [IngredientLexicon] + recipe tags.
final class RecipeDietPolicy {
  const RecipeDietPolicy([this._lexicon = const IngredientLexicon()]);

  final IngredientLexicon _lexicon;

  bool isCompatible({
    required List<String> tags,
    required Iterable<String> ingredientNames,
    required DietPreference diet,
  }) {
    if (diet == DietPreference.omnivore) return true;

    final normalizedTags = tags.map((t) => t.toLowerCase()).toSet();
    if (diet == DietPreference.vegan) {
      if (normalizedTags.contains('vegan')) return true;
      if (normalizedTags.contains('meat') ||
          normalizedTags.contains('fish') ||
          normalizedTags.contains('seafood') ||
          normalizedTags.contains('dairy')) {
        return false;
      }
    }
    if (diet == DietPreference.vegetarian) {
      if (normalizedTags.contains('vegan') ||
          normalizedTags.contains('vegetarian')) {
        // Still verify no meat slipped into ingredients.
      } else if (normalizedTags.contains('meat') ||
          normalizedTags.contains('fish') ||
          normalizedTags.contains('seafood')) {
        return false;
      }
    }

    for (final name in ingredientNames) {
      if (diet == DietPreference.vegetarian && _lexicon.isMeatOrFish(name)) {
        return false;
      }
      if (diet == DietPreference.vegan && _lexicon.isAnimalDerived(name)) {
        return false;
      }
    }
    return true;
  }
}
