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

// Fix build lỗi "class file for androidx.concurrent.futures.CallbackToFutureAdapter
// not found" khi biên dịch camera-core (plugin camera_android_camerax, đã xác nhận
// tái diễn ở cả camera-core 1.5.3 và 1.6.1 — không phải bug riêng 1 version, mà do
// subproject plugin thiếu hẳn androidx.concurrent:concurrent-futures trên classpath
// biên dịch). `gradle.projectsEvaluated` là hook đúng thời điểm: chạy đúng 1 lần sau
// khi TẤT CẢ subproject đã cấu hình xong (configuration 'implementation' đã tồn tại,
// không còn ở trạng thái "already evaluated" khi thêm dependency) — khác các cách đã
// thử trước (subprojects{} trực tiếp: quá sớm; afterEvaluate lồng trong subprojects{}:
// quá muộn).
gradle.projectsEvaluated {
    project(":camera_android_camerax").dependencies.add(
        "implementation",
        "androidx.concurrent:concurrent-futures:1.2.0",
    )
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
