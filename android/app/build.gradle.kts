import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

fun String?.isTruthy(): Boolean {
    return this != null && (
        equals("true", ignoreCase = true) ||
            equals("1") ||
            equals("yes", ignoreCase = true)
        )
}

val uploadCrashlyticsMapping = providers
    .gradleProperty("rxpro.uploadCrashlyticsMapping")
    .orElse(providers.environmentVariable("RXPRO_UPLOAD_CRASHLYTICS_MAPPING"))
    .orNull
    .isTruthy()

android {
    namespace = "com.fix.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.fix.mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val storeFilePath = keystoreProperties["storeFile"] as String?
            storeFile = file(storeFilePath ?: "missing-release-keystore.jks")
            storePassword = keystoreProperties["storePassword"] as String?
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

tasks.configureEach {
    if (name.startsWith("uploadCrashlyticsMappingFile")) {
        enabled = uploadCrashlyticsMapping
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

gradle.taskGraph.whenReady {
    val isReleaseBuild = allTasks.any { task ->
        task.name.contains("Release", ignoreCase = true)
    }
    if (isReleaseBuild && !keystorePropertiesFile.exists()) {
        throw GradleException(
            "Release signing is not configured. Create android/key.properties with storeFile, storePassword, keyAlias and keyPassword.",
        )
    }
}
