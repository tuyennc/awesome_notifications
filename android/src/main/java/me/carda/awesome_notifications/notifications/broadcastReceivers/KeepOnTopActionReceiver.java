package me.carda.awesome_notifications.notifications.broadcastReceivers;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

import me.carda.awesome_notifications.notifications.NotificationBuilder;
import me.carda.awesome_notifications.notifications.NotificationGateKeeper;
import me.carda.awesome_notifications.notifications.models.NotificationModel;
import me.carda.awesome_notifications.notifications.models.returnedData.ActionReceived;

/**
 * Created by michaelbui on 24/3/18.
 */

public class KeepOnTopActionReceiver extends BroadcastReceiver {

    @Override
    public void onReceive(final Context context, Intent intent) {

        NotificationModel notificationModel = NotificationBuilder.buildNotificationModelFromIntent(intent);
        ActionReceived actionReceived = NotificationBuilder.buildNotificationActionFromNotificationModel(context, notificationModel, intent);
        NotificationBuilder.finalizeNotificationIntent(context, notificationModel, intent);

        if (notificationModel != null) {
            try {

                NotificationGateKeeper.SendBroadcastKeepOnTopAction(
                        context,
                        actionReceived
                );

            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
}
