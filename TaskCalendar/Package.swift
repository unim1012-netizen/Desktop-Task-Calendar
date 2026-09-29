// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TaskCalendar",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "TaskCalendar", path: "Sources")
    ]
)
