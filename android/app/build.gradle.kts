import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val flutterRoot = rootProject.file("..")

fun readBuildVersionFromConfig(): String {
    val configFile = File(flutterRoot, "version_config.json")
    if (!configFile.exists()) return "2.06"
    val text = configFile.readText()
    val match = Regex(""""buildVersion"\s*:\s*"([^"]+)"""").find(text)
    return match?.groupValues?.get(1) ?: "2.06"
}

fun readAppFlavor(): String {
    val appConfig = File(flutterRoot, "lib/core/config/app_config.dart")
    if (!appConfig.exists()) return "dev"
    val match = Regex("""baseDomain\s*=\s*'([^']+)'""").find(appConfig.readText())
    val domain = match?.groupValues?.get(1) ?: return "dev"
    return if (domain.contains("prod.")) "prod" else "dev"
}

fun apkOutputName(): String {
    return "quikdawa-${readAppFlavor()}-v${readBuildVersionFromConfig()}.apk"
}

val bumpVersionSync = tasks.register<Exec>("bumpVersionSync") {
    workingDir = flutterRoot
    commandLine("dart", "run", "tool/bump_version.dart", "--sync")
}

val bumpVersionIncrement = tasks.register<Exec>("bumpVersionIncrement") {
    workingDir = flutterRoot
    commandLine("dart", "run", "tool/bump_version.dart", "--increment")
    isEnabled = false
}

android {
    namespace = "com.quikdawa"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.quikdawa"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        // Google Play requires targetSdk 36 (Android 16) by 31 Aug 2026.
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Keep native libs uncompressed so 16KB LOAD alignment is preserved.
    packaging {
        jniLibs {
            useLegacyPackaging = false
        }
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }

    applicationVariants.all {
        val variant = this
        val outputApkName = apkOutputName()

        outputs.all {
            val output = this as com.android.build.gradle.internal.api.BaseVariantOutputImpl
            output.outputFileName = outputApkName
        }

        variant.assembleProvider.get().doLast {
            val flutterApkDir = File(flutterRoot, "build/app/outputs/flutter-apk")
            flutterApkDir.mkdirs()
            val apkDir = File(
                layout.buildDirectory.get().asFile,
                "outputs/apk/${variant.buildType.name}",
            )
            val builtApk = apkDir.listFiles()
                ?.firstOrNull { file -> file.isFile && file.name.endsWith(".apk") }
            if (builtApk != null) {
                builtApk.copyTo(File(flutterApkDir, outputApkName), overwrite = true)
            }
        }
    }
}

flutter {
    source = "../.."
}

tasks.named("preBuild") {
    dependsOn(bumpVersionSync)
}

tasks.matching { it.name == "assembleDebug" || it.name == "assembleRelease" }.configureEach {
    finalizedBy(bumpVersionIncrement)
}

gradle.taskGraph.whenReady {
    val willAssemble = allTasks.any {
        it.name == "assembleDebug" || it.name == "assembleRelease"
    }
    bumpVersionIncrement.configure {
        isEnabled = willAssemble
    }
}
