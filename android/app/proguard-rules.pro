# R8 keep rules for the release build (see build.gradle.kts).
# Flutter's own rules are contributed by the Flutter Gradle plugin; these cover
# plugins that reach into their classes reflectively.

# flutter_local_notifications serialises scheduled notifications with Gson.
-keep class com.dexterous.** { *; }
-keepattributes *Annotation*, Signature
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# home_widget: the widget provider is referenced from the manifest.
-keep class es.antonborri.home_widget.** { *; }
