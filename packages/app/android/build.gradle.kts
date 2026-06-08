import org.gradle.api.tasks.compile.JavaCompile

allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://android-sdk.is.com/")
        }
        maven {
            url = uri("https://unity3d.jfrog.io/artifactory/unity-ads-android-master/")
        }
        maven {
            url = uri("https://jitpack.io")
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Force billing client 7.0.0 across all subprojects to avoid the
// ProxyBillingActivity NullPointerException bug in 7.1.1.
// See: https://issuetracker.google.com/issues/312977090
subprojects {
    configurations.all {
        resolutionStrategy {
            force("com.android.billingclient:billing:7.0.0")
            force("com.android.billingclient:billing-ktx:7.0.0")
        }
    }
}

subprojects {
    tasks.withType<JavaCompile>().configureEach {
        // Some third-party plugins still compile with source/target 8.
        // Suppress the obsolete options warning emitted by newer JDKs.
        options.compilerArgs.add("-Xlint:-options")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
