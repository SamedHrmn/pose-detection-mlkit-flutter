import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mlkit_platform_channel/channel_helper.dart';
import 'package:flutter_mlkit_platform_channel/image_utils.dart';
import 'package:flutter_mlkit_platform_channel/pose_painter.dart';

class CameraView extends StatefulWidget {
  const CameraView({Key? key}) : super(key: key);

  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  CameraController? controller;
  static bool isDetecting = false;
  static CustomPaint? customPaint;
  static late InputImage inputImage;
  int? selectedCameraIdx;
  List<CameraDescription>? cameras;

  @override
  void initState() {
    super.initState();

    availableCameras().then((availableCameras) {
      cameras = availableCameras;
      if (cameras!.length > 0) {
        setState(() {
          selectedCameraIdx = 0;
        });

        _initCameraController(cameras![selectedCameraIdx!]).then((void v) {});
      } else {
        print("No camera available");
      }
    }).catchError((err) {
      print('Error: $err.code\nError Message: $err.message');
    });
  }

  Future _initCameraController(CameraDescription cameraDescription) async {
    controller = CameraController(cameraDescription, ResolutionPreset.vga480);

    controller!.addListener(() {
      if (mounted) {
        setState(() {});
      }

      if (controller!.value.hasError) {
        print('Camera error ${controller!.value.errorDescription}');
      }
    });

    try {
      controller!.initialize().then((value) {
        if (!mounted) {
          return;
        }
        setState(() {});

        detectPose();
      });
    } on CameraException catch (e) {
      print(e.description);
    }

    if (mounted) {
      setState(() {});
    }
  }

  detectPose() {
    controller!.startImageStream((CameraImage img) async {
      if (!isDetecting) {
        isDetecting = true;

        inputImage =
            await _processCameraImage(img, cameras![selectedCameraIdx!]);
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

  static Future<InputImage> _processCameraImage(
      CameraImage image, CameraDescription description) async {
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final imageRotation =
        InputImageRotationMethods.fromRawValue(description.sensorOrientation) ??
            InputImageRotation.Rotation_0deg;

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
      inputImageFormat: InputImageFormat.NV21,
      planeData: planeData,
    );

    final inputImage =
        InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

    return inputImage;
  }

  @override
  void dispose() {
    controller?.dispose();
    ChannelHelper.disposeDetector();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return Container();
    }
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _cameraPreviewWidget(),
          _painter(),
          Positioned(
            right: 0,
            bottom: 0,
            height: 50,
            child: _cameraToggleButton(),
          ),
        ],
      ),
    );
  }

  Widget _cameraPreviewWidget() {
    if (controller == null || !controller!.value.isInitialized) {
      return const Text(
        'Loading',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20.0,
          fontWeight: FontWeight.w900,
        ),
      );
    }

    return CameraPreview(controller!);
  }

  Widget _painter() {
    return customPaint != null
        ? RepaintBoundary(child: customPaint)
        : SizedBox();
  }

  Widget _cameraToggleButton() {
    if (cameras == null || cameras!.isEmpty) {
      return Spacer();
    }

    CameraDescription selectedCamera = cameras![selectedCameraIdx!];
    CameraLensDirection lensDirection = selectedCamera.lensDirection;

    return FloatingActionButton(
      onPressed: _onSwitchCamera,
      child: Icon(_getCameraLensIcon(lensDirection)),
    );
  }

  IconData _getCameraLensIcon(CameraLensDirection direction) {
    switch (direction) {
      case CameraLensDirection.back:
        return Icons.camera_rear;
      case CameraLensDirection.front:
        return Icons.camera_front;
      case CameraLensDirection.external:
        return Icons.camera;
      default:
        return Icons.device_unknown;
    }
  }

  void _onSwitchCamera() {
    selectedCameraIdx =
        selectedCameraIdx! < cameras!.length - 1 ? selectedCameraIdx! + 1 : 0;
    CameraDescription selectedCamera = cameras![selectedCameraIdx!];
    _initCameraController(selectedCamera);
  }
}
