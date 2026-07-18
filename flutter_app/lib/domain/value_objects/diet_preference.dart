/// Dietary preference used to filter recipe suggestions.
enum DietPreference {
  omnivore('omnivore'),
  vegetarian('vegetarian'),
  vegan('vegan');

  const DietPreference(this.wire);

  final String wire;

  static DietPreference fromWire(String wire) => values.firstWhere(
    (d) => d.wire == wire,
    orElse: () => DietPreference.omnivore,
  );
}
