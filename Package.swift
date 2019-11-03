// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BZCalendar",
    platforms: [.iOS(.v11), .macOS(.v10_13)],
    products: [
        .library(
            name: "BZCalendar",
            targets: ["BZCalendar"]),
    ],
    dependencies: [
      .package(url: "https://github.com/bartekzabicki/Unicorns.git", from: "0.2.2"),
  ],
    targets: [
        .target(
            name: "BZCalendar",
            dependencies: ["Unicorns"],
            path: ".",
            sources: ["BZCalendar/Classes"])
    ]
)
