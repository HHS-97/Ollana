allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 빌드 디렉토리 설정 단순화
rootProject.buildDir = File("${rootProject.projectDir}/../build")

subprojects {
    project.buildDir = File("${rootProject.buildDir}/${project.name}")
}

// 의존성 설정
subprojects {
    project.evaluationDependsOn(":app")
}

// clean 태스크
tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}
