allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

extra.set("FlutterFire", mapOf(
    "FirebaseSDKVersion" to "34.15.0"
))
