package com.pixpark.fbexample;

import android.content.Context;
import android.util.AttributeSet;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.HorizontalScrollView;
import android.widget.LinearLayout;
import android.widget.SeekBar;
import android.widget.TextView;
import androidx.annotation.Nullable;
import com.pixpark.facebetter.BeautyParams.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class BeautyPanelView extends LinearLayout {
  private static final String TAG = "BeautyPanelView";

  // UI 组件
  private SeekBar mValueSlider;
  private TextView mValueLabel;
  private HorizontalScrollView mParamScrollView;
  private LinearLayout mParamSelectionContainer;
  private LinearLayout mBeautyTypeContainer;

  // 数据
  private List<BeautyTypeData> mBeautyTypeDataList;
  private List<Button> mParamButtons;
  private List<Button> mBeautyTypeButtons;
  private Map<Object, Float> mParamValues;
  private BeautyType mCurrentBeautyType;
  private Object mCurrentParamType;

  // 回调接口
  public interface BeautyPanelCallback {
    void onBeautyParamChanged(BeautyType beautyType, Object paramType, float value);
  }

  private BeautyPanelCallback mCallback;

  public BeautyPanelView(Context context) {
    super(context);
    init();
  }

  public BeautyPanelView(Context context, @Nullable AttributeSet attrs) {
    super(context, attrs);
    init();
  }

  public BeautyPanelView(Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
    super(context, attrs, defStyleAttr);
    init();
  }

  private void init() {
    LayoutInflater.from(getContext()).inflate(R.layout.beauty_panel, this, true);

    mCurrentBeautyType = BeautyType.BASIC;
    mCurrentParamType = 0;
    mParamValues = new HashMap<>();
    mParamButtons = new ArrayList<>();
    mBeautyTypeButtons = new ArrayList<>();

    initViews();
    setupBeautyTypeData();
    initializeParamValues();
    setupUI();
  }

  private void initViews() {
    mValueSlider = findViewById(R.id.beauty_value_slider);
    mValueLabel = findViewById(R.id.beauty_value_label);
    mParamScrollView = findViewById(R.id.param_scroll_view);
    mParamSelectionContainer = findViewById(R.id.param_selection_container);
    mBeautyTypeContainer = findViewById(R.id.beauty_type_container);

    mValueSlider.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
      @Override
      public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
        if (fromUser) {
          float value = progress / 100.0f;
          mValueLabel.setText(progress + "%");
          mParamValues.put(mCurrentParamType, value);

          if (mCallback != null) {
            mCallback.onBeautyParamChanged(mCurrentBeautyType, mCurrentParamType, value);
          }
        }
      }

      @Override
      public void onStartTrackingTouch(SeekBar seekBar) {}

      @Override
      public void onStopTrackingTouch(SeekBar seekBar) {}
    });
  }

  private void setupBeautyTypeData() {
    mBeautyTypeDataList = new ArrayList<>();

    // 美肤
    BeautyTypeData basicData = new BeautyTypeData();
    basicData.title = "美肤";
    basicData.type = BeautyType.BASIC;
    basicData.params = new ArrayList<>();
    basicData.params.add(new ParamData("磨皮", BasicParam.SMOOTHING));
    basicData.params.add(new ParamData("锐化", BasicParam.SHARPENING));
    basicData.params.add(new ParamData("美白", BasicParam.WHITENING));
    basicData.params.add(new ParamData("红润", BasicParam.ROSINESS));
    mBeautyTypeDataList.add(basicData);

    // 美型
    BeautyTypeData reshapeData = new BeautyTypeData();
    reshapeData.title = "美型";
    reshapeData.type = BeautyType.RESHAPE;
    reshapeData.params = new ArrayList<>();
    reshapeData.params.add(new ParamData("瘦脸", ReshapeParam.FACE_THIN));
    reshapeData.params.add(new ParamData("V脸", ReshapeParam.FACE_V_SHAPE));
    reshapeData.params.add(new ParamData("窄脸", ReshapeParam.FACE_NARROW));
    reshapeData.params.add(new ParamData("短脸", ReshapeParam.FACE_SHORT));
    reshapeData.params.add(new ParamData("颧骨", ReshapeParam.CHEEKBONE));
    reshapeData.params.add(new ParamData("下颌骨", ReshapeParam.JAWBONE));
    reshapeData.params.add(new ParamData("下巴", ReshapeParam.CHIN));
    reshapeData.params.add(new ParamData("瘦鼻梁", ReshapeParam.NOSE_SLIM));
    reshapeData.params.add(new ParamData("大眼", ReshapeParam.EYE_SIZE));
    reshapeData.params.add(new ParamData("眼距", ReshapeParam.EYE_DISTANCE));
    mBeautyTypeDataList.add(reshapeData);

    // 美妆
    BeautyTypeData makeupData = new BeautyTypeData();
    makeupData.title = "美妆";
    makeupData.type = BeautyType.MAKEUP;
    makeupData.params = new ArrayList<>();
    makeupData.params.add(new ParamData("口红", MakeupParam.LIPSTICK));
    makeupData.params.add(new ParamData("腮红", MakeupParam.BLUSH));
    mBeautyTypeDataList.add(makeupData);

    // 背景
    BeautyTypeData segmentationData = new BeautyTypeData();
    segmentationData.title = "背景";
    segmentationData.type = BeautyType.SEGMENTATION;
    segmentationData.params = new ArrayList<>();
    segmentationData.params.add(new ParamData("背景图片", SegmentationParam.BACKGROUND_IMAGE));
    mBeautyTypeDataList.add(segmentationData);
  }

  private void initializeParamValues() {
    for (BeautyTypeData beautyType : mBeautyTypeDataList) {
      for (ParamData param : beautyType.params) {
        mParamValues.put(param.type, 0.0f);
      }
    }
  }

  private void setupUI() {
    setupBeautyTypeButtons();
    updateParamSelectionView();
  }

  private void setupBeautyTypeButtons() {
    mBeautyTypeContainer.removeAllViews();
    mBeautyTypeButtons.clear();

    for (int i = 0; i < mBeautyTypeDataList.size(); i++) {
      BeautyTypeData beautyType = mBeautyTypeDataList.get(i);

      Button button = new Button(getContext());
      button.setText(beautyType.title);
      button.setTextColor(getResources().getColor(R.color.beauty_text_normal));
      button.setBackgroundResource(R.drawable.beauty_type_button_background);
      button.setTextSize(14);
      button.setTag(i);
      button.setOnClickListener(v -> onBeautyTypeButtonClicked((Integer) v.getTag()));

      // 将 dp 转换为像素
      int buttonHeight = (int) (40 * getResources().getDisplayMetrics().density);
      LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(0, buttonHeight, 1.0f);
      mBeautyTypeContainer.addView(button, params);
      mBeautyTypeButtons.add(button);
    }

    selectBeautyTypeButton(0);
  }

  private void updateParamSelectionView() {
    mParamSelectionContainer.removeAllViews();
    mParamButtons.clear();

    BeautyTypeData currentBeautyTypeData = getCurrentBeautyTypeData();
    if (currentBeautyTypeData == null)
      return;

    for (int i = 0; i < currentBeautyTypeData.params.size(); i++) {
      ParamData param = currentBeautyTypeData.params.get(i);

      Button button = new Button(getContext());
      button.setText(param.title);
      button.setTextColor(getResources().getColor(android.R.color.white));
      button.setBackgroundResource(R.drawable.param_button_background);
      button.setTextSize(12);
      button.setTag(i);
      button.setOnClickListener(v -> onParamButtonClicked((Integer) v.getTag()));

      // 将 dp 转换为像素
      int buttonWidth = (int) (80 * getResources().getDisplayMetrics().density);
      int buttonHeight = (int) (40 * getResources().getDisplayMetrics().density);
      int margin = (int) (12 * getResources().getDisplayMetrics().density);

      LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(buttonWidth, buttonHeight);
      if (i > 0) {
        params.leftMargin = margin;
      }
      mParamSelectionContainer.addView(button, params);
      mParamButtons.add(button);
    }

    if (!mParamButtons.isEmpty()) {
      selectParamButton(0);
      updateSliderForCurrentParam();
    }
  }

  private BeautyTypeData getCurrentBeautyTypeData() {
    for (BeautyTypeData beautyType : mBeautyTypeDataList) {
      if (beautyType.type == mCurrentBeautyType) {
        return beautyType;
      }
    }
    return null;
  }

  private void onBeautyTypeButtonClicked(int index) {
    Log.d(TAG, "Beauty type button clicked: " + index);
    selectBeautyTypeButton(index);

    BeautyTypeData beautyTypeData = mBeautyTypeDataList.get(index);
    mCurrentBeautyType = beautyTypeData.type;

    updateParamSelectionView();
    updateSliderForCurrentParam();
  }

  private void onParamButtonClicked(int index) {
    Log.d(TAG, "Param button clicked: " + index);
    selectParamButton(index);

    BeautyTypeData currentBeautyTypeData = getCurrentBeautyTypeData();
    if (currentBeautyTypeData != null && index < currentBeautyTypeData.params.size()) {
      ParamData param = currentBeautyTypeData.params.get(index);
      mCurrentParamType = param.type;
      updateSliderForCurrentParam();
    }
  }

  private void updateSliderForCurrentParam() {
    Float paramValue = mParamValues.get(mCurrentParamType);
    if (paramValue != null) {
      int progress = Math.round(paramValue * 100);
      mValueSlider.setProgress(progress);
      mValueLabel.setText(progress + "%");
    }
  }

  private void selectBeautyTypeButton(int index) {
    for (int i = 0; i < mBeautyTypeButtons.size(); i++) {
      Button button = mBeautyTypeButtons.get(i);
      if (i == index) {
        button.setSelected(true);
        button.setTextColor(getResources().getColor(R.color.beauty_text_selected));
      } else {
        button.setSelected(false);
        button.setTextColor(getResources().getColor(R.color.beauty_text_normal));
      }
    }
  }

  private void selectParamButton(int index) {
    for (int i = 0; i < mParamButtons.size(); i++) {
      Button button = mParamButtons.get(i);
      button.setSelected(i == index);
    }
  }

  public void setBeautyPanelCallback(BeautyPanelCallback callback) {
    mCallback = callback;
  }

  // 数据类
  private static class BeautyTypeData {
    String title;
    BeautyType type;
    List<ParamData> params;
  }

  private static class ParamData {
    String title;
    Object type;

    ParamData(String title, Object type) {
      this.title = title;
      this.type = type;
    }
  }
}
