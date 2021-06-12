package me.carda.awesome_notifications.notifications.broadcastReceivers;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import io.flutter.Log;

import me.carda.awesome_notifications.AwesomeNotificationsPlugin;
import me.carda.awesome_notifications.BroadcastSender;
import me.carda.awesome_notifications.notifications.NotificationBuilder;
import me.carda.awesome_notifications.notifications.NotificationSender;
import me.carda.awesome_notifications.notifications.models.returnedData.ActionReceived;
import me.carda.awesome_notifications.utils.DateUtils;

public class AutoDismissibleReceiver extends BroadcastReceiver {

    String TAG = "AutoCancelReceiver";

    @Override
    public void onReceive(Context context, Intent intent) {
        ActionReceived actionReceived =
                NotificationBuilder.buildNotificationActionFromIntent(context, intent);

        if (actionReceived != null) {
            actionReceived.dismissedLifeCycle = AwesomeNotificationsPlugin.getApplicationLifeCycle();
            actionReceived.dismissedDate = DateUtils.getUTCDate();

            BroadcastSender.SendBroadcastNotificationDismissed(
                    context, actionReceived
            );
        }

        if(AwesomeNotificationsPlugin.debug)
            Log.d(TAG, "Notification dismissed via action button");
    }
}
