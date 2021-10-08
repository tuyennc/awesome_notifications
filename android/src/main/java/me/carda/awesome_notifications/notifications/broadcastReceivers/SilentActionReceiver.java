package me.carda.awesome_notifications.notifications.broadcastReceivers;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

import me.carda.awesome_notifications.notifications.NotificationBroadcaster;
import me.carda.awesome_notifications.notifications.NotificationBuilder;
import me.carda.awesome_notifications.notifications.models.NotificationModel;

public class SilentActionReceiver extends BroadcastReceiver {

    @Override
    public void onReceive(final Context context, Intent intent) {

        NotificationModel notificationModel = NotificationBuilder.buildNotificationModelFromIntent(intent);
        NotificationBuilder.finalizeNotificationIntent(context, notificationModel, intent);

        if(NotificationBuilder.notificationIntentDisabledAction(intent)){
            return;
        }

        if (notificationModel != null) {

            try {
                NotificationBroadcaster.broadcastSilentData(
                    context,
                    notificationModel,
                    intent
                );
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
}
