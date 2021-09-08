package me.carda.awesome_notifications.notifications.managers;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Context;
import android.media.AudioAttributes;
import android.media.RingtoneManager;
import android.net.Uri;
import android.os.Build;

import java.util.List;

import androidx.core.app.NotificationManagerCompat;
import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.enumerators.DefaultRingtoneType;
import me.carda.awesome_notifications.notifications.enumerators.MediaSource;
import me.carda.awesome_notifications.notifications.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.notifications.models.NotificationChannelModel;
import me.carda.awesome_notifications.utils.AudioUtils;
import me.carda.awesome_notifications.utils.BitmapUtils;
import me.carda.awesome_notifications.utils.BooleanUtils;
import me.carda.awesome_notifications.utils.MediaUtils;
import me.carda.awesome_notifications.utils.StringUtils;

public class ChannelManager {

    private static final SharedManager<NotificationChannelModel> shared = new SharedManager<>("ChannelManager", NotificationChannelModel.class);

    public static Boolean removeChannel(Context context, String channelKey) {

        NotificationChannelModel oldChannel = getChannelByKey(context, channelKey);

        if(oldChannel == null) return true;

        // Ensures the removal of any possible standard
        removeAndroidChannel(context, oldChannel.channelKey);
        removeAndroidChannel(context, oldChannel.getChannelHashKey(context, false));
        removeAndroidChannel(context, oldChannel.getChannelHashKey(context, true));

        return shared.remove(context, Definitions.SHARED_CHANNELS, channelKey);
    }

    public static List<NotificationChannelModel> listChannels(Context context) {
        return shared.getAllObjects(context, Definitions.SHARED_CHANNELS);
    }

    public static void saveChannel(Context context, NotificationChannelModel channelModel, Boolean forceUpdate) {

        channelModel.refreshIconResource(context);
        NotificationChannelModel oldChannel = getChannelByKey(context, channelModel.channelKey);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if(oldChannel != null){

                NotificationChannel androidChannel = getAndroidChannel(context, channelModel);
                if(androidChannel != null){
                    String oldHashKey = androidChannel.getId();
                    String newHashKey = channelModel.getChannelHashKey(context, false);

                    if(!oldHashKey.equals(newHashKey)){
                        if(forceUpdate) {
                            // Ensures the removal of previous channel to enable force update
                            removeAndroidChannel(context, oldHashKey);
                        }
                    }
                }
            }

            setAndroidChannel(context, channelModel);
        }

