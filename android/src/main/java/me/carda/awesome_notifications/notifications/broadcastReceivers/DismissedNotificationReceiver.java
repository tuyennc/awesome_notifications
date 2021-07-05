package me.carda.awesome_notifications.notifications.broadcastReceivers;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.NotificationBuilder;
import me.carda.awesome_notifications.notifications.NotificationSender;
import me.carda.awesome_notifications.notifications.models.NotificationModel;
import me.carda.awesome_notifications.notifications.models.returnedData.ActionReceived;

public class DismissedNotificationReceiver extends BroadcastReceiver
{
    static String TAG = "DismissedNotificationReceiver";

    @Override
    public void onReceive(Context context, Intent intent) {

        String action = intent.getAction();

        if (action != null && action.equals(Definitions.DISMISSED_NOTIFICATION)) {

            NotificationModel notificationModel = NotificationBuilder.buildNotificationModelFromIntent(intent);
            ActionReceived actionReceived = NotificationBuilder.buildNotificationActionFromNotificationModel(context, notificationModel, intent);
            NotificationBuilder.finalizeNotificationIntent(context, notificationModel, intent);

            NotificationSender.sendDismissedNotification(context, actionReceived);
        }
    }
}
