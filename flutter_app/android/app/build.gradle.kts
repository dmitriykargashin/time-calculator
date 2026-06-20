import java.util.Properties
import java.io.FileInputStream
import java.io.File

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Ensure the redirected build temp dir (gradle.properties java.io.tmpdir) exists
// so R8's release scratch has somewhere to write on the big project volume - the
// macOS root volume is too small for it. Recreated here if it was ever deleted.
File("/Volumes/Additional/tmp-tc").mkdirs()

// Release signing is kept out of source control in android/key.properties.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.dmitriykargashin.cardamon_time_calculator"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Must stay identical to the original Play Store listing.
        // (The legacy paid ".pro" listing is abandoned - the app is free with
        // donation purchases only; the pro flavor was removed 2026-06.)
        applicationId = "com.dmitriykargashin.cardamontimecalculator"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Launcher label, overridden for debug so a side-by-side dev install
        // is distinguishable from the real Play app on the device.
        manifestPlaceholders["appLabel"] = "Time Calculator Cardamon"
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // The taskGraph check below fails release builds when
            // key.properties is missing, so the debug fallback can never
            // produce a shippable artifact; it only keeps configuration of
            // unrelated (debug) builds working on checkouts without the
            // keystore.
            signingConfig = if (keystorePropertiesFile.exists())
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
        }
        debug {
            // Debug installs under a distinct id + name so they can sit
            // side-by-side with the Play-signed production app on a device
            // (the production app is Play-signed; a local debug build cannot
            // update it in place). Release is unaffected.
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            manifestPlaceholders["appLabel"] = "Time Calc (dev)"
        }
    }
}

// Build-invariant guard, checked as soon as the task graph is known (before
// any task runs): a release artifact must be signed with the upload key.
gradle.taskGraph.whenReady {
    val buildsRelease = allTasks.any {
        it.project.path == project.path &&
            it.name.startsWith("package") &&
            it.name.contains("Release")
    }
    if (buildsRelease && !keystorePropertiesFile.exists()) {
        throw GradleException(
            "android/key.properties is missing: this release build would be " +
                "debug-signed and rejected by Play. Restore key.properties " +
                "(and the keystore from the Google Drive backup) before " +
                "building a release."
        )
    }
}

flutter {
    source = "../.."
}

// Firebase Analytics: apply the Google Services plugin ONLY for RELEASE builds
// (and only when google-services.json is present). The DEBUG build uses the
// ".dev" applicationIdSuffix, which is NOT a client in google-services.json /
// the Firebase project, so applying the plugin to debug would fail the build
// with "No matching client found for ...dev". Release uses the real
// applicationId (present in the json) -> analytics works in the published app;
// the .dev debug build runs with analytics off (Firebase.initializeApp throws
// -> graceful no-op), and dev test events never pollute the production
// Analytics property.
val buildsReleaseVariant =
    gradle.startParameter.taskNames.any { it.contains("Release") }
if (buildsReleaseVariant && file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}
