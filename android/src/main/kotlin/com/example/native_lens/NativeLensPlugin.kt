package com.example.native_lens

import android.content.Context
import android.content.pm.FeatureInfo
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorManager
import android.os.Build
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
    private lateinit var sensorManager: SensorManager
    private lateinit var windowManager: WindowManager

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "native_lens")
        channel.setMethodCallHandler(this)
        applicationContext = flutterPluginBinding.applicationContext
        packageManager = applicationContext.packageManager
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

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
