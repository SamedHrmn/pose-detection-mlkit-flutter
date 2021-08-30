enum PoseLandmarkType {
  nose,
  leftEyeInner,
  leftEye,
  leftEyeOuter,
  rightEyeInner,
  rightEye,
  rightEyeOuter,
  leftEar,
  rightEar,
  leftMouth,
  rightMouth,
  leftShoulder,
  rightShoulder,
  leftElbow,
  rightElbow,
  leftWrist,
  rightWrist,
  leftPinky,
  rightPinky,
  leftIndex,
  rightIndex,
  leftThumb,
  rightThumb,
  leftHip,
  rightHip,
  leftKnee,
  rightKnee,
  leftAnkle,
  rightAnkle,
  leftHeel,
  rightHeel,
  leftFootIndex,
  rightFootIndex
}

class PoseLandmark {
  PoseLandmark(
      this.type,
      this.x,
      this.y,
      this.z,
      this.likelihood,
      );

  final PoseLandmarkType type;
  final double x;
  final double y;
  final double z;
  final double likelihood;

  factory PoseLandmark.fromMap(Map<dynamic, dynamic> data) {
    return PoseLandmark(
      PoseLandmarkType.values[data['type']],
      data['x'],
      data['y'],
      data['z'],
      data['likelihood'] ?? 0.0,
    );
  }
}

class Pose {
  Pose(this.landmarks);

  final Map<PoseLandmarkType, PoseLandmark> landmarks;
}