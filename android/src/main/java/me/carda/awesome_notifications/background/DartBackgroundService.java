package me.carda.awesome_notifications.background;

import android.content.Context;
import android.content.Intent;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.core.app.JobIntentService;
import me.carda.awesome_notifications.notifications.managers.DefaultsManager;

public class DartBackgroundService extends JobIntentService {
    private static final String TAG = "DartBackgroundService";

    @Override
    protected void onHandleWork(@NonNull final Intent intent) {

        long dartCallbackHandle = getDartCallbackDispatcher(this);
        if (dartCallbackHandle == 0L) {
            Log.w(TAG, "A background message could not be handled in Dart" +
                            " because there is no onSilentData handler registered.");
            return;
        }

        long silentCallbackHandle = getSilentCallbackDispatcher(this);
        if (silentCallbackHandle == 0L) {
            Log.w(TAG,"A background message could not be handled in Dart" +
                            " because there is no dart background handler registered.");
            return;
        }

        DartBackgroundExecutor.runBackgroundExecutor(
                this,
                intent,
                dartCallbackHandle,
                silentCallbackHandle);
    }

    public static long getDartCallbackDispatcher(Context context){
        return DefaultsManager.getDartCallbackDispatcher(context);
    }

    public static long getSilentCallbackDispatcher(Context context){
        return DefaultsManager.getSilentCallbackDispatcher(context);
    }
}