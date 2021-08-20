import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class ChannelHelper {
  static const _CHANNEL_TAG = "mlkit";
  static var _methodChannel = MethodChannel(_CHANNEL_TAG);
  static var _logger = Logger();

  static Future startAndroidPoseDetectionWithChannel() async {
    bool res = await _methodChannel
        .invokeMethod("startAndroidPoseDetectionWithChannel");
    if (res) {
      _logger.i("**** Native Activity Started ! ****");
    }
  }
}
