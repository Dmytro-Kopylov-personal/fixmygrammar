// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FixMyGrammar",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "FixMyGrammar", targets: ["FixMyGrammar"]),
        .library(name: "FixMyGrammarCore", targets: ["FixMyGrammarCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey", exact: "0.2.1"),
    ],
    targets: [
        .target(
            name: "FixMyGrammarCore",
            path: "Sources/FixMyGrammarCore"
        ),
        .executableTarget(
            name: "FixMyGrammar",
            dependencies: ["FixMyGrammarCore", "HotKey"],
            path: "Sources/FixMyGrammar"
        ),
        .testTarget(
            name: "FixMyGrammarTests",
            dependencies: ["FixMyGrammarCore"],
            path: "Tests/FixMyGrammarTests"
        ),
    ]
)
