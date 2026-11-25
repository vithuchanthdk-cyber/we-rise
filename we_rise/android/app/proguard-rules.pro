# WE RISE — ProGuard / R8 rules
# Keep MainActivity and Android components
-keep class com.werise.chennai.MainActivity { *; }

# Keep Flutter/Dart entry points
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Hive
-keep class com.hivedb.** { *; }
-keepclassmembers class * extends com.hivedb.hive.HiveObject { *; }

# Supabase / Postgres / Realtime
-keep class io.supabase.** { *; }
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# speech_to_text
-keep class com.csdcorp.speechToText.** { *; }

# geolocator
-keep class com.baseflow.geolocator.** { *; }

# image_picker / flutter_image_compress
-keep class com.mr.flutter.plugin.** { *; }
-keep class io.flutter.plugins.imagepicker.** { *; }

# Keep data classes (Dart-compiled code is AOT — this is mainly for Java interop)
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
    public static int i(...);
}
