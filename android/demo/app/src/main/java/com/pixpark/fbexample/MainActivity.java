package com.pixpark.fbexample;

import static android.widget.Toast.LENGTH_LONG;

import android.Manifest;
import android.content.pm.PackageManager;
import android.media.Image;
import android.os.Bundle;
import android.util.Log;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.Toast;
import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import com.pixpark.facebetter.BeautyEffectEngine;
import com.pixpark.facebetter.BeautyParams.*;
import com.pixpark.facebetter.ImageBuffer;
import com.pixpark.facebetter.ImageFrame;
import java.nio.ByteBuffer;

public class MainActivity extends AppCompatActivity {
  private static final String TAG = "MainActivity";
  private static final int CAMERA_PERMISSION_REQUEST_CODE = 200;

  private BeautyEffectEngine mBeautyEngine;
  private CameraHandler mCameraHandler;
  private FrameLayout mCameraPreviewContainer;
  private Button mSwitchCameraButton;
  private GLVideoRenderer mVideoRenderer;
  private BeautyPanelView mBeautyPanel;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    EdgeToEdge.enable(this);
    setContentView(R.layout.activity_main);

    // 保持屏幕常亮，防止息屏
    getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

    ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
      Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
      v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
      return insets;
    });

    // Initialize UI components
    initUI();

    initBeautyEngine();

    checkCameraPermission();
  }

  private void initBeautyEngine() {
    BeautyEffectEngine.LogConfig logConfig = new BeautyEffectEngine.LogConfig();
    logConfig.consoleEnabled = true;
    logConfig.fileEnabled = false;
    logConfig.level = BeautyEffectEngine.LogLevel.INFO;
    logConfig.fileName = "android_beauty_engine.log";
    BeautyEffectEngine.setLogConfig(logConfig);

    BeautyEffectEngine.EngineConfig config = new BeautyEffectEngine.EngineConfig();
    config.appId = "your appid";
    config.appKey = "your appkey";

    mBeautyEngine = new BeautyEffectEngine(this, config);
    Log.d(TAG, "BeautyEffectEngine initialized");
  }

  private void initUI() {
    mCameraPreviewContainer = findViewById(R.id.camera_preview_container);
    mSwitchCameraButton = findViewById(R.id.switch_camera_button);
    mBeautyPanel = findViewById(R.id.beauty_panel);

    // Create and add OpenGL video renderer
    mVideoRenderer = new GLVideoRenderer(this);
    mCameraPreviewContainer.addView(mVideoRenderer);

    // Hide switch camera button as CameraController doesn't support switching
    mSwitchCameraButton.setVisibility(android.view.View.GONE);

    // Setup beauty panel callback
    mBeautyPanel.setBeautyPanelCallback(new BeautyPanelView.BeautyPanelCallback() {
      @Override
      public void onBeautyParamChanged(BeautyType beautyType, Object paramType, float value) {
        if (mBeautyEngine != null) {
          // 首先启用对应的美颜类型
          int enableResult = mBeautyEngine.enableBeautyType(BeautyType.BASIC, true);
          Log.d(TAG, "Enable beauty type " + beautyType + " result: " + enableResult);

          // 根据参数类型调用相应的 setBeautyParam 方法
          int setResult = -1;
          if (paramType instanceof BasicParam) {
            setResult = mBeautyEngine.setBeautyParam((BasicParam) paramType, value);
          } else if (paramType instanceof ReshapeParam) {
            setResult = mBeautyEngine.setBeautyParam((ReshapeParam) paramType, value);
          } else if (paramType instanceof MakeupParam) {
            setResult = mBeautyEngine.setBeautyParam((MakeupParam) paramType, value);
          } else if (paramType instanceof SegmentationParam) {
            // SegmentationParam 需要 String 类型的值，这里暂时跳过
            Log.w(TAG, "SegmentationParam not supported in this demo");
            return;
          }

          Log.d(TAG,
              "Beauty param changed: type=" + beautyType + ", param=" + paramType
                  + ", value=" + value + ", setResult=" + setResult);
        }
      }
    });
  }

  public void setupCamera() {
    if (mCameraHandler == null) {
      mCameraHandler = new CameraHandler(this);

      // Set frame callback
      mCameraHandler.setFrameCallback(new CameraHandler.FrameCallback() {
        @Override
        public void onFrameAvailable(Image image, int orientation) {
          final long startNs = System.nanoTime();
          try {
            // Process camera frame data here
            if (image == null) {
              Log.w(TAG, "onFrameAvailable: image is null");
              return;
            }

            // Get image planes
            Image.Plane[] planes = image.getPlanes();
            ByteBuffer yBuffer = planes[0].getBuffer();
            ByteBuffer uBuffer = planes[1].getBuffer();
            ByteBuffer vBuffer = planes[2].getBuffer();

            int yStride = planes[0].getRowStride();
            int uStride = planes[1].getRowStride();
            int vStride = planes[2].getRowStride();

            int uPixelStride = planes[1].getPixelStride();
            int width = image.getWidth();
            int height = image.getHeight();

            // Create input frame from camera data using ByteBuffer directly
            ImageFrame input = ImageFrame.createWithAndroid420(
                width, height, yBuffer, yStride, uBuffer, uStride, vBuffer, vStride, uPixelStride);
            if (input != null) {
              input.rotate(ImageBuffer.Rotation.ROTATION_270);
              ImageFrame output =
                  mBeautyEngine.processImage(input, BeautyEffectEngine.ProcessMode.VIDEO);

              if (output != null) {
                if (mVideoRenderer != null) {
                  ImageBuffer buffer = output.toI420();
                  mVideoRenderer.renderBuffer(buffer);
                }
                output.release();
              }

              input.release();
            } else {
              Log.w(TAG, "Failed to process frame - output is null");
            }
          } finally {
            long elapsedUs = (System.nanoTime() - startNs) / 1000L;
            Log.d(TAG, "onFrameAvailable cost: " + (elapsedUs / 1000.0) + " ms");
          }
        }
      });

      // Start camera
      mCameraHandler.startCamera();
    }
  }

  public void checkCameraPermission() {
    // Check camera permission
    if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA)
        != PackageManager.PERMISSION_GRANTED) {
      // If no camera permission, request permission
      ActivityCompat.requestPermissions(
          this, new String[] {Manifest.permission.CAMERA}, CAMERA_PERMISSION_REQUEST_CODE);
    } else {
      // Has permission, set up camera
      setupCamera();
    }
  }

  @Override
  public void onRequestPermissionsResult(
      int requestCode, String[] permissions, int[] grantResults) {
    super.onRequestPermissionsResult(requestCode, permissions, grantResults);
    if (requestCode == CAMERA_PERMISSION_REQUEST_CODE) {
      if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
        setupCamera();
      } else {
        Toast.makeText(this, "No camera permission!", LENGTH_LONG).show();
      }
    }
  }

  @Override
  protected void onResume() {
    super.onResume();

    if (mCameraHandler != null && !mCameraHandler.isCameraOpened()) {
      mCameraHandler.startCamera();
    }
  }

  @Override
  protected void onPause() {
    super.onPause();

    if (mCameraHandler != null) {
      mCameraHandler.stopCamera();
    }
  }

  @Override
  protected void onDestroy() {
    // Release camera resources
    if (mCameraHandler != null) {
      mCameraHandler.stopCamera();
      mCameraHandler = null;
    }

    // Release video renderer
    if (mVideoRenderer != null) {
      mVideoRenderer = null;
    }

    if (mBeautyEngine != null) {
      mBeautyEngine.release();
    }

    super.onDestroy();
  }
}
