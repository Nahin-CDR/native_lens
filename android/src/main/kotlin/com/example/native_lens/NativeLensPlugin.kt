package com.example.native_lens

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.FeatureInfo
import android.content.pm.PackageManager
import android.hardware.camera2.CameraAccessException
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.hardware.camera2.CameraMetadata
import android.hardware.Sensor
import android.hardware.SensorManager
import android.media.MediaCodecInfo
import android.media.MediaCodecList
import android.os.BatteryManager
import android.os.Build
import android.os.PowerManager
import android.util.DisplayMetrics
import android.view.Display
import android.view.WindowManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** NativeLensPlugin */
class NativeLensPlugin :
    FlutterPlugin,
    MethodCallHandler {
    // The MethodChannel that will the communication between Flutter and native Android
    //
    // This local reference serves to register the plugin with the Flutter Engine and unregister it
    // when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var applicationContext: Context
    private lateinit var packageManager: PackageManager
    private lateinit var cameraManager: CameraManager
    private lateinit var powerManager: PowerManager
    private lateinit var sensorManager: SensorManager
    private lateinit var windowManager: WindowManager

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "native_lens")
        channel.setMethodCallHandler(this)
        applicationContext = flutterPluginBinding.applicationContext
        packageManager = applicationContext.packageManager
        cameraManager =
            applicationContext.getSystemService(Context.CAMERA_SERVICE) as CameraManager
        powerManager =
            applicationContext.getSystemService(Context.POWER_SERVICE) as PowerManager
        sensorManager =
            applicationContext.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        windowManager =
            applicationContext.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when (call.method) {
            "getPlatformSummary" -> result.success(getPlatformSummary())
            "getSystemFeatures" -> result.success(getSystemFeatures())
            "getSensors" -> result.success(getSensors())
            "getDisplayInfo" -> result.success(getDisplayInfo())
            "getMediaCodecs" -> result.success(getMediaCodecs())
            "getCameraCapabilities" -> result.success(getCameraCapabilities())
            "getPowerState" -> result.success(getPowerState())
            else -> result.notImplemented()
        }
    }

    private fun getPlatformSummary(): Map<String, Any> {
        return mapOf(
            "manufacturer" to Build.MANUFACTURER,
            "brand" to Build.BRAND,
            "model" to Build.MODEL,
            "device" to Build.DEVICE,
            "product" to Build.PRODUCT,
            "androidSdk" to Build.VERSION.SDK_INT,
            "androidRelease" to Build.VERSION.RELEASE
        )
    }

    private fun getSystemFeatures(): List<Map<String, Any?>> {
        val availableFeatures = packageManager.systemAvailableFeatures ?: emptyArray()

        return availableFeatures.map { featureInfo ->
            val isGlEsFeature = isGlEsFeature(featureInfo)
            val featureName =
                if (isGlEsFeature) {
                    "OpenGL ES"
                } else {
                    featureInfo.name ?: "Unknown"
                }

            mapOf(
                "name" to featureName,
                "version" to getFeatureVersion(featureInfo, isGlEsFeature),
                "isGlEsFeature" to isGlEsFeature
            )
        }
    }

    private fun isGlEsFeature(featureInfo: FeatureInfo): Boolean {
        return featureInfo.name == null &&
            featureInfo.reqGlEsVersion != FeatureInfo.GL_ES_VERSION_UNDEFINED
    }

    private fun getFeatureVersion(
        featureInfo: FeatureInfo,
        isGlEsFeature: Boolean
    ): Int? {
        if (isGlEsFeature) {
            return featureInfo.reqGlEsVersion
        }

        if (featureInfo.version > 0) {
            return featureInfo.version
        }

        return null
    }

    private fun getSensors(): List<Map<String, Any>> {
        return sensorManager.getSensorList(Sensor.TYPE_ALL).map { sensor ->
            mapOf(
                "name" to sensor.name,
                "vendor" to sensor.vendor,
                "type" to sensor.type,
                "typeName" to getSensorTypeName(sensor.type),
                "version" to sensor.version,
                "resolution" to sensor.resolution,
                "maximumRange" to sensor.maximumRange,
                "power" to sensor.power,
                "minDelay" to sensor.minDelay,
                "maxDelay" to sensor.maxDelay,
                "isWakeUpSensor" to sensor.isWakeUpSensor
            )
        }
    }

    private fun getSensorTypeName(type: Int): String {
        return when (type) {
            Sensor.TYPE_ACCELEROMETER -> "Accelerometer"
            Sensor.TYPE_MAGNETIC_FIELD -> "Magnetic Field"
            Sensor.TYPE_ORIENTATION -> "Orientation"
            Sensor.TYPE_GYROSCOPE -> "Gyroscope"
            Sensor.TYPE_LIGHT -> "Light"
            Sensor.TYPE_PRESSURE -> "Pressure"
            Sensor.TYPE_TEMPERATURE -> "Temperature"
            Sensor.TYPE_PROXIMITY -> "Proximity"
            Sensor.TYPE_GRAVITY -> "Gravity"
            Sensor.TYPE_LINEAR_ACCELERATION -> "Linear Acceleration"
            Sensor.TYPE_ROTATION_VECTOR -> "Rotation Vector"
            Sensor.TYPE_RELATIVE_HUMIDITY -> "Relative Humidity"
            Sensor.TYPE_AMBIENT_TEMPERATURE -> "Ambient Temperature"
            Sensor.TYPE_MAGNETIC_FIELD_UNCALIBRATED -> "Magnetic Field Uncalibrated"
            Sensor.TYPE_GAME_ROTATION_VECTOR -> "Game Rotation Vector"
            Sensor.TYPE_GYROSCOPE_UNCALIBRATED -> "Gyroscope Uncalibrated"
            Sensor.TYPE_SIGNIFICANT_MOTION -> "Significant Motion"
            Sensor.TYPE_STEP_DETECTOR -> "Step Detector"
            Sensor.TYPE_STEP_COUNTER -> "Step Counter"
            Sensor.TYPE_GEOMAGNETIC_ROTATION_VECTOR -> "Geomagnetic Rotation Vector"
            Sensor.TYPE_HEART_RATE -> "Heart Rate"
            Sensor.TYPE_POSE_6DOF -> "Pose 6DoF"
            Sensor.TYPE_STATIONARY_DETECT -> "Stationary Detect"
            Sensor.TYPE_MOTION_DETECT -> "Motion Detect"
            Sensor.TYPE_HEART_BEAT -> "Heart Beat"
            Sensor.TYPE_LOW_LATENCY_OFFBODY_DETECT -> "Low Latency Offbody Detect"
            Sensor.TYPE_ACCELEROMETER_UNCALIBRATED -> "Accelerometer Uncalibrated"
            else -> "Unknown Type $type"
        }
    }

    private fun getDisplayInfo(): Map<String, Any> {
        val display = getCurrentDisplay()
        val metrics = getDisplayMetrics(display)
        val supportedHdrTypes = getSupportedHdrTypes(display)

        return mapOf(
            "widthPixels" to metrics.widthPixels,
            "heightPixels" to metrics.heightPixels,
            "density" to metrics.density.toDouble(),
            "densityDpi" to metrics.densityDpi,
            "refreshRate" to getRefreshRate(display),
            "supportedRefreshRates" to getSupportedRefreshRates(display),
            "isHdrSupported" to supportedHdrTypes.isNotEmpty(),
            "supportedHdrTypes" to supportedHdrTypes
        )
    }

    @Suppress("DEPRECATION")
    private fun getCurrentDisplay(): Display? {
        return windowManager.defaultDisplay
    }

    @Suppress("DEPRECATION")
    private fun getDisplayMetrics(display: Display?): DisplayMetrics {
        val metrics = DisplayMetrics()

        if (display != null) {
            display.getRealMetrics(metrics)
            return metrics
        }

        return applicationContext.resources.displayMetrics
    }

    private fun getRefreshRate(display: Display?): Double {
        if (display == null) {
            return 0.0
        }

        return display.refreshRate.toDouble()
    }

    private fun getSupportedRefreshRates(display: Display?): List<Double> {
        if (display == null || Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            val refreshRate = getRefreshRate(display)
            if (refreshRate > 0.0) {
                return listOf(refreshRate)
            }
            return emptyList()
        }

        return display.supportedModes
            .map { mode -> mode.refreshRate.toDouble() }
            .distinct()
            .sorted()
    }

    private fun getSupportedHdrTypes(display: Display?): List<String> {
        if (display == null || Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            return emptyList()
        }

        return display.hdrCapabilities.supportedHdrTypes.map { hdrType ->
            getHdrTypeName(hdrType)
        }
    }

    private fun getHdrTypeName(hdrType: Int): String {
        return when (hdrType) {
            Display.HdrCapabilities.HDR_TYPE_DOLBY_VISION -> "Dolby Vision"
            Display.HdrCapabilities.HDR_TYPE_HDR10 -> "HDR10"
            Display.HdrCapabilities.HDR_TYPE_HLG -> "HLG"
            Display.HdrCapabilities.HDR_TYPE_HDR10_PLUS -> "HDR10+"
            else -> "Unknown HDR Type $hdrType"
        }
    }

    private fun getMediaCodecs(): List<Map<String, Any>> {
        val codecInfos = MediaCodecList(MediaCodecList.ALL_CODECS).codecInfos

        return codecInfos.map { codecInfo ->
            val supportedTypes = codecInfo.supportedTypes.toList()
            val supportedVideoTypes = supportedTypes.filter { mimeType ->
                mimeType.startsWith("video/")
            }
            val supportedAudioTypes = supportedTypes.filter { mimeType ->
                mimeType.startsWith("audio/")
            }

            mapOf(
                "name" to codecInfo.name,
                "isEncoder" to codecInfo.isEncoder,
                "supportedTypes" to supportedTypes,
                "isHardwareAccelerated" to isCodecHardwareAccelerated(codecInfo),
                "isSoftwareOnly" to isCodecSoftwareOnly(codecInfo),
                "isVendor" to isCodecVendor(codecInfo),
                "supportedVideoTypes" to supportedVideoTypes,
                "supportedAudioTypes" to supportedAudioTypes
            )
        }
    }

    private fun isCodecHardwareAccelerated(codecInfo: MediaCodecInfo): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return false
        }

        return codecInfo.isHardwareAccelerated
    }

    private fun isCodecSoftwareOnly(codecInfo: MediaCodecInfo): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return false
        }

        return codecInfo.isSoftwareOnly
    }

    private fun isCodecVendor(codecInfo: MediaCodecInfo): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return false
        }

        return codecInfo.isVendor
    }

    private fun getCameraCapabilities(): List<Map<String, Any>> {
        val cameras = mutableListOf<Map<String, Any>>()
        val cameraIds =
            try {
                cameraManager.cameraIdList
            } catch (exception: CameraAccessException) {
                return emptyList()
            } catch (exception: RuntimeException) {
                return emptyList()
            }

        for (cameraId in cameraIds) {
            try {
                val characteristics = cameraManager.getCameraCharacteristics(cameraId)
                cameras.add(getCameraCapability(cameraId, characteristics))
            } catch (exception: CameraAccessException) {
                // Skip cameras that cannot be queried so one failure does not break the list.
            } catch (exception: RuntimeException) {
                // Some devices expose camera IDs that can fail during metadata reads.
            }
        }

        return cameras
    }

    private fun getCameraCapability(
        cameraId: String,
        characteristics: CameraCharacteristics
    ): Map<String, Any> {
        return mapOf(
            "cameraId" to cameraId,
            "lensFacing" to getLensFacingName(characteristics),
            "hardwareLevel" to getHardwareLevelName(characteristics),
            "hasFlash" to (characteristics.get(CameraCharacteristics.FLASH_INFO_AVAILABLE)
                ?: false),
            "sensorOrientation" to (characteristics.get(CameraCharacteristics.SENSOR_ORIENTATION)
                ?: 0),
            "supportsRawCapture" to hasCameraCapability(
                characteristics,
                CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES_RAW
            ),
            "supportsManualSensor" to hasCameraCapability(
                characteristics,
                CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES_MANUAL_SENSOR
            ),
            "supportsManualPostProcessing" to hasCameraCapability(
                characteristics,
                CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES_MANUAL_POST_PROCESSING
            ),
            "supportsAutoFocus" to supportsAutoFocus(characteristics),
            "supportsOpticalStabilization" to supportsOpticalStabilization(characteristics),
            "supportedFpsRanges" to getSupportedFpsRanges(characteristics)
        )
    }

    private fun getLensFacingName(characteristics: CameraCharacteristics): String {
        return when (characteristics.get(CameraCharacteristics.LENS_FACING)) {
            CameraCharacteristics.LENS_FACING_FRONT -> "Front"
            CameraCharacteristics.LENS_FACING_BACK -> "Back"
            CameraCharacteristics.LENS_FACING_EXTERNAL -> "External"
            else -> "Unknown"
        }
    }

    private fun getHardwareLevelName(characteristics: CameraCharacteristics): String {
        return when (characteristics.get(CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL)) {
            CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL_LEGACY -> "Legacy"
            CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL_LIMITED -> "Limited"
            CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL_FULL -> "Full"
            CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL_3 -> "Level 3"
            CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL_EXTERNAL -> "External"
            else -> "Unknown"
        }
    }

    private fun hasCameraCapability(
        characteristics: CameraCharacteristics,
        capability: Int
    ): Boolean {
        val capabilities =
            characteristics.get(CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES)
                ?: return false

        return capabilities.contains(capability)
    }

    private fun supportsAutoFocus(characteristics: CameraCharacteristics): Boolean {
        val autoFocusModes =
            characteristics.get(CameraCharacteristics.CONTROL_AF_AVAILABLE_MODES)
                ?: return false

        return autoFocusModes.any { mode ->
            mode != CameraMetadata.CONTROL_AF_MODE_OFF
        }
    }

    private fun supportsOpticalStabilization(characteristics: CameraCharacteristics): Boolean {
        val stabilizationModes =
            characteristics.get(CameraCharacteristics.LENS_INFO_AVAILABLE_OPTICAL_STABILIZATION)
                ?: return false

        return stabilizationModes.contains(
            CameraMetadata.LENS_OPTICAL_STABILIZATION_MODE_ON
        )
    }

    private fun getSupportedFpsRanges(characteristics: CameraCharacteristics): List<String> {
        val ranges =
            characteristics.get(CameraCharacteristics.CONTROL_AE_AVAILABLE_TARGET_FPS_RANGES)
                ?: return emptyList()

        return ranges.map { range ->
            "${range.lower}-${range.upper} fps"
        }
    }

    private fun getPowerState(): Map<String, Any> {
        val batteryIntent = getBatteryIntent()
        val batteryLevel = getBatteryLevel(batteryIntent)
        val batteryStatus = batteryIntent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        val batteryHealth = batteryIntent?.getIntExtra(BatteryManager.EXTRA_HEALTH, -1) ?: -1
        val plugged = batteryIntent?.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0) ?: 0
        val temperature = batteryIntent?.getIntExtra(
            BatteryManager.EXTRA_TEMPERATURE,
            Int.MIN_VALUE
        ) ?: Int.MIN_VALUE

        return mapOf(
            "batteryLevel" to batteryLevel,
            "isCharging" to isBatteryCharging(batteryStatus),
            "chargingSource" to getChargingSourceName(plugged),
            "batteryHealth" to getBatteryHealthName(batteryHealth),
            "batteryStatus" to getBatteryStatusName(batteryStatus),
            "batteryTemperatureCelsius" to getBatteryTemperatureCelsius(temperature),
            "isPowerSaveMode" to isPowerSaveModeEnabled(),
            "isIgnoringBatteryOptimizations" to isIgnoringBatteryOptimizations()
        )
    }

    private fun getBatteryIntent(): Intent? {
        return applicationContext.registerReceiver(
            null,
            IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        )
    }

    private fun getBatteryLevel(batteryIntent: Intent?): Int {
        if (batteryIntent == null) {
            return getBatteryLevelFromManager()
        }

        val level = batteryIntent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
        val scale = batteryIntent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)

        if (level >= 0 && scale > 0) {
            return ((level.toFloat() / scale.toFloat()) * 100).toInt()
        }

        return getBatteryLevelFromManager()
    }

    private fun getBatteryLevelFromManager(): Int {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            return 0
        }

        val batteryManager =
            applicationContext.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val level = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)

        if (level >= 0) {
            return level
        }

        return 0
    }

    private fun isBatteryCharging(status: Int): Boolean {
        return status == BatteryManager.BATTERY_STATUS_CHARGING ||
            status == BatteryManager.BATTERY_STATUS_FULL
    }

    private fun getChargingSourceName(plugged: Int): String {
        return when (plugged) {
            BatteryManager.BATTERY_PLUGGED_AC -> "AC"
            BatteryManager.BATTERY_PLUGGED_USB -> "USB"
            BatteryManager.BATTERY_PLUGGED_WIRELESS -> "Wireless"
            0 -> "Not charging"
            else -> "Unknown"
        }
    }

    private fun getBatteryHealthName(health: Int): String {
        return when (health) {
            BatteryManager.BATTERY_HEALTH_GOOD -> "Good"
            BatteryManager.BATTERY_HEALTH_OVERHEAT -> "Overheat"
            BatteryManager.BATTERY_HEALTH_DEAD -> "Dead"
            BatteryManager.BATTERY_HEALTH_OVER_VOLTAGE -> "Over voltage"
            BatteryManager.BATTERY_HEALTH_UNSPECIFIED_FAILURE -> "Unspecified failure"
            BatteryManager.BATTERY_HEALTH_COLD -> "Cold"
            else -> "Unknown"
        }
    }

    private fun getBatteryStatusName(status: Int): String {
        return when (status) {
            BatteryManager.BATTERY_STATUS_CHARGING -> "Charging"
            BatteryManager.BATTERY_STATUS_DISCHARGING -> "Discharging"
            BatteryManager.BATTERY_STATUS_NOT_CHARGING -> "Not charging"
            BatteryManager.BATTERY_STATUS_FULL -> "Full"
            else -> "Unknown"
        }
    }

    private fun getBatteryTemperatureCelsius(temperature: Int): Double {
        if (temperature == Int.MIN_VALUE) {
            return 0.0
        }

        return temperature / 10.0
    }

    private fun isPowerSaveModeEnabled(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            return false
        }

        return powerManager.isPowerSaveMode
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return false
        }

        return powerManager.isIgnoringBatteryOptimizations(applicationContext.packageName)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
