import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing preference order:
// 1. android/key.properties (local / production secrets, git-ignored)
// 2. committed CI keystore android/app/fridgeos-ci.jks (stable update signing)
// 3. debug keystore (last resort for local `flutter run --release`)
//
// Root cause of "must uninstall to install APK": CI previously fell back to the
// machine-local debug keystore, so each runner produced a different signature.
// Android rejects updates when the signing certificate changes.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val ciKeystoreFile = file("fridgeos-ci.jks")
val hasReleaseSigning = keystorePropertiesFile.exists()
val hasCiSigning = !hasReleaseSigning && ciKeystoreFile.exists()
if (hasReleaseSigning) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "com.fridgeos.fridgeos"
    // Prefer Flutter's default; keep a floor of 36 for current AndroidX plugins.
    compileSdk = maxOf(flutter.compileSdkVersion, 36)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by flutter_local_notifications (uses java.time APIs on older
        // Android via backported JDK libraries).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.fridgeos.fridgeos"
        // Android 8.0. See docs/03-non-functional-requirements.md NFR-COMPAT-1.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        } else if (hasCiSigning) {
            create("release") {
                keyAlias = "fridgeos"
                keyPassword = "fridgeos-ci-store"
                storeFile = ciKeystoreFile
                storePassword = "fridgeos-ci-store"
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning || hasCiSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // Shrink, obfuscate and strip unused resources (docs/09 §10).
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Backports java.time and other JDK APIs so plugins that rely on them work
    // down to minSdk 26 (see compileOptions.isCoreLibraryDesugaringEnabled).
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
