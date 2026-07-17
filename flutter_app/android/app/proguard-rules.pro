# R8/ProGuard keep rules for release builds (docs/09-security-design.md §10).

# mobile_scanner uses ML Kit / CameraX on Android via reflection.
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_barcode.** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.**
