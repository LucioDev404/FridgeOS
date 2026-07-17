# R8/ProGuard keep rules for release builds (docs/09-security-design.md §10).

# Google ML Kit barcode scanning uses reflection into these packages.
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_barcode.** { *; }
-dontwarn com.google.mlkit.**

# ML Kit may reference optional text-recognition components not bundled here.
-dontwarn com.google.android.gms.**
