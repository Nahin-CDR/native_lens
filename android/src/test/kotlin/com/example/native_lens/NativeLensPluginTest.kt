package com.example.native_lens

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.Mockito
import kotlin.test.Test

/*
 * This demonstrates a simple unit test of the Kotlin portion of this plugin's implementation.
 *
 * Once you have built the plugin's example app, you can run these tests from the command
 * line by running `./gradlew testDebugUnitTest` in the `example/android/` directory, or
 * you can run them directly from IDEs that support JUnit such as Android Studio.
 */

internal class NativeLensPluginTest {
    @Test
    fun onMethodCall_getPlatformSummary_returnsExpectedValue() {
        val plugin = NativeLensPlugin()

        val call = MethodCall("getPlatformSummary", null)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)

        val expectedSummary =
            mapOf(
                "manufacturer" to android.os.Build.MANUFACTURER,
                "brand" to android.os.Build.BRAND,
                "model" to android.os.Build.MODEL,
                "device" to android.os.Build.DEVICE,
                "product" to android.os.Build.PRODUCT,
                "androidSdk" to android.os.Build.VERSION.SDK_INT,
                "androidRelease" to android.os.Build.VERSION.RELEASE
            )

        Mockito.verify(mockResult).success(expectedSummary)
    }
}
