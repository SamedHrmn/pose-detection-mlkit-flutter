import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as imageLib;

class InputImage {
  InputImage._(
      {String? filePath,
        Uint8List? bytes,
        required String imageType,
        InputImageData? inputImageData})
      : filePath = filePath,
        bytes = bytes,
        imageType = imageType,
        inputImageData = inputImageData;


  factory InputImage.fromBytes(
      {required Uint8List bytes, required InputImageData inputImageData}) {
    return InputImage._(
        bytes: bytes, imageType: 'bytes', inputImageData: inputImageData);
  }

  final String? filePath;
  final Uint8List? bytes;
  final String imageType;
  final InputImageData? inputImageData;

  Map<String, dynamic> getImageData() {
    var map = <String, dynamic>{
      'bytes': bytes,
      'type': imageType,
      'path': filePath,
      'metadata':
      inputImageData == null ? 'none' : inputImageData!.getMetaData()
    };
    return map;
  }
}

class InputImageData {

  final int imageWidth;
  final int imageHeight;
  final InputImageRotation imageRotation;
  final InputImageFormat inputImageFormat;
  final List<InputImagePlaneMetadata>? planeData;

  InputImageData(
      {required this.imageWidth,
        required this.imageHeight,
        required this.imageRotation,
        required this.inputImageFormat,
        required this.planeData});

  Map<String, dynamic> getMetaData() {
    var map = <String, dynamic>{
      'width': imageWidth,
      'height': imageHeight,
      'rotation': imageRotation.rawValue,
      'imageFormat': inputImageFormat.rawValue,
      'planeData': planeData
          ?.map((InputImagePlaneMetadata plane) => plane._serialize())
          .toList(),
    };
    return map;
  }
}

class InputImagePlaneMetadata {
  InputImagePlaneMetadata({
    required this.bytesPerRow,
    this.height,
    this.width,
  });

  final int bytesPerRow;
  final int? height;
  final int? width;

  Map<String, dynamic> _serialize() => <String, dynamic>{
    'bytesPerRow': bytesPerRow,
    'height': height,
    'width': width,
  };
}


enum InputImageFormat { NV21, YV12, YUV_420_888, YUV420, BGRA8888 }

extension InputImageFormatMethods on InputImageFormat {
  static Map<InputImageFormat, int> get _values => {
    InputImageFormat.NV21: 17,
    InputImageFormat.YV12: 842094169,
    InputImageFormat.YUV_420_888: 35,
    InputImageFormat.YUV420: 875704438,
    InputImageFormat.BGRA8888: 1111970369,
  };

  int get rawValue => _values[this] ?? 17;

  static InputImageFormat? fromRawValue(int rawValue) {
    return InputImageFormatMethods._values
        .map((k, v) => MapEntry(v, k))[rawValue];
  }
}

enum InputImageRotation {
  Rotation_0deg,
  Rotation_90deg,
  Rotation_180deg,
  Rotation_270deg
}

extension InputImageRotationMethods on InputImageRotation {
  static Map<InputImageRotation, int> get _values => {
    InputImageRotation.Rotation_0deg: 0,
    InputImageRotation.Rotation_90deg: 90,
    InputImageRotation.Rotation_180deg: 180,
    InputImageRotation.Rotation_270deg: 270,
  };

  int get rawValue => _values[this] ?? 0;

  static InputImageRotation? fromRawValue(int rawValue) {
    return InputImageRotationMethods._values
        .map((k, v) => MapEntry(v, k))[rawValue];
  }
}

/*
class ImageUtils {


  static Uint8List _imageToByteListUint8(imageLib.Image image, int inputWidth ,int inputHeight)  {
    var convertedBytes = Uint8List(1 * inputWidth * inputHeight * 3);
    var buffer = Uint8List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputWidth; i++) {
      for (var j = 0; j < inputHeight; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = imageLib.getRed(pixel);
        buffer[pixelIndex++] = imageLib.getGreen(pixel);
        buffer[pixelIndex++] = imageLib.getBlue(pixel); 
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  /// Converts a [CameraImage] in YUV420 format to [imageLib.Image] in RGB format
  static Uint8List? convertCameraImage(map) {
    var cameraImage = map['img'];
    var inputWidth = map['width'];
    var inputHeight = map['height'];

    if (cameraImage.format.group == ImageFormatGroup.yuv420) {
      return  _imageToByteListUint8(_convertYUV420ToImage(cameraImage),  inputWidth , inputHeight );
    } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
      return  _imageToByteListUint8(_convertBGRA8888ToImage(cameraImage),  inputWidth , inputHeight );
    } else {
      return null;
    }
  }

  /// Converts a [CameraImage] in BGRA888 format to [imageLib.Image] in RGB format
  static imageLib.Image _convertBGRA8888ToImage(CameraImage cameraImage) {
    imageLib.Image img = imageLib.Image.fromBytes(cameraImage.planes[0].width!,
        cameraImage.planes[0].height!, cameraImage.planes[0].bytes,
        format: imageLib.Format.bgra);
    return img;
  }

  /// Converts a [CameraImage] in YUV420 format to [imageLib.Image] in RGB format
  static imageLib.Image _convertYUV420ToImage(CameraImage cameraImage) {
    final int width = cameraImage.width;
    final int height = cameraImage.height;

    final int uvRowStride = cameraImage.planes[1].bytesPerRow;
    final int uvPixelStride = cameraImage.planes[1].bytesPerPixel!;

    final image = imageLib.Image(width, height);

    for (int w = 0; w < width; w++) {
      for (int h = 0; h < height; h++) {
        final int uvIndex =
            uvPixelStride * (w / 2).floor() + uvRowStride * (h / 2).floor();
        final int index = h * width + w;

        final y = cameraImage.planes[0].bytes[index];
        final u = cameraImage.planes[1].bytes[uvIndex];
        final v = cameraImage.planes[2].bytes[uvIndex];

        image.data[index] = ImageUtils._yuv2rgb(y, u, v);
      }
    }
    return image;
  }

  /// Convert a single YUV pixel to RGB
  static int _yuv2rgb(int y, int u, int v) {
    // Convert yuv pixel to rgb
    int r = (y + v * 1436 / 1024 - 179).round();
    int g = (y - u * 46549 / 131072 + 44 - v * 93604 / 131072 + 91).round();
    int b = (y + u * 1814 / 1024 - 227).round();

    // Clipping RGB values to be inside boundaries [ 0 , 255 ]
    r = r.clamp(0, 255);
    g = g.clamp(0, 255);
    b = b.clamp(0, 255);

    return 0xff000000 |
    ((b << 16) & 0xff0000) |
    ((g << 8) & 0xff00) |
    (r & 0xff);
  }


}

 */