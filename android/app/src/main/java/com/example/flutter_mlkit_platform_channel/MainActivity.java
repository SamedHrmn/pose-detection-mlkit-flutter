package com.example.flutter_mlkit_platform_channel;


import android.content.Intent;
import android.graphics.Bitmap;

import androidx.annotation.NonNull;

import com.google.mlkit.common.MlKitException;
import com.google.mlkit.vision.common.InputImage;
import com.google.mlkit.vision.pose.PoseDetection;
import com.google.mlkit.vision.pose.PoseDetector;
import com.google.mlkit.vision.pose.PoseLandmark;
import com.google.mlkit.vision.pose.defaults.PoseDetectorOptions;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.Executor;
import java.util.concurrent.Executors;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {

    private final String CHANNEL_TAG = "mlkit";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);


        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL_TAG).setMethodCallHandler((call, result) -> {
            if (call.method.equals("startAndroidPoseDetectionWithChannel")) {
                startAndroidPoseDetectionWithChannel();
                result.success(true);
            } else if (call.method.equals("startCameraStream")) {
                try {
                    MyPoseDetector.init(result);
                    startCameraStream(call, result);
                    System.out.println("CAMERA STREAM STARTING");
                } catch (MlKitException e) {
                    e.printStackTrace();
                }
            } else if (call.method.equals("disposeDetector")) {
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
        Map<String, Object> metaData = (Map<String, Object>) imageData.get("metadata");

        int width = (int) metaData.get("width");
        int height = (int) metaData.get("height");
        int rotation = (int) metaData.get("rotation");
        //int format = (int) metaData.get("imageFormat");
        System.out.println(width + "x" + height);
        ;
        //System.out.println(format);




        /*InputImage inputImage = InputImage.fromByteArray(bytes,width,height,rotation,InputImage.IMAGE_FORMAT_NV21);



        PoseDetectorOptions detectorOptions = new PoseDetectorOptions.Builder()
                .setDetectorMode(PoseDetectorOptions.STREAM_MODE)
                .build();
        PoseDetector detector = PoseDetection.getClient(detectorOptions);



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


         */


        MyPoseDetector.predict(bytes, width, height, rotation);


    }


    private void disposeDetector() {
        MyPoseDetector.poseDetector.close();
    }

}


class MyPoseDetector {

    static public PoseDetector poseDetector;
    static Bitmap mCurrentFrame;
    static private InputImage visionImage;
    static MethodChannel.Result myResult;
    private static final Executor executor = Executors.newCachedThreadPool();


    public static void init(MethodChannel.Result result) {
        myResult = result;
        PoseDetectorOptions options =
                new PoseDetectorOptions.Builder()
                        .setDetectorMode(PoseDetectorOptions.STREAM_MODE)
                        .build();
        poseDetector = PoseDetection.getClient(options);
    }

    public static void predict(byte[] bytes, int width, int height, int rotation) {
        try {

            // TODO: 4 farklı yolla visionImage'i vermeyi denedim ,
            // TODO: farklı methodlarda farklı hatalar veriyor.

            /*  HATA YOK FAKAT POSES LENGTH 0
            mCurrentFrame = VisionUtil.getBitmap(image,rotation);
            this.visionImage = InputImage.fromBitmap(mCurrentFrame,0);*/

            /*  BAD STATE HATASI
            mCurrentFrame  = VisionUtil.getBitmapFromInputImage(image,rotation);
            this.visionImage = InputImage.fromBitmap(mCurrentFrame,0);*/

            /*
               PROCESS EXCEPTION , MLKit Internal Error
            this.visionImage = InputImage.fromMediaImage(image,0);*/

            /*
               HATA YOK FAKAT YANLIŞ ÇALIŞIYOR.
            this.visionImage = InputImage.fromByteArray(bytes,image.getWidth(),image.getHeight(),
                    0,InputImage.IMAGE_FORMAT_NV21);
            */


            visionImage = InputImage.fromByteArray(bytes, width, height, rotation, InputImage.IMAGE_FORMAT_NV21);

            //yuvToBitmap(bytes,width,height);

            //visionImage = InputImage.fromBitmap(mCurrentFrame,rotation);

            executor.execute(new Runnable() {
                @Override
                public void run() {

                    poseDetector.process(visionImage)
                            .addOnSuccessListener(pose -> {
                                ArrayList<ArrayList<HashMap<String, Object>>> array = new ArrayList<>();

                                if (!pose.getAllPoseLandmarks().isEmpty()) {
                                    ArrayList<HashMap<String, Object>> landmarks = new ArrayList<>();
                                    for (PoseLandmark poseLandmark : pose.getAllPoseLandmarks()) {
                                        HashMap<String, Object> landmarkMap = new HashMap<>();
                                        landmarkMap.put("type", poseLandmark.getLandmarkType());
                                        landmarkMap.put("x", poseLandmark.getPosition3D().getX());
                                        landmarkMap.put("y", poseLandmark.getPosition3D().getY());
                                        landmarkMap.put("z", poseLandmark.getPosition3D().getZ());
                                        landmarkMap.put("likelihood", poseLandmark.getInFrameLikelihood());
                                        landmarks.add(landmarkMap);
                                    }
                                    array.add(landmarks);
                                }
                                myResult.success(array);
                            });


                }
            });


        } catch (Throwable throwable) {
            System.out.println("MainError");
            throwable.printStackTrace();
        }
    }
}