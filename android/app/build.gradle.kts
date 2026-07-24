import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasSharedSigningConfig = keystorePropertiesFile.exists()

if (hasSharedSigningConfig) {
    keystorePropertiesFile.inputStream().use { inputStream ->
        keystoreProperties.load(inputStream)
    }
}

fun requireKeystoreProperty(name: String): String =
    keystoreProperties.getProperty(name)
        ?: throw org.gradle.api.GradleException("Missing $name in android/key.properties")

android {
    namespace = "com.example.openalex"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.openalex"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"
        testInstrumentationRunnerArguments["clearPackageData"] = "true"
    }

    testOptions {
        execution = "ANDROIDX_TEST_ORCHESTRATOR"
    }
    
    signingConfigs {
        if (hasSharedSigningConfig) {
            create("shared") {
                storeFile = rootProject.file(requireKeystoreProperty("storeFile"))
                storePassword = requireKeystoreProperty("storePassword")
                keyAlias = requireKeystoreProperty("keyAlias")
                keyPassword = requireKeystoreProperty("keyPassword")
            }
        }
    }

    buildTypes {
        getByName("debug") {
            if (hasSharedSigningConfig) {
                signingConfig = signingConfigs.getByName("shared")
            }
        }

        getByName("release") {
            if (hasSharedSigningConfig) {
                signingConfig = signingConfigs.getByName("shared")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    androidTestUtil("androidx.test:orchestrator:1.5.1")
}
