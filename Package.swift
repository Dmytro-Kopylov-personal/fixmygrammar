// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FixMyGrammar",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "FixMyGrammar", targets: ["FixMyGrammar"]),
    ],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey", from: "0.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "FixMyGrammar",
            dependencies: ["HotKey"],
            path: "Sources/FixMyGrammar"
        ),
    ]
)
