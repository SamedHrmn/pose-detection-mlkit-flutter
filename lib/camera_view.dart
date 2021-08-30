import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mlkit_platform_channel/channel_helper.dart';
import 'package:flutter_mlkit_platform_channel/image_utils.dart';
import 'package:flutter_mlkit_platform_channel/pose_painter.dart';

Uint8List? byteList;

class CameraView extends StatefulWidget {
  CameraView({Key? key, required this.appCameras}) : super(key: key);

  final List<CameraDescription> appCameras;

  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  late CameraController controller;
  bool isDetecting = false;
  CustomPaint? customPaint;

  @override
  void initState() {
    super.initState();

    if (widget.appCameras.length < 1) {
      print('No camera is found');
    } else {
      controller = CameraController(
        widget.appCameras[0],
        ResolutionPreset.low,
      );
      controller.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});

        detectPose();
      });
    }
  }

  /// TODO: Medium kamera ayari için bakılacak
  detectPose() {
    controller.startImageStream((CameraImage img) async {
      if (!isDetecting) {
        isDetecting = true;

        final InputImage inputImage = await _processCameraImage(img);
        final poses = await ChannelHelper.startCameraStream(
            {"imageData": inputImage.getImageData()});

        print("POSES FOUND: " + poses.length.toString());

        if (inputImage.inputImageData != null) {
          final painter = PosePainter(
              poses,
              Size(inputImage.inputImageData!.imageWidth.toDouble(),
                  inputImage.inputImageData!.imageHeight.toDouble()),
              inputImage.inputImageData!.imageRotation);
          customPaint = CustomPaint(painter: painter);
        } else {
          customPaint = null;
        }

        isDetecting = false;
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  Future<InputImage> _processCameraImage(CameraImage image) async {
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final imageRotation = InputImageRotationMethods.fromRawValue(
            widget.appCameras.first.sensorOrientation) ??
        InputImageRotation.Rotation_0deg;

    final inputImageFormat =
        InputImageFormatMethods.fromRawValue(image.format.raw) ??
            InputImageFormat.NV21;

    final planeData = image.planes.map(
      (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    final inputImageData = InputImageData(
      imageWidth: image.width,
      imageHeight: image.height,
      imageRotation: imageRotation,
      inputImageFormat: inputImageFormat,
      planeData: planeData,
    );

    final inputImage =
        InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

    return inputImage;
  }

  @override
  void dispose() {
    controller.dispose();
    ChannelHelper.disposeDetector();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller.value.isInitialized == false) {
      return Container();
    }
    return Container(
      color: Colors.black,
      child: RepaintBoundary(
        // Paint için isolate.
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            CameraPreview(controller),
            if (customPaint != null) customPaint!,
          ],
        ),
      ),
    );
  }
}
