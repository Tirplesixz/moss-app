import 'package:flutter/services.dart';

enum WallpaperExportAction { applied, shared, saved }

class WallpaperExportResult {
  const WallpaperExportResult(this.action, {this.location});
  final WallpaperExportAction action;
  final String? location;
}

class LockScreenPlatformService {
  const LockScreenPlatformService();

  static const _channel = MethodChannel('com.moss.moss/lockscreen');

  Future<WallpaperExportResult> apply(
    Uint8List pngBytes, {
    bool saveToGallery = true,
  }) async {
    final raw = await _channel.invokeMapMethod<String, dynamic>(
      'applyLockScreen',
      {'bytes': pngBytes, 'saveToGallery': saveToGallery},
    );
    final action = switch (raw?['action']) {
      'applied' => WallpaperExportAction.applied,
      'saved' => WallpaperExportAction.saved,
      _ => WallpaperExportAction.shared,
    };
    return WallpaperExportResult(action, location: raw?['location'] as String?);
  }
}
