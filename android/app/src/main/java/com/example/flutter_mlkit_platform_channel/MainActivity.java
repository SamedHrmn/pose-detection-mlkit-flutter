package com.example.flutter_mlkit_platform_channel;


import android.content.Intent;

import androidx.annotation.NonNull;

import com.example.flutter_mlkit_platform_channel.pose_detector.PoseDetectorProcessor;
import com.google.mlkit.common.MlKitException;
import com.google.mlkit.vision.common.InputImage;
import com.google.mlkit.vision.pose.PoseDetection;
import com.google.mlkit.vision.pose.PoseDetector;
import com.google.mlkit.vision.pose.PoseDetectorOptionsBase;
import com.google.mlkit.vision.pose.PoseLandmark;
import com.google.mlkit.vision.pose.accurate.AccuratePoseDetectorOptions;
import com.google.mlkit.vision.pose.defaults.PoseDetectorOptions;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {

    private final String CHANNEL_TAG = "mlkit";

    private PoseDetector detector;


    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL_TAG).setMethodCallHandler((call, result) -> {
            if (call.method.equals("startAndroidPoseDetectionWithChannel")) {
                startAndroidPoseDetectionWithChannel();
                result.success(true);
            } else if (call.method.equals("startCameraStream")) {
                try {
                    startCameraStream(call, result);
                    System.out.println("CAMERA STREAM STARTING");
                } catch (MlKitException e) {
                    e.printStackTrace();
                }
            } else if(call.method.equals("disposeDetector")){
                disposeDetector();
            }
        });
    }

    private void startAndroidPoseDetectionWithChannel() {
        Intent intent = new Intent(this, ChooserActivity.class);
        startActivity(intent);
    }

    private void startCameraStream(MethodCall args, MethodChannel.Result result) throws MlKitException {
        /*byte[] imageBytes = ((byte[]) args.get("bytes"));
        int width = ((int) args.get("width"));
        int height = ((int) args.get("height"));
        InputImage inputImage = InputImage.fromByteArray(imageBytes, width, height, 0, InputImage.IMAGE_FORMAT_NV21);
        */

        Map<String, Object> imageData = args.argument("imageData");
        byte[] bytes = (byte[]) imageData.get("bytes");
        System.out.println(bytes.length);
         Map<String,Object> metaData = (Map<String, Object>) imageData.get("metadata");

        int width = (int) metaData.get("width");
        int height = (int) metaData.get("height");
        int rotation = (int) metaData.get("rotation");
        //int format = (int) metaData.get("imageFormat");
        System.out.println(width);
        System.out.println(rotation);
        //System.out.println(format);




        InputImage inputImage = InputImage.fromByteArray(bytes,width,height,rotation,InputImage.IMAGE_FORMAT_NV21);



        PoseDetectorOptions detectorOptions = new PoseDetectorOptions.Builder()
                .setDetectorMode(PoseDetectorOptions.STREAM_MODE)
                .build();
        detector = PoseDetection.getClient(detectorOptions);



        detector.process(inputImage).addOnSuccessListener(pose -> {
            List<List<Map<String, Object>>> array = new ArrayList<>();

            if (!pose.getAllPoseLandmarks().isEmpty()) {
                List<Map<String, Object>> landmarks = new ArrayList<>();
                for (PoseLandmark poseLandmark : pose.getAllPoseLandmarks()) {
                    Map<String, Object> landmarkMap = new HashMap<>();
                    landmarkMap.put("type", poseLandmark.getLandmarkType());
                    landmarkMap.put("x", poseLandmark.getPosition3D().getX());
                    landmarkMap.put("y", poseLandmark.getPosition3D().getY());
                    landmarkMap.put("z", poseLandmark.getPosition3D().getZ());
                    landmarkMap.put("likelihood", poseLandmark.getInFrameLikelihood());
                    landmarks.add(landmarkMap);
                }
                array.add(landmarks);
            }
            result.success(array);
        }).addOnFailureListener(e -> result.error("PoseDetectorError", e.toString(), null));


    }


    private void disposeDetector(){
        detector.close();
    }

}