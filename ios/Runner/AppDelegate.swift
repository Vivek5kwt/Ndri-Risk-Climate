import Flutter
import UIKit
import flutter_downloader

private func registerDownloaderPlugins(registry: FlutterPluginRegistry) {
  if !registry.hasPlugin("FlutterDownloaderPlugin") {
    FlutterDownloaderPlugin.register(
      with: registry.registrar(forPlugin: "FlutterDownloaderPlugin")!
    )
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    FlutterDownloaderPlugin.setPluginRegistrantCallback(registerDownloaderPlugins)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
