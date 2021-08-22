package com.example.flutter_mlkit_platform_channel;


import android.content.Intent;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {

    private final String CHANNEL_TAG = "mlkit";


    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(),CHANNEL_TAG).setMethodCallHandler((call, result) -> {
            if(call.method.equals("startAndroidPoseDetectionWithChannel")){
                startAndroidPoseDetectionWithChannel();
                result.success(true);
            }
        });
    }

    private void startAndroidPoseDetectionWithChannel() {
        Intent intent = new Intent(this,ChooserActivity.class);
        startActivity(intent);
    }
}