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
    project.evaluationDependsOn(":app")
}

// Some plugins (receive_sharing_intent 1.9) declare compileSdk 37, which the
// SDK manager only offers as the minor-versioned "android-37.0" and AGP then
// fails to find. Nothing in them needs API 37, so build every plugin against
// the same SDK as the app.
subprojects {
    fun pinCompileSdk() {
        extensions.findByType<com.android.build.api.dsl.LibraryExtension>()?.apply {
            if ((compileSdk ?: 0) > 36) compileSdk = 36
        }
    }
    // evaluationDependsOn(":app") above may already have evaluated some
    // projects, and afterEvaluate refuses to register on those.
    if (state.executed) pinCompileSdk() else afterEvaluate { pinCompileSdk() }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
