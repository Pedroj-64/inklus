# =============================================================================
# ProGuard / R8 rules for Inklus release builds
# =============================================================================

# --- ML Kit ---
# ML Kit carga modelos vía reflect/dynamic loading; sin keep, R8 los elimina.
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Idiomas adicionales no usados
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google.mlkit.vision.digitalink.recognition.chinese.**
-dontwarn com.google.mlkit.vision.digitalink.recognition.japanese.**
-dontwarn com.google.mlkit.vision.digitalink.recognition.korean.**

# --- Google Sign-In ---
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-dontwarn com.google.android.gms.**

# --- Google APIs (googleapis / _discoveryapis_commons) ---
# Los clientes HTTP de Google usan reflección para parsear JSON.
-keep class com.google.api.client.** { *; }
-keep class com.google.common.** { *; }
-dontwarn com.google.api.client.**
-dontwarn com.google.common.**
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

# --- HTTP / IO ---
-keep class org.apache.http.** { *; }
-dontwarn org.apache.http.**
-dontwarn java.lang.instrument.ClassFileTransformer
-dontwarn sun.misc.Unsafe
-dontwarn com.google.errorprone.annotations.**

# --- Cryptography ---
-keep class com.goterl.lazycode.lazysodium.** { *; }
-dontwarn com.goterl.lazycode.lazysodium.**

# --- PDF / printing ---
-keep class com.itextpdf.** { *; }
-dontwarn com.itextpdf.**
