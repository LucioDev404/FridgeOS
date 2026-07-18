import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing preference order:
// 1. On CI (GITHUB_ACTIONS/CI): always use committed android/app/fridgeos-ci.jks
// 2. Local android/key.properties (production secrets, git-ignored)
// 3. Committed CI keystore for local release builds without key.properties
// 4. Debug keystore (last resort)
//
// Root cause of "APK is a different application / must uninstall":
// Android requires the SAME signing certificate for updates. Older CI builds
// fell back to each runner's unique debug keystore, so each APK had a different
// signature while sharing applicationId com.fridgeos.fridgeos.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val ciKeystoreFile = file("fridgeos-ci.jks")
val isCi =
    System.getenv("GITHUB_ACTIONS") == "true" || System.getenv("CI") == "true"
val hasReleaseSigning = keystorePropertiesFile.exists()
val hasCiKeystore = ciKeystoreFile.exists()

// Prefer the stable CI keystore on GitHub Actions so every workflow APK updates
// in place. Local developers may still use key.properties for Play uploads.
val useCiKeystore = hasCiKeystore && (isCi || !hasReleaseSigning)
val useLocalReleaseSigning = hasReleaseSigning && !isCi

if (useLocalReleaseSigning) {
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
        if (useLocalReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        } else if (useCiKeystore) {
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
            val hasReleaseConfig =
                useLocalReleaseSigning || useCiKeystore
            signingConfig = if (hasReleaseConfig) {
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

// Fail CI loudly if the release build would still be debug-signed.
afterEvaluate {
    if (isCi && !useCiKeystore) {
        throw GradleException(
            "CI release builds require android/app/fridgeos-ci.jks so APKs share " +
                "one signing certificate and install as updates.",
        )
    }
    tasks.matching { it.name.contains("assembleRelease", ignoreCase = true) }.configureEach {
        doFirst {
            val configName = android.buildTypes.getByName("release").signingConfig?.name
            logger.lifecycle("FridgeOS release signingConfig=$configName (ci=$isCi, ciKeystore=$useCiKeystore)")
            if (isCi && configName != "release") {
                throw GradleException(
                    "Refusing to build a CI release APK without the release signing config.",
                )
            }
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
