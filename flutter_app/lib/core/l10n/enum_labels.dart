import 'package:fridgeos/domain/value_objects/enums.dart';
import 'package:fridgeos/l10n/gen/app_localizations.dart';

/// Maps controlled domain enums to their localized display strings. Keeps the
/// mapping in one place so widgets never switch on `wire` values directly.
extension FoodCategoryLabel on FoodCategory {
  String label(AppLocalizations l10n) => switch (this) {
    FoodCategory.dairy => l10n.categoryDairy,
    FoodCategory.produce => l10n.categoryProduce,
    FoodCategory.meat => l10n.categoryMeat,
    FoodCategory.bakery => l10n.categoryBakery,
    FoodCategory.beverages => l10n.categoryBeverages,
    FoodCategory.frozen => l10n.categoryFrozen,
    FoodCategory.pantryStaple => l10n.categoryPantryStaple,
    FoodCategory.other => l10n.categoryOther,
  };
}

extension MeasurementUnitLabel on MeasurementUnit {
  String label(AppLocalizations l10n) => switch (this) {
    MeasurementUnit.pieces => l10n.unitPieces,
    MeasurementUnit.grams => l10n.unitGrams,
    MeasurementUnit.kilograms => l10n.unitKilograms,
    MeasurementUnit.milliliters => l10n.unitMilliliters,
    MeasurementUnit.liters => l10n.unitLiters,
    MeasurementUnit.pack => l10n.unitPack,
  };
}

extension LocationTypeLabel on LocationType {
  String label(AppLocalizations l10n) => switch (this) {
    LocationType.refrigerator => l10n.typeRefrigerator,
    LocationType.freezer => l10n.typeFreezer,
    LocationType.pantry => l10n.typePantry,
  };
}

extension InventoryEventTypeLabel on InventoryEventType {
  String label(AppLocalizations l10n) => switch (this) {
    InventoryEventType.addProduct => l10n.eventAddProduct,
    InventoryEventType.removeProduct => l10n.eventRemoveProduct,
    InventoryEventType.updateQuantity => l10n.eventUpdateQuantity,
    InventoryEventType.restock => l10n.eventRestock,
    InventoryEventType.manualCorrection => l10n.eventManualCorrection,
    InventoryEventType.changeLocation => l10n.eventChangeLocation,
    InventoryEventType.consume => l10n.eventConsume,
    InventoryEventType.discard => l10n.eventDiscard,
  };
}

extension RecipeDifficultyLabel on RecipeDifficulty {
  String label(AppLocalizations l10n) => switch (this) {
    RecipeDifficulty.easy => l10n.recipeDifficultyEasy,
    RecipeDifficulty.medium => l10n.recipeDifficultyMedium,
    RecipeDifficulty.hard => l10n.recipeDifficultyHard,
  };
}
