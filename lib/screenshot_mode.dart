/// Compile-time flag enabled via `--dart-define=SCREENSHOT=true`.
///
/// When set, the app seeds representative demo controllers and serves canned
/// status/outputs instead of hitting the network, so Play Store screenshots can
/// be captured on an emulator with no real FPP hardware present. It is a
/// `const bool.fromEnvironment`, so in normal/release builds it is `false` and
/// every guarded demo branch is tree-shaken away.
const bool kScreenshotMode = bool.fromEnvironment('SCREENSHOT');
