// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DSInterviewer",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DSInterviewer",
            targets: ["DSInterviewer"]
        ),
    ],
    targets: [
        .target(
            name: "DSInterviewer",
            path: "."
        ),
    ]
)
