# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase
-keepattributes Signature
-keepattributes *Annotation*

# Google Generative AI
-keep class com.google.generativeai.** { *; }

# Hive
-keep class com.hive_ce.** { *; }

# Keep generic signatures
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Play Core (required for deferred components)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
