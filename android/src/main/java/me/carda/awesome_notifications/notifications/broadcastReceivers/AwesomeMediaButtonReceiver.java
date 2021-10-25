package me.carda.awesome_notifications.notifications.broadcastReceivers;

import android.content.Context;
import android.content.Intent;
import android.util.Log;

import androidx.media.session.MediaButtonReceiver;

public class AwesomeMediaButtonReceiver extends MediaButtonReceiver {

    static String TAG = "AwesomeMediaButtonReceiver";

    @Override
    public void onReceive(Context context, Intent intent) {

        Log.d(TAG, "media button received");
        String action = intent.getAction();

        if (action != null && action.equals(Intent.ACTION_MEDIA_BUTTON)) {
            /*
            Parcelable event = intent.getParcelableExtra(Intent.EXTRA_KEY_EVENT);
            if (event.action == KeyEvent.ACTION_UP || event.action ==
                    KeyEvent.ACTION_DOWN) {
                when (event.keyCode) {
                    // handle cancel button
                    KeyEvent.KEYCODE_MEDIA_STOP -> context.sendIntent(ACTION_FINISH)
                    // handle play button
                    KeyEvent.KEYCODE_MEDIA_PLAY, KeyEvent.KEYCODE_MEDIA_PAUSE -> context.sendIntent(ACTION_PLAY_PAUSE)
                }
            }

            ActionReceived actionReceived = NotificationBuilder.buildNotificationActionFromIntent(context, intent);

            if (actionReceived != null) {

                actionReceived.dismissedLifeCycle = AwesomeNotificationsPlugin.getApplicationLifeCycle();
                actionReceived.dismissedDate = DateUtils.getUTCDate();

                try {

                    BroadcastSender.SendBroadcastMediaButton(
                        context,
                        actionReceived
                    );

                    //Toast.makeText(context, "DismissedNotificationReceiver", Toast.LENGTH_SHORT).show();

                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
            */
        }
    }
}