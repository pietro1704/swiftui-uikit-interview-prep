// swift-tools-version: 5.9
import PackageDescription
import AppleProductTypes

let package = Package(
    name: "InterviewPrep",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .iOSApplication(
            name: "InterviewPrep",
            targets: ["AppMain"],
            bundleIdentifier: "com.pietro.InterviewPrepPlayground",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            accentColor: .presetColor(.purple),
            supportedDeviceFamilies: [.pad, .phone],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppMain",
            path: "",
            exclude: ["README.md"],
            sources: [
                "AppMain",
                "Shared",
                "Lessons",
                "MockInterview"
            ],
            resources: [.process("Resources")]
        )
    ]
)
