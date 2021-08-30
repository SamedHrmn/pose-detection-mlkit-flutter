import 'package:flutter/services.dart';
import 'package:flutter_mlkit_platform_channel/pose_model.dart';
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

  static Future<List<Pose>> startCameraStream(Map<String,dynamic> args) async {
    final response = await _methodChannel.invokeMethod("startCameraStream",args);


    List<Pose> poses = [];
    for (final pose in response) {
      Map<PoseLandmarkType, PoseLandmark> landmarks = {};
      for (final point in pose) {
        final landmark = PoseLandmark.fromMap(point);
        landmarks[landmark.type] = landmark;
      }
      poses.add(Pose(landmarks));
    }
    return poses;

  }

  static Future<void> disposeDetector() async{
    await _methodChannel.invokeMethod("disposeDetector");
  }
}
