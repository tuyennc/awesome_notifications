package me.carda.awesome_notifications.notifications;

import android.content.Context;
import android.content.Intent;

import java.io.Serializable;
import java.util.Map;

import androidx.core.app.JobIntentService;
import androidx.localbroadcastmanager.content.LocalBroadcastManager;
import me.carda.awesome_notifications.AwesomeNotificationsPlugin;
import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.background.DartBackgroundExecutor;
import me.carda.awesome_notifications.background.DartBackgroundService;
import me.carda.awesome_notifications.notifications.enumerators.NotificationLifeCycle;
import me.carda.awesome_notifications.notifications.managers.DismissedManager;
import me.carda.awesome_notifications.notifications.models.NotificationModel;
import me.carda.awesome_notifications.notifications.models.returnedData.ActionReceived;
import me.carda.awesome_notifications.notifications.models.returnedData.NotificationReceived;

public class NotificationGateKeeper {

    private static final String TAG = "BroadcastSender";

    public static Boolean broadcastNotificationCreated(Context context, NotificationReceived notificationReceived){

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

    public static Boolean broadcastNotificationDisplayed(Context context, NotificationReceived notificationReceived){

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

    public static Boolean broadcastNotificationDismissed(Context context, ActionReceived actionReceived){

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

    public static Boolean SendBroadcastKeepOnTopAction(Context context, ActionReceived actionReceived){

        Boolean success = false;

        Intent intent = new Intent(Definitions.BROADCAST_KEEP_ON_TOP);
        intent.putExtra(Definitions.EXTRA_BROADCAST_MESSAGE, (Serializable) actionReceived.toMap());

        try {

            LocalBroadcastManager broadcastManager = LocalBroadcastManager.getInstance(context);
            success = broadcastManager.sendBroadcast(intent);

            if(success){
                //Log.d(TAG, "Sent created to broadcast");
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        return success;
    }

    public static Boolean broadcastSilentData(Context context, NotificationModel notificationModel, Intent originalIntent){

        switch (notificationModel.content.notificationActionType){

            case BringToForeground:
            case DisabledAction:
                return false;

            /*case SilentBackgroundThread:
                break;*/

            case SilentMainThread:
                if(AwesomeNotificationsPlugin.appLifeCycle != NotificationLifeCycle.AppKilled){
                    try {
                        Intent intent = new Intent(Definitions.BROADCAST_SILENT_ACTION);
                        intent.putExtra(Definitions.EXTRA_BROADCAST_MESSAGE, (Serializable) notificationModel.toMap());
                        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);

                        LocalBroadcastManager broadcastManager = LocalBroadcastManager.getInstance(context);
                        return broadcastManager.sendBroadcast(intent);
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
                break;

        }

        Intent serviceIntent =
            DartBackgroundExecutor.notificationBuilder.buildNotificationIntentFromModel(
                context,
                originalIntent.getAction(),
                notificationModel,
                DartBackgroundService.class);

        serviceIntent.putExtras(originalIntent);

        JobIntentService.enqueueWork(
            context,
            DartBackgroundService.class,
            42,
            serviceIntent);

        return true;
/*
        Intent intent = new Intent(Definitions.BROADCAST_KEEP_ON_TOP);
        intent.putExtra(Definitions.EXTRA_BROADCAST_MESSAGE, (Serializable) notificationModel.toMap());
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);

        try {

            LocalBroadcastManager broadcastManager = LocalBroadcastManager.getInstance(context);
            success = broadcastManager.sendBroadcast(intent);

        } catch (Exception e) {
            e.printStackTrace();
        }

        return success;*/
    }
}
