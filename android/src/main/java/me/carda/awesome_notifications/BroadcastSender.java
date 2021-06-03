package me.carda.awesome_notifications;

import android.content.Context;
import android.content.Intent;

import java.io.Serializable;
import java.util.Map;

import androidx.localbroadcastmanager.content.LocalBroadcastManager;
import io.flutter.Log;
import me.carda.awesome_notifications.notifications.managers.DismissedManager;
import me.carda.awesome_notifications.notifications.models.returnedData.ActionReceived;
import me.carda.awesome_notifications.notifications.models.returnedData.NotificationReceived;

public class BroadcastSender {

    private static final String TAG = "BroadcastSender";

    public static Boolean SendBroadcastNotificationCreated(Context context, NotificationReceived notificationReceived){

        boolean success = false;

        Map<String, Object> data = notificationReceived.toMap();

        Intent intent = new Intent(Definitions.BROADCAST_CREATED_NOTIFICATION);
        intent.putExtra(Definitions.EXTRA_BROADCAST_MESSAGE, (Serializable) data);
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);

        try {

            LocalBroadcastManager broadcastManager = LocalBroadcastManager.getInstance(context);
            success = broadcastManager.sendBroadcast(intent);

        } catch (Exception e) {
            e.printStackTrace();
        }

        return success;
    }

    public static Boolean SendBroadcastKeepOnTopAction(Context context, ActionReceived actionReceived){

        boolean success = false;

        Intent intent = new Intent(Definitions.BROADCAST_KEEP_ON_TOP);
        intent.putExtra(Definitions.EXTRA_BROADCAST_MESSAGE, (Serializable) actionReceived.toMap());
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);

        try {

            LocalBroadcastManager broadcastManager = LocalBroadcastManager.getInstance(context);
            success = broadcastManager.sendBroadcast(intent);

        } catch (Exception e) {
            e.printStackTrace();
        }

        return success;
    }

    public static Boolean SendBroadcastNotificationDisplayed(Context context, NotificationReceived notificationReceived){

        boolean success = false;

        Map<String, Object> data = notificationReceived.toMap();

        Intent intent = new Intent(Definitions.BROADCAST_DISPLAYED_NOTIFICATION);
        intent.putExtra(Definitions.EXTRA_BROADCAST_MESSAGE, (Serializable) data);
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);

        try {

            LocalBroadcastManager broadcastManager = LocalBroadcastManager.getInstance(context);
            success = broadcastManager.sendBroadcast(intent);

        } catch (Exception e) {
            e.printStackTrace();
        }

        return success;
    }

    public static Boolean SendBroadcastNotificationDismissed(Context context, ActionReceived actionReceived){

        boolean success = false;

        DismissedManager.saveDismissed(context, actionReceived);

        Map<String, Object> data = actionReceived.toMap();

        Intent intent = new Intent(Definitions.BROADCAST_DISMISSED_NOTIFICATION);
        intent.putExtra(Definitions.EXTRA_BROADCAST_MESSAGE, (Serializable) data);
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);

        try {

            LocalBroadcastManager broadcastManager = LocalBroadcastManager.getInstance(context);
            success = broadcastManager.sendBroadcast(intent);

        } catch (Exception e) {
            e.printStackTrace();
        }

        return success;
    }

    public static Boolean SendBroadcastMediaButton(Context context, ActionReceived actionReceived){

        boolean success = false;

        Map<String, Object> data = actionReceived.toMap();

        Intent intent = new Intent(Definitions.BROADCAST_MEDIA_BUTTON);
        intent.putExtra(Definitions.EXTRA_BROADCAST_MESSAGE, (Serializable) data);
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);

        try {

            LocalBroadcastManager broadcastManager = LocalBroadcastManager.getInstance(context);
            success = broadcastManager.sendBroadcast(intent);

        } catch (Exception e) {
            e.printStackTrace();
        }

        return success;
    }
}
