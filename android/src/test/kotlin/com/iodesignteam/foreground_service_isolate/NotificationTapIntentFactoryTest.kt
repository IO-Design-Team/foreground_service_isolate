package com.iodesignteam.foreground_service_isolate

import android.app.PendingIntent
import android.content.Intent
import android.net.Uri
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf

@RunWith(RobolectricTestRunner::class)
class NotificationTapIntentFactoryTest {
    private val context = ApplicationProvider.getApplicationContext<android.content.Context>()
    private val packageName = context.packageName

    @Test
    fun noneAction_returnsNullPendingIntent() {
        val pendingIntent = NotificationTapIntentFactory.create(
            context = context,
            packageName = packageName,
            notificationId = 1,
            tapAction = "none",
            tapDeepLink = null,
            tapIntentAction = null
        )

        assertNull(pendingIntent)
    }

    @Test
    fun launchDeepLink_createsActionViewIntent() {
        val deepLink = "foreground-service-isolate://session/123"
        val pendingIntent = NotificationTapIntentFactory.create(
            context = context,
            packageName = packageName,
            notificationId = 2,
            tapAction = "launchDeepLink",
            tapDeepLink = deepLink,
            tapIntentAction = null
        )

        assertNotNull(pendingIntent)
        val savedIntent = shadowOf(pendingIntent as PendingIntent).savedIntent
        assertEquals(Intent.ACTION_VIEW, savedIntent.action)
        assertEquals(Uri.parse(deepLink), savedIntent.data)
        assertHasLaunchFlags(savedIntent)
    }

    @Test
    fun launchIntentAction_createsPackageScopedIntent() {
        val action = "com.example.OPEN_FROM_NOTIFICATION"
        val pendingIntent = NotificationTapIntentFactory.create(
            context = context,
            packageName = packageName,
            notificationId = 3,
            tapAction = "launchIntentAction",
            tapDeepLink = null,
            tapIntentAction = action
        )

        assertNotNull(pendingIntent)
        val savedIntent = shadowOf(pendingIntent as PendingIntent).savedIntent
        assertEquals(action, savedIntent.action)
        assertEquals(packageName, savedIntent.`package`)
        assertHasLaunchFlags(savedIntent)
    }

    @Test
    fun launchDeepLink_withoutLink_returnsNullPendingIntent() {
        val pendingIntent = NotificationTapIntentFactory.create(
            context = context,
            packageName = packageName,
            notificationId = 31,
            tapAction = "launchDeepLink",
            tapDeepLink = null,
            tapIntentAction = null
        )

        assertNull(pendingIntent)
    }

    @Test
    fun launchIntentAction_withoutAction_returnsNullPendingIntent() {
        val pendingIntent = NotificationTapIntentFactory.create(
            context = context,
            packageName = packageName,
            notificationId = 32,
            tapAction = "launchIntentAction",
            tapDeepLink = null,
            tapIntentAction = null
        )

        assertNull(pendingIntent)
    }

    @Test
    fun launchApp_usesProvidedLaunchIntent() {
        val launchIntent = Intent(Intent.ACTION_MAIN).apply {
            setPackage(packageName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        val pendingIntent = NotificationTapIntentFactory.create(
            context = context,
            packageName = packageName,
            notificationId = 4,
            tapAction = "launchApp",
            tapDeepLink = null,
            tapIntentAction = null,
            launchAppIntent = launchIntent
        )

        assertNotNull(pendingIntent)
        val savedIntent = shadowOf(pendingIntent as PendingIntent).savedIntent
        assertEquals(Intent.ACTION_MAIN, savedIntent.action)
        assertEquals(packageName, savedIntent.`package`)
        assertHasLaunchFlags(savedIntent)
    }

    @Test
    fun unknownAction_fallsBackToLaunchAppIntent() {
        val launchIntent = Intent(Intent.ACTION_MAIN).apply {
            setPackage(packageName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        val pendingIntent = NotificationTapIntentFactory.create(
            context = context,
            packageName = packageName,
            notificationId = 5,
            tapAction = "unknownAction",
            tapDeepLink = null,
            tapIntentAction = null,
            launchAppIntent = launchIntent
        )

        assertNotNull(pendingIntent)
        val savedIntent = shadowOf(pendingIntent as PendingIntent).savedIntent
        assertEquals(Intent.ACTION_MAIN, savedIntent.action)
        assertEquals(packageName, savedIntent.`package`)
        assertHasLaunchFlags(savedIntent)
    }

    @Test
    fun unknownAction_withoutLaunchIntent_returnsNullPendingIntent() {
        val pendingIntent = NotificationTapIntentFactory.create(
            context = context,
            packageName = packageName,
            notificationId = 6,
            tapAction = "unknownAction",
            tapDeepLink = null,
            tapIntentAction = null,
            launchAppIntent = null
        )

        assertNull(pendingIntent)
    }

    private fun assertHasLaunchFlags(intent: Intent) {
        assertTrue((intent.flags and Intent.FLAG_ACTIVITY_NEW_TASK) != 0)
        assertTrue((intent.flags and Intent.FLAG_ACTIVITY_SINGLE_TOP) != 0)
    }
}
