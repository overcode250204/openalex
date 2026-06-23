import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (!keystorePropertiesFile.exists()) {
    throw org.gradle.api.GradleException(
        "Missing android/key.properties. Please create this file before building."
    )
}

keystorePropertiesFile.inputStream().use { inputStream ->
    keystoreProperties.load(inputStream)
}

val sharedStoreFile: String = keystoreProperties.getProperty("storeFile")
    ?: throw org.gradle.api.GradleException("Missing storeFile in android/key.properties")

val sharedStorePassword: String = keystoreProperties.getProperty("storePassword")
    ?: throw org.gradle.api.GradleException("Missing storePassword in android/key.properties")

val sharedKeyAlias: String = keystoreProperties.getProperty("keyAlias")
    ?: throw org.gradle.api.GradleException("Missing keyAlias in android/key.properties")

val sharedKeyPassword: String = keystoreProperties.getProperty("keyPassword")
    ?: throw org.gradle.api.GradleException("Missing keyPassword in android/key.properties")

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
    }
    
    signingConfigs {
        create("shared") {
            storeFile = rootProject.file(sharedStoreFile)
            storePassword = sharedStorePassword
            keyAlias = sharedKeyAlias
            keyPassword = sharedKeyPassword
        }
    }

    buildTypes {
        getByName("debug") {
            signingConfig = signingConfigs.getByName("shared")
        }

        getByName("release") {
            signingConfig = signingConfigs.getByName("shared")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}