allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    // flutter_avif_android 3.1.0 (latest) ships duplicate Java and Kotlin
    // copies of FlutterAvifPlugin. Kotlin 2.2+ rejects the redeclaration. The
    // plugin's Java source dir contains only this redundant copy, so empty it
    // and let the identical Kotlin implementation compile. kotlinc reads the
    // module's Java source roots for joint compilation, so clearing srcDirs
    // (rather than an exclude filter, which AGP doesn't forward to kotlinc) is
    // what actually removes the duplicate from its view. Registered before
    // evaluationDependsOn so it also covers :app, which that call evaluates
    // eagerly.
    afterEvaluate {
        if (project.name == "flutter_avif_android") {
            extensions.findByName("android")?.let { ext ->
                (ext as com.android.build.gradle.BaseExtension)
                    .sourceSets.getByName("main").java
                    .setSrcDirs(emptyList<String>())
            }
        }
    }
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
