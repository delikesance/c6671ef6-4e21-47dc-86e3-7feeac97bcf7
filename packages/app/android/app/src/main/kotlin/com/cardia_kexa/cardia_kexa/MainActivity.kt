package com.cardia_kexa.cardia_kexa

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "BotCreator"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        // Install a global exception handler *before* super.onCreate so it
        // covers the earliest possible window.  We keep a reference to the
        // previous handler and delegate to it for everything except the
        // ProxyBillingActivity NPE that we intentionally suppress.
        val previousHandler = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            if (isProxyBillingActivityNpe(throwable)) {
                Log.w(
                    TAG,
                    "Suppressed ProxyBillingActivity crash – " +
                        "Play Services returned null PendingIntent. " +
                        "The purchase flow will fail gracefully.",
                    throwable,
                )
                // Do NOT re-throw and do NOT call previousHandler.
                // The app process continues normally.
                return@setDefaultUncaughtExceptionHandler
            }
            // Delegate everything else to the previous handler
            // (Firebase Crashlytics, default Android handler, etc.).
            previousHandler?.uncaughtException(thread, throwable)
        }

        super.onCreate(savedInstanceState)
    }

    /**
     * Returns `true` when [throwable] is the known Play Billing Library crash:
     *
     *   java.lang.RuntimeException: Unable to start activity
     *   ComponentInfo{.../com.android.billingclient.api.ProxyBillingActivity}:
     *   java.lang.NullPointerException: Attempt to invoke virtual method
     *   'android.content.IntentSender android.app.PendingIntent.getIntentSender()'
     *   on a null object reference
     *
     * This happens when `BillingClient.launchBillingFlow()` receives a null
     * `PendingIntent` from Play Services.  The library still tries to launch
     * `ProxyBillingActivity` with that null intent, triggering the NPE.
     *
     * Suppressing this exception keeps the app alive.  The purchase flow
     * simply doesn't open — the user stays on the subscription page.
     */
    private fun isProxyBillingActivityNpe(throwable: Throwable): Boolean {
        // Walk the causal chain; the NPE is often wrapped in a RuntimeException.
        var current: Throwable? = throwable
        while (current != null) {
            val message = current.message ?: ""

            if (message.contains("ProxyBillingActivity") &&
                current is RuntimeException
            ) {
                // Check if the *cause* is the null-PendingIntent NPE.
                val cause = current.cause
                if (cause is NullPointerException) {
                    val causeMessage = cause.message ?: ""
                    if (causeMessage.contains("PendingIntent") &&
                        causeMessage.contains("getIntentSender")
                    ) {
                        return true
                    }
                }
            }

            // Also check if the throwable ITSELF is the NPE (unwrapped).
            if (message.contains("PendingIntent") &&
                message.contains("getIntentSender") &&
                current is NullPointerException
            ) {
                return true
            }

            current = current.cause
        }
        return false
    }
}