        shared.set(context, Definitions.SHARED_CHANNELS, channelModel.channelKey, channelModel);
        shared.commit(context);
    }

    public static NotificationChannelModel getChannelByKey(Context context, String channelKey){

        NotificationChannelModel channelModel = shared.get(context, Definitions.SHARED_CHANNELS, channelKey);
        if(channelModel != null){
            channelModel.refreshIconResource(context);
        }

        return channelModel;
    }

    public static Uri retrieveSoundResourceUri(Context context, DefaultRingtoneType ringtoneType, String soundSource) {
        Uri uri = null;
        if (StringUtils.isNullOrEmpty(soundSource)) {

            int defaultRingtoneKey;
            switch (ringtoneType){

                case Ringtone:
                    defaultRingtoneKey = RingtoneManager.TYPE_RINGTONE;
                    break;

                case Alarm:
                    defaultRingtoneKey = RingtoneManager.TYPE_ALARM;
                    break;

                case Notification:
                default:
                    defaultRingtoneKey = RingtoneManager.TYPE_NOTIFICATION;
                    break;
            }
            uri = RingtoneManager.getDefaultUri(defaultRingtoneKey);

        } else {
            int soundResourceId = AudioUtils.getAudioResourceId(context, soundSource);
            if(soundResourceId > 0){
                uri = Uri.parse("android.resource://" + context.getPackageName() + "/" + soundResourceId);
            }
        }
        return uri;
    }

    public static void commitChanges(Context context){
        shared.commit(context);
    }

    public static NotificationChannel getAndroidChannel(Context context, NotificationChannelModel referenceChannel){

        NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);

        // Returns channel from another packages with same name
        NotificationChannel standardAndroidChannel = notificationManager.getNotificationChannel(referenceChannel.channelKey);
        if(standardAndroidChannel != null){
            return standardAndroidChannel;
        }

        // Returns channel from previous awesome notification
        String oldAwesomeChannelKey = referenceChannel.getChannelHashKey(context, true);
        NotificationChannel oldAwesomeAndroidChannel = notificationManager.getNotificationChannel(oldAwesomeChannelKey);
        if(oldAwesomeAndroidChannel != null){
            return oldAwesomeAndroidChannel;
        }

        // Returns forceUpdate starndard
        String newAwesomeChannelKey = referenceChannel.getChannelHashKey(context, false);
        return notificationManager.getNotificationChannel(newAwesomeChannelKey);
    }

    private static void removeAndroidChannel(Context context, String channelId) {
        NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                notificationManager.deleteNotificationChannel(channelId);
            } catch ( Exception ignored) {
            }
        }
    }

    public static void setAndroidChannel(Context context, NotificationChannelModel newChannel) {

        newChannel.refreshIconResource(context);

        try {
            newChannel.validate(context);
        } catch (AwesomeNotificationException e) {
            e.printStackTrace();
            return;
        }

        // Channels are only available on Android Oreo and beyond.
        // On older versions, channel models are only used to organize notifications
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {

            NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);

            NotificationChannel newNotificationChannel = new NotificationChannel(newChannel.getChannelHashKey(context, false), newChannel.channelName, newChannel.importance.ordinal());
            newNotificationChannel.setDescription(newChannel.channelDescription);

            if (newChannel.playSound) {

                /// TODO NEED TO IMPROVE AUDIO RESOURCES TO BE MORE VERSATILE, SUCH AS BITMAP ONES
                AudioAttributes audioAttributes = null;
                audioAttributes = new AudioAttributes.Builder()
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                        .build();

                Uri uri = retrieveSoundResourceUri(context, newChannel.defaultRingtoneType, newChannel.soundSource);
                newNotificationChannel.setSound(uri, audioAttributes);

            } else {
                newNotificationChannel.setSound(null, null);
            }

            newNotificationChannel.enableVibration(BooleanUtils.getValue(newChannel.enableVibration));
            if (newChannel.vibrationPattern != null && newChannel.vibrationPattern.length > 0) {
                newNotificationChannel.setVibrationPattern(newChannel.vibrationPattern);
            }

            boolean enableLights = BooleanUtils.getValue(newChannel.enableLights);
            newNotificationChannel.enableLights(enableLights);

            if (enableLights && newChannel.ledColor != null) {
                newNotificationChannel.setLightColor(newChannel.ledColor);
            }

            newNotificationChannel.setShowBadge(BooleanUtils.getValue(newChannel.channelShowBadge));

            // Removes the old standard before apply the new one
            String oldAwesomeChannelKey = newChannel.getChannelHashKey(context, true);
            NotificationChannel oldAwesomeAndroidChannel = notificationManager.getNotificationChannel(oldAwesomeChannelKey);
            if(oldAwesomeAndroidChannel != null){
                notificationManager.deleteNotificationChannel(oldAwesomeAndroidChannel.getId());
            }

            notificationManager.createNotificationChannel(newNotificationChannel);
        }

    }

    public static boolean isNotificationChannelActive(Context context, String channelId){
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if(!StringUtils.isNullOrEmpty(channelId)) {
                NotificationManager manager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
                NotificationChannel channel = manager.getNotificationChannel(channelId);
                return channel != null && channel.getImportance() != NotificationManager.IMPORTANCE_NONE;
            }
            return false;
        } else {
            return NotificationManagerCompat.from(context).areNotificationsEnabled();
        }
    }
}
