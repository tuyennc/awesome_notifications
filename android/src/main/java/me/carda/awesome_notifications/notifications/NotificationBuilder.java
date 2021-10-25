package me.carda.awesome_notifications.notifications;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.preference.PreferenceManager;
import android.service.notification.StatusBarNotification;


import java.io.Serializable;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.stream.IntStream;
import java.util.concurrent.ConcurrentHashMap;

import androidx.annotation.NonNull;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;
import androidx.core.app.Person;
import androidx.core.app.RemoteInput;

import androidx.core.graphics.drawable.IconCompat;
import me.carda.awesome_notifications.AwesomeNotificationsPlugin;
import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.broadcastReceivers.DismissedNotificationReceiver;
import me.carda.awesome_notifications.notifications.broadcastReceivers.KeepOnTopActionReceiver;
import me.carda.awesome_notifications.notifications.broadcastReceivers.SilentActionReceiver;
import me.carda.awesome_notifications.notifications.enumerators.GroupSort;
import me.carda.awesome_notifications.notifications.enumerators.NotificationActionType;
import me.carda.awesome_notifications.notifications.enumerators.NotificationLayout;
import me.carda.awesome_notifications.notifications.enumerators.NotificationPrivacy;
import me.carda.awesome_notifications.notifications.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.notifications.managers.ChannelManager;
import me.carda.awesome_notifications.notifications.managers.DefaultsManager;
import me.carda.awesome_notifications.notifications.models.NotificationButtonModel;
import me.carda.awesome_notifications.notifications.models.NotificationChannelModel;
import me.carda.awesome_notifications.notifications.models.NotificationContentModel;
import me.carda.awesome_notifications.notifications.models.NotificationMessageModel;
import me.carda.awesome_notifications.notifications.models.NotificationModel;
import me.carda.awesome_notifications.notifications.models.returnedData.ActionReceived;
import me.carda.awesome_notifications.utils.BitmapUtils;
import me.carda.awesome_notifications.utils.BooleanUtils;
import me.carda.awesome_notifications.utils.DateUtils;
import me.carda.awesome_notifications.utils.HtmlUtils;
import me.carda.awesome_notifications.utils.IntegerUtils;
import me.carda.awesome_notifications.utils.ListUtils;
import me.carda.awesome_notifications.utils.StringUtils;

//badges
import me.leolin.shortcutbadger.ShortcutBadger;

import static me.carda.awesome_notifications.Definitions.NOTIFICATION_BADGE_KEY;

public class NotificationBuilder {

    public static String TAG = "NotificationBuilder";

    public static Notification createNotification(Context context, Intent originalIntent, NotificationModel notificationModel) throws AwesomeNotificationException {
        return createNotification(context, originalIntent, notificationModel, false);
    }

    @SuppressWarnings("unchecked")
    public static Notification createNotification(Context context, Intent originalIntent, NotificationModel notificationModel, boolean isSummary) throws AwesomeNotificationException {

        NotificationChannelModel channelModel = ChannelManager.getChannelByKey(context, notificationModel.content.channelKey);
        if(channelModel == null)
            throw new AwesomeNotificationException("Channel '"+ notificationModel.content.channelKey +"' does not exist or is disabled");

        notificationModel.content.groupKey = getGroupKey(notificationModel.content, channelModel);

        Intent intent = buildNotificationIntentFromModel(
            context,
            Definitions.SELECT_NOTIFICATION,
            originalIntent,
            notificationModel,
            channelModel
        );

        Intent deleteIntent = buildNotificationIntentFromModel(
            context,
            Definitions.DISMISSED_NOTIFICATION,
            null,
            notificationModel,
            channelModel,
            DismissedNotificationReceiver.class
        );

        PendingIntent pendingIntent = notificationModel.content.notificationActionType == NotificationActionType.BringToForeground ?
            PendingIntent.getActivity(
                context,
                notificationModel.content.id,
                intent,
                Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M /*Android 6*/ ?
                    PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT :
                    PendingIntent.FLAG_UPDATE_CURRENT
            ) :
            PendingIntent.getBroadcast(
                context,
                notificationModel.content.id,
                intent,
                Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M /*Android 6*/ ?
                    PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT :
                    PendingIntent.FLAG_UPDATE_CURRENT
            );

        PendingIntent pendingDeleteIntent = PendingIntent.getBroadcast(
            context,
            notificationModel.content.id,
            deleteIntent,
            Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M /*Android 6*/ ?
                PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT :
                PendingIntent.FLAG_UPDATE_CURRENT
        );

        Notification finalNotification = getNotificationBuilderFromModel(context, originalIntent, notificationModel, pendingIntent, pendingDeleteIntent, isSummary);

        finalNotification.extras.putInt(
                Definitions.NOTIFICATION_ID,
                notificationModel.content.id);

        finalNotification.extras.putString(
                Definitions.NOTIFICATION_CHANNEL_KEY,
                StringUtils.digestString(notificationModel.content.channelKey));

        finalNotification.extras.putString(
                Definitions.NOTIFICATION_LAYOUT,
                StringUtils.digestString(notificationModel.content.notificationLayout.toString()));

        if(!ListUtils.isNullOrEmpty(notificationModel.content.messages)) {
            Map<String, Object> contentData = notificationModel.content.toMap();
            List<Map> contentMessageData = (List<Map>) contentData.get(Definitions.NOTIFICATION_MESSAGES);
            finalNotification.extras.putSerializable(
                    Definitions.NOTIFICATION_MESSAGES,
                    (Serializable) contentMessageData);
        }

        return finalNotification;
    }

    private static Class<?> getTargetClass(Context context, NotificationActionType actionType){

        switch (actionType){

            case BringToForeground:
                return getNotificationTargetActivityClass(context);

            case KeepOnTopAction:
                return KeepOnTopActionReceiver.class;

            default:
                return SilentActionReceiver.class;
        }
    }

    public static Intent buildNotificationIntentFromModel(
        Context context,
        String actionReference,
        Intent originalIntent,
        NotificationModel notificationModel,
        NotificationChannelModel channel
    ){
        return buildNotificationIntentFromModel(
            context, actionReference,
            originalIntent,
            notificationModel,
            channel,
            notificationModel.content.notificationActionType);
    }

    public static Intent buildNotificationIntentFromModel(
            Context context,
            String actionReference,
            Intent originalIntent,
            NotificationModel notificationModel,
            NotificationChannelModel channel,
            Class<?> targetClass
    ){
        return buildNotificationIntentFromModel(
                context,
                actionReference,
                originalIntent,
                notificationModel,
                channel,
                notificationModel.content.notificationActionType, targetClass);
    }

    public static Intent buildNotificationIntentFromModel(
            Context context,
            String actionReference,
            Intent originalIntent,
            NotificationModel notificationModel,
            NotificationChannelModel channel,
            NotificationActionType actionType
    ){
        Class<?> targetClass = getTargetClass(context, actionType);
        return buildNotificationIntentFromModel(
                context,
                actionReference,
                originalIntent,
                notificationModel,
                channel,
                actionType,
                targetClass);
    }

    public static Intent buildNotificationIntentFromModel(
        Context context,
        String actionReference,
        Intent originalIntent,
        NotificationModel notificationModel,
        NotificationChannelModel channel,
        NotificationActionType actionType,
        Class<?> targetClass
    ){
        Intent intent = targetClass == null ? new Intent() : new Intent(context, targetClass);

        // Preserves analytics extras
        if(originalIntent != null)
            intent.putExtras(originalIntent.getExtras());

        intent.setAction(actionReference);

        Bundle extras = intent.getExtras();
        if(extras == null)
            extras = new Bundle();

        String jsonData = notificationModel.toJson();
        extras.putString(Definitions.NOTIFICATION_JSON, jsonData);

        updateTrackingExtras(notificationModel, channel, actionType, extras);
        intent.putExtras(extras);

        return intent;
    }

    private static void updateTrackingExtras(NotificationModel notificationModel, NotificationChannelModel channel, NotificationActionType actionType, Bundle extras) {
        String groupKey = getGroupKey(notificationModel.content, channel);

        extras.putInt(Definitions.NOTIFICATION_ID, notificationModel.content.id);
        extras.putString(Definitions.NOTIFICATION_CHANNEL_KEY, StringUtils.digestString(notificationModel.content.channelKey));
        extras.putString(Definitions.NOTIFICATION_GROUP_KEY, StringUtils.digestString(groupKey));
        extras.putBoolean(Definitions.NOTIFICATION_AUTO_DISMISSIBLE, notificationModel.content.autoDismissible);
        extras.putString(Definitions.NOTIFICATION_ACTION_TYPE, actionType.toString());
    }

    public static NotificationModel buildNotificationModelFromIntent(Intent intent){

        String actionKey = intent.getAction();

        if(actionKey == null) return null;

        boolean isNormalAction = Definitions.SELECT_NOTIFICATION.equals(actionKey) || Definitions.DISMISSED_NOTIFICATION.equals(actionKey);
        boolean isButtonAction = actionKey.startsWith(Definitions.NOTIFICATION_BUTTON_ACTION_PREFIX);

        if (isNormalAction || isButtonAction) {
            String notificationJson = intent.getStringExtra(Definitions.NOTIFICATION_JSON);

            if(intent.getBooleanExtra(Definitions.NOTIFICATION_REQUIRE_INPUT_TEXT, false)){
                String actionInput = getButtonInputText(intent, intent.getStringExtra(Definitions.NOTIFICATION_BUTTON_KEY));
                if(StringUtils.isNullOrEmpty(actionInput))
                    actionInput = intent.getStringExtra(Definitions.NOTIFICATION_INPUT_TEXT);
                intent.putExtra(Definitions.NOTIFICATION_INPUT_TEXT, actionInput);
            }

            return new NotificationModel().fromJson(notificationJson);
        }
        return null;
    }

    public static ActionReceived buildNotificationActionFromNotificationModel(Context context, NotificationModel notificationModel, Intent intent){
        if(notificationModel == null) return null;

        String actionKey = intent.getAction();
        if(actionKey == null) return null;

        boolean isNormalAction = Definitions.SELECT_NOTIFICATION.equals(actionKey) || Definitions.DISMISSED_NOTIFICATION.equals(actionKey);
        boolean isButtonAction = actionKey.startsWith(Definitions.NOTIFICATION_BUTTON_ACTION_PREFIX);

        if (isNormalAction || isButtonAction){

            ActionReceived actionModel = new ActionReceived(notificationModel.content);
            actionModel.setActualActionAttributes();

            String notificationActionTypeText = intent.getStringExtra(Definitions.NOTIFICATION_ACTION_TYPE);
            actionModel.notificationActionType =
                    notificationActionTypeText == null ? NotificationActionType.BringToForeground :
                            NotificationActionType.valueOf(notificationActionTypeText);

            if (isButtonAction){
                actionModel.actionKey = intent.getStringExtra(Definitions.NOTIFICATION_BUTTON_KEY);

                if(intent.getBooleanExtra(Definitions.NOTIFICATION_REQUIRE_INPUT_TEXT, false)){
                    actionModel.actionInput = getButtonInputText(intent, intent.getStringExtra(Definitions.NOTIFICATION_BUTTON_KEY));
                    if(StringUtils.isNullOrEmpty(actionModel.actionInput))
                        actionModel.actionInput = intent.getStringExtra(Definitions.NOTIFICATION_INPUT_TEXT);
                    intent.putExtra(Definitions.NOTIFICATION_INPUT_TEXT, actionModel.actionInput);

                    if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.P /*Android 9*/) {
                        try {
                            notificationModel.remoteHistory = actionModel.actionInput;
                            notificationModel.content.isRefreshNotification = true;
                            NotificationSender.send(context, notificationModel);
                        } catch (Exception e) {
                            e.printStackTrace();
                        }
                    }
                }
            }

            if(StringUtils.isNullOrEmpty(actionModel.displayedDate)){
                actionModel.displayedDate = DateUtils.getUTCDate();
            }

            return actionModel;
        }
        return null;
    }

    public static void finalizeNotificationIntent(Context context, NotificationModel notificationModel, Intent intent){

        int notificationId = intent.getIntExtra(Definitions.NOTIFICATION_ID, -1);

        boolean shouldDismiss = intent.getBooleanExtra(Definitions.NOTIFICATION_AUTO_DISMISSIBLE, notificationId >= 0);

        if (shouldDismiss){

            // "IT WORKS" to cancel notification remote inputs since Android 9, but is not the correct way to do
            // https://stackoverflow.com/questions/54219914/cancel-notification-with-remoteinput-not-working/56867575#56867575
            if(Build.VERSION.SDK_INT < Build.VERSION_CODES.P || !intent.getBooleanExtra(Definitions.NOTIFICATION_REQUIRE_INPUT_TEXT, false)) {

//                    notificationId = notificationModel.content.id;
//                    NotificationSender.send(context, notificationModel);
//
//                    int finalNotificationId = notificationId;
//                    new Handler(Looper.getMainLooper()).postDelayed(new Runnable() {
//                        @Override
//                        public void run() {
//                            NotificationSender.dismissNotification(context, finalNotificationId);
//                        }
//                    }, 300);

                NotificationSender.dismissNotification(context, notificationId);
            }
        }
    }

    public static Notification getAndroidNotificationById(Context context, int id){
        if(context != null && android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M){

            NotificationManager manager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
            StatusBarNotification[] currentActiveNotifications = manager.getActiveNotifications();

            if(currentActiveNotifications != null){
                for (StatusBarNotification activeNotification : currentActiveNotifications) {
                    if(activeNotification.getId() == id){
                        return activeNotification.getNotification();
                    }
                }
            }
        }
        return null;
    }

    public static List<Notification> getAllAndroidActiveNotificationsByChannelKey(Context context, String channelKey){
        List<Notification> notifications = new ArrayList<>();
        if(context != null && !StringUtils.isNullOrEmpty(channelKey) && android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M){

            NotificationManager manager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
            StatusBarNotification[] currentActiveNotifications = manager.getActiveNotifications();

            String hashedKey = StringUtils.digestString(channelKey);

            if(currentActiveNotifications != null){
                for (StatusBarNotification activeNotification : currentActiveNotifications) {

                    Notification notification = activeNotification.getNotification();

                    String notificationChannelKey = notification.extras
                            .getString(Definitions.NOTIFICATION_CHANNEL_KEY);

                    if(notificationChannelKey != null && notificationChannelKey.equals(hashedKey)){
                        notifications.add(notification);
                    }
                }
            }
        }
        return notifications;
    }

    public static List<Notification> getAllAndroidActiveNotificationsByGroupKey(Context context, String groupKey){
        List<Notification> notifications = new ArrayList<>();
        if(context != null && !StringUtils.isNullOrEmpty(groupKey) && android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M){

            NotificationManager manager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
            StatusBarNotification[] currentActiveNotifications = manager.getActiveNotifications();

            String hashedKey = StringUtils.digestString(groupKey);

            if(currentActiveNotifications != null){
                for (StatusBarNotification activeNotification : currentActiveNotifications) {

                    Notification notification = activeNotification.getNotification();

                    String notificationGroupKey = notification.extras
                            .getString(Definitions.NOTIFICATION_GROUP_KEY);

                    if(notificationGroupKey != null && notificationGroupKey.equals(hashedKey)){
                        notifications.add(notification);
                    }
                }
            }
        }
        return notifications;
    }

    private static String getButtonInputText(Intent intent, String buttonKey) {
        Bundle remoteInput = RemoteInput.getResultsFromIntent(intent);
        if (remoteInput != null) {
            return remoteInput.getCharSequence(buttonKey).toString();
        }
        return null;
    }

    private static Notification getNotificationBuilderFromModel(Context context, Intent originalIntent, NotificationModel notificationModel, PendingIntent pendingIntent, PendingIntent deleteIntent, boolean isSummary) throws AwesomeNotificationException {

        NotificationChannelModel channel = ChannelManager.getChannelByKey(context, notificationModel.content.channelKey);

        if(channel == null) throw new AwesomeNotificationException("Channel '"+ notificationModel.content.channelKey+"' does not exist or is disabled");

        NotificationCompat.Builder builder = new NotificationCompat.Builder(context, notificationModel.content.channelKey);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O /*Android 8*/){
            NotificationChannel androidChannel = ChannelManager.getAndroidChannel(context, channel);
            if(androidChannel == null){
                throw new AwesomeNotificationException("The notification channel '"+channel.channelKey+"' does not exist or is disabled");
            }
            builder.setChannelId(androidChannel.getId());
        }

        setSmallIcon(context, notificationModel, channel, builder);

        // Crashing on Android 11+
        //setRemoteHistory(notificationModel, builder);

        setGrouping(context, notificationModel, channel, builder);

        setVisibility(context, notificationModel, channel, builder);
        setShowWhen(notificationModel, builder);

        setLayout(context, notificationModel, channel, builder);

        createActionButtons(context, originalIntent, notificationModel, channel, builder);

        setTitle(notificationModel, channel, builder);
        setBody(notificationModel, builder);

        setAutoDismissible(notificationModel, builder);
        setTicker(notificationModel, builder);
        setOnlyAlertOnce(notificationModel, channel, builder);

        setLockedNotification(notificationModel, channel, builder);
        setImportance(channel, builder);

        setSound(context, notificationModel, channel, builder);
        setVibrationPattern(channel, builder);
        setLights(channel, builder);

        setLargeIcon(context, notificationModel, builder);
        setLayoutColor(context, notificationModel, channel, builder);

        if(!isSummary)
            setBadge(context, channel, builder);

        builder.setContentIntent(pendingIntent);
        if(!isSummary){
            builder.setDeleteIntent(deleteIntent);
        }

        Notification androidNotification = builder.build();
        if(androidNotification.extras == null)
            androidNotification.extras = new Bundle();
        updateTrackingExtras(notificationModel, channel, notificationModel.content.notificationActionType, androidNotification.extras);

        return androidNotification;
    }

    private static void setShowWhen(NotificationModel notificationModel, NotificationCompat.Builder builder) {
        builder.setShowWhen(BooleanUtils.getValueOrDefault(notificationModel.content.showWhen, true));
    }

    private static Integer getBackgroundColor(NotificationModel notificationModel, NotificationChannelModel channel, NotificationCompat.Builder builder){
        Integer bgColorValue;
        bgColorValue = IntegerUtils.extractInteger(notificationModel.content.backgroundColor, null);
        if(bgColorValue != null){
            builder.setColorized(true);
        }
        else {
            bgColorValue = getLayoutColor(notificationModel, channel);
        }
        return bgColorValue;
    }

    private static Integer getLayoutColor(NotificationModel notificationModel, NotificationChannelModel channel){
        Integer layoutColorValue;
        layoutColorValue = IntegerUtils.extractInteger(notificationModel.content.color, channel.defaultColor);
        layoutColorValue = IntegerUtils.extractInteger(layoutColorValue, Color.BLACK);
        return layoutColorValue;
    }

    private static void setImportance(NotificationChannelModel channel, NotificationCompat.Builder builder) {
        // Conversion to Priority
        int priorityValue = Math.min(Math.max(IntegerUtils.extractInteger(channel.importance) -2,-2),2);
        builder.setPriority(priorityValue);
    }

    private static void setOnlyAlertOnce(NotificationModel notificationModel, NotificationChannelModel channel, NotificationCompat.Builder builder) {
        boolean onlyAlertOnceValue = BooleanUtils.getValue(notificationModel.content.notificationLayout == NotificationLayout.ProgressBar || channel.onlyAlertOnce);
        builder.setOnlyAlertOnce(onlyAlertOnceValue);
    }

    private static void setRemoteHistory(NotificationModel notificationModel, NotificationCompat.Builder builder) {
        if(!StringUtils.isNullOrEmpty(notificationModel.remoteHistory)) {
            builder.setRemoteInputHistory(new CharSequence[]{notificationModel.remoteHistory});
        }
    }

    private static void setLockedNotification(NotificationModel notificationModel, NotificationChannelModel channel, NotificationCompat.Builder builder) {
        boolean contentLocked = BooleanUtils.getValue(notificationModel.content.locked);
        boolean channelLocked = BooleanUtils.getValue(channel.locked);

        if(contentLocked){
            builder.setOngoing(true);
        }
        else if(channelLocked){
            boolean lockedValue = BooleanUtils.getValueOrDefault(notificationModel.content.locked, true);
            builder.setOngoing(lockedValue);
        }
    }

    private static void setTicker(NotificationModel notificationModel, NotificationCompat.Builder builder) {
        String tickerValue;
        tickerValue = StringUtils.getValueOrDefault(notificationModel.content.ticker, null);
        tickerValue = StringUtils.getValueOrDefault(tickerValue, notificationModel.content.summary);
        tickerValue = StringUtils.getValueOrDefault(tickerValue, notificationModel.content.body);
        builder.setTicker(tickerValue);
    }

    private static void setBadge(Context context, NotificationChannelModel channelModel, NotificationCompat.Builder builder){
        if(BooleanUtils.getValue(channelModel.channelShowBadge)){
            incrementGlobalBadgeCounter(context);
            builder.setNumber(1);
        }
    }

    private static void setAutoDismissible(NotificationModel notificationModel, NotificationCompat.Builder builder) {
        builder.setAutoCancel(BooleanUtils.getValueOrDefault(notificationModel.content.autoDismissible, true));
    }

    private static void setBody(NotificationModel notificationModel, NotificationCompat.Builder builder) {
        builder.setContentText(HtmlUtils.fromHtml(notificationModel.content.body));
    }

    private static void setTitle(NotificationModel notificationModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {
        if(notificationModel.content.title != null){
            builder.setContentTitle(HtmlUtils.fromHtml(notificationModel.content.title));
        }
    }

    private static void setVibrationPattern(NotificationChannelModel channelModel, NotificationCompat.Builder builder) {
        if (BooleanUtils.getValue(channelModel.enableVibration)) {
            if (channelModel.vibrationPattern != null && channelModel.vibrationPattern.length > 0) {
                builder.setVibrate(channelModel.vibrationPattern);
            }
        } else {
            builder.setVibrate(new long[]{0});
        }
    }

    private static void setLights(NotificationChannelModel channelModel, NotificationCompat.Builder builder) {
        if (BooleanUtils.getValue(channelModel.enableLights)) {
            Integer ledColorValue = IntegerUtils.extractInteger(channelModel.ledColor, Color.WHITE);
            Integer ledOnMsValue = IntegerUtils.extractInteger(channelModel.ledOnMs, 300);
            Integer ledOffMsValue = IntegerUtils.extractInteger(channelModel.ledOffMs, 700);
            builder.setLights(ledColorValue, ledOnMsValue, ledOffMsValue);
        }
    }

    private static void setVisibility(Context context, NotificationModel notificationModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {
        Integer visibilityIndex;
        visibilityIndex = IntegerUtils.extractInteger(notificationModel.content.privacy, channelModel.defaultPrivacy.ordinal());
        visibilityIndex = IntegerUtils.extractInteger(visibilityIndex, NotificationPrivacy.Public);

        builder.setVisibility(visibilityIndex - 1);
    }

    private static void setLayoutColor(Context context, NotificationModel notificationModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {

        if(notificationModel.content.backgroundColor == null){
            builder.setColor(getLayoutColor(notificationModel, channelModel));
        } else {
            builder.setColor(getBackgroundColor(notificationModel, channelModel, builder));
        }
    }

    private static void setLargeIcon(Context context, NotificationModel notificationModel, NotificationCompat.Builder builder) {
        if (!StringUtils.isNullOrEmpty(notificationModel.content.largeIcon)) {
            Bitmap largeIcon = BitmapUtils.getBitmapFromSource(context, notificationModel.content.largeIcon);
            if(largeIcon != null){
                builder.setLargeIcon(largeIcon);
            }
        }
    }

    public static int getGlobalBadgeCounter(Context context){
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(context);

        // Read previous value. If not found, use 0 as default value.
        return prefs.getInt(Definitions.BADGE_COUNT, 0);
    }

    public static void setGlobalBadgeCounter(Context context, int count){
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(context);
        SharedPreferences.Editor editor = prefs.edit();

        editor.putInt(Definitions.BADGE_COUNT, count);
        ShortcutBadger.applyCount(context, count);

        editor.apply();
    }

    public static void resetGlobalBadgeCounter(Context context){
        setGlobalBadgeCounter(context, 0 );
    }

    public static int incrementGlobalBadgeCounter(Context context) {

        int totalAmount = getGlobalBadgeCounter(context);
        setGlobalBadgeCounter(context, ++totalAmount);
        return totalAmount;
    }

    public static int decrementGlobalBadgeCounter(Context context) {

        int totalAmount = Math.max(getGlobalBadgeCounter(context)-1, 0);
        setGlobalBadgeCounter(context, totalAmount);
        return totalAmount;
    }

    // https://github.com/rafaelsetragni/awesome_notifications/issues/191
    public static Class getNotificationTargetActivityClass(Context context) {

        String packageName = context.getPackageName();
        Intent launchIntent = context.getPackageManager().getLaunchIntentForPackage(packageName);
        String className =
                launchIntent == null ?
                        AwesomeNotificationsPlugin.getMainTargetClassName() :
                        launchIntent.getComponent().getClassName();
        try {
            return Class.forName(className);
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
            return null;
        }
    }

    public static boolean notificationIntentDisabledAction(Intent intent){
        String actionType = intent.getStringExtra(Definitions.NOTIFICATION_ACTION_TYPE);
        return actionType != null && actionType.equals(NotificationActionType.DisabledAction.toString());
    }

    @NonNull
    public static void createActionButtons(Context context, Intent originalIntent, NotificationModel notificationModel, NotificationChannelModel channel, NotificationCompat.Builder builder) {

        if(ListUtils.isNullOrEmpty(notificationModel.actionButtons)) return;

        for(NotificationButtonModel buttonProperties : notificationModel.actionButtons) {

            Intent actionIntent = buildNotificationIntentFromModel(
                context,
                Definitions.NOTIFICATION_BUTTON_ACTION_PREFIX + "_" + buttonProperties.key,
                originalIntent,
                notificationModel,
                channel,
                buttonProperties.notificationActionType
            );

            actionIntent.putExtra(Definitions.NOTIFICATION_BUTTON_KEY, buttonProperties.key);
            actionIntent.putExtra(Definitions.NOTIFICATION_SHOW_IN_COMPACT_VIEW, buttonProperties.showInCompactView);
            actionIntent.putExtra(Definitions.NOTIFICATION_ENABLED, buttonProperties.enabled);
            actionIntent.putExtra(Definitions.NOTIFICATION_AUTO_DISMISSIBLE, buttonProperties.autoDismissible);
            actionIntent.putExtra(Definitions.NOTIFICATION_ACTION_TYPE, buttonProperties.notificationActionType.toString());
            actionIntent.putExtra(Definitions.NOTIFICATION_REQUIRE_INPUT_TEXT, buttonProperties.requireInputText);

            PendingIntent actionPendingIntent = null;

            if(buttonProperties.enabled){

                if(buttonProperties.notificationActionType == NotificationActionType.BringToForeground) {

                    actionPendingIntent = PendingIntent.getActivity(
                            context,
                            notificationModel.content.id,
                            actionIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT
                    );

                }
                else {

                    if(android.os.Build.VERSION.SDK_INT < Build.VERSION_CODES.N){
                        actionIntent.setAction(Intent.ACTION_MAIN);
                        actionIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                    }

                    actionPendingIntent = PendingIntent.getBroadcast(
                            context,
                            notificationModel.content.id,
                            actionIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT
                    );
                }
            }

            int iconResource = 0;
            if(!StringUtils.isNullOrEmpty(buttonProperties.icon)){
                iconResource = BitmapUtils.getDrawableResourceId(context, buttonProperties.icon);
            }

            if(buttonProperties.requireInputText) {

                RemoteInput remoteInput = new RemoteInput.Builder(buttonProperties.key)
                        .setLabel(buttonProperties.label)
                        .build();

                NotificationCompat.Action replyAction = new NotificationCompat.Action.Builder(
                        iconResource, buttonProperties.label, actionPendingIntent)
                        .addRemoteInput(remoteInput)
                        .setAllowGeneratedReplies(true)
                        .build();

                builder.addAction( replyAction );

            } else {

                builder.addAction(iconResource, buttonProperties.label, actionPendingIntent);
            }
        }
    }

    private static void setSound(Context context, NotificationModel notificationModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {

        Uri uri = null;

        if (!notificationModel.content.isRefreshNotification && BooleanUtils.getValue(channelModel.playSound)) {
            uri = ChannelManager.retrieveSoundResourceUri(context, channelModel.defaultRingtoneType, channelModel.soundSource);
        }

        builder.setSound(uri);
    }

    private static void setSmallIcon(Context context, NotificationModel notificationModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {
        if (!StringUtils.isNullOrEmpty(notificationModel.content.icon)) {
            builder.setSmallIcon(BitmapUtils.getDrawableResourceId(context, notificationModel.content.icon));
        } else if (!StringUtils.isNullOrEmpty(channelModel.icon)) {
            builder.setSmallIcon(BitmapUtils.getDrawableResourceId(context, channelModel.icon));
        } else {
            String defaultIcon = DefaultsManager.getDefaultIconByKey(context);

            if (StringUtils.isNullOrEmpty(defaultIcon)) {

                // for backwards compatibility: this is for handling the old way references to the icon used to be kept but should be removed in future
                if (channelModel.iconResourceId != null) {
                    builder.setSmallIcon(channelModel.iconResourceId);
                } else {
                    int defaultResource = context.getResources().getIdentifier(
                            "ic_launcher",
                            "mipmap",
                            context.getPackageName()
                    );

                    if(defaultResource > 0){
                        builder.setSmallIcon(defaultResource);
                    }
                }
            } else {
                int resourceIndex = BitmapUtils.getDrawableResourceId(context, defaultIcon);
                if(resourceIndex > 0){
                    builder.setSmallIcon(resourceIndex);
                }
            }
        }
    }

    private static void setGrouping(Context context, NotificationModel notificationModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {

        if(android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M){
            if( // Grouping key is reserved to arrange messaging and messaging group layouts
                notificationModel.content.notificationLayout == NotificationLayout.Messaging ||
                notificationModel.content.notificationLayout == NotificationLayout.MessagingGroup
            ){
                return;
            }
        }

        String groupKey = getGroupKey(notificationModel.content, channelModel);

        if (!StringUtils.isNullOrEmpty(groupKey)) {
            builder.setGroup(groupKey);

            if(notificationModel.groupSummary) {
                builder.setGroupSummary(true);
            }
            else {
                boolean grouped = true;
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {

                    NotificationManager manager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
                    StatusBarNotification[] currentActiveNotifications = manager.getActiveNotifications();

                    for (StatusBarNotification activeNotification : currentActiveNotifications) {
                        if (activeNotification.getGroupKey().contains("g:"+groupKey)) {
                            grouped = false;
                            break;
                        }
                    }
                }

                if (grouped) {
                    notificationModel.groupSummary = true;
                }
            }

            String idText = notificationModel.content.id.toString();
            String sortKey = Long.toString(
                (channelModel.groupSort == GroupSort.Asc ? System.currentTimeMillis() : Long.MAX_VALUE - System.currentTimeMillis())
            );

            builder.setSortKey(sortKey + idText);

            builder.setGroupAlertBehavior(channelModel.groupAlertBehavior.ordinal());
        }
        else {
            // Prevent Android auto channel grouping for 4+ ungroupded notifications
            builder.setGroup(notificationModel.content.id.toString());
        }
    }

    private static void setLayout(Context context, NotificationModel notificationModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) throws AwesomeNotificationException {

        switch (notificationModel.content.notificationLayout) {

            case BigPicture:
                if(setBigPictureLayout(context, notificationModel.content, builder)) return;
                break;

            case BigText:
                if(setBigTextStyle(context, notificationModel.content, builder)) return;
                break;

            case Inbox:
                if(setInboxLayout(context, notificationModel.content, builder)) return;
                break;

            case Messaging:
                if(setMessagingLayout(context, false, notificationModel.content, channelModel, builder)) return;
                break;

            case MessagingGroup:
                if(setMessagingLayout(context, true, notificationModel.content, channelModel, builder)) return;
                break;

            case MediaPlayer:
                if(setMediaPlayerLayout(context, notificationModel.content, notificationModel.actionButtons, builder)) return;
                break;

            case ProgressBar:
                setProgressLayout(notificationModel.content, builder);
                break;

            case Default:
                setDefaultLayout(notificationModel.content, builder);
            default:
                break;
        }
    }

    private static Boolean setDefaultLayout(NotificationContentModel contentModel, NotificationCompat.Builder builder){
        if(!StringUtils.isNullOrEmpty(contentModel.summary)){
            CharSequence defaultSumary = HtmlUtils.fromHtml(contentModel.summary);
            builder.setSubText(defaultSumary);
        }
        return true;
    }

    private static Boolean setBigPictureLayout(Context context, NotificationContentModel contentModel, NotificationCompat.Builder builder) {

        Bitmap bigPicture = null, largeIcon = null;

        if (!StringUtils.isNullOrEmpty(contentModel.largeIcon)) {
            largeIcon = BitmapUtils.getBitmapFromSource(context, contentModel.largeIcon);
        }

        if (!StringUtils.isNullOrEmpty(contentModel.bigPicture)) {
            bigPicture = BitmapUtils.getBitmapFromSource(context, contentModel.bigPicture);
        }

        if(bigPicture == null) {
            return false;
        }

        NotificationCompat.BigPictureStyle bigPictureStyle = new NotificationCompat.BigPictureStyle();

        bigPictureStyle.bigPicture(bigPicture);
        bigPictureStyle.bigLargeIcon(contentModel.hideLargeIconOnExpand ? null : largeIcon);

        if (!StringUtils.isNullOrEmpty(contentModel.title)) {
            CharSequence contentTitle = HtmlUtils.fromHtml(contentModel.title);
            bigPictureStyle.setBigContentTitle(contentTitle);
        }

        if (!StringUtils.isNullOrEmpty(contentModel.body)) {
            CharSequence summaryText = HtmlUtils.fromHtml(contentModel.body);
            bigPictureStyle.setSummaryText(summaryText);
        }

        builder.setStyle(bigPictureStyle);

        return true;
    }

    private static Boolean setBigTextStyle(Context context, NotificationContentModel contentModel, NotificationCompat.Builder builder) {

        NotificationCompat.BigTextStyle bigTextStyle = new NotificationCompat.BigTextStyle();

        if (StringUtils.isNullOrEmpty(contentModel.body)) return false;

        CharSequence bigBody = HtmlUtils.fromHtml(contentModel.body);
        bigTextStyle.bigText(bigBody);

        if (!StringUtils.isNullOrEmpty(contentModel.summary)) {
            CharSequence bigSummary = HtmlUtils.fromHtml(contentModel.summary);
            bigTextStyle.setSummaryText(bigSummary);
        }

        if (!StringUtils.isNullOrEmpty(contentModel.title)) {
            CharSequence bigTitle = HtmlUtils.fromHtml(contentModel.title);
            bigTextStyle.setBigContentTitle(bigTitle);
        }

        builder.setStyle(bigTextStyle);

        return true;
    }

    private static Boolean setInboxLayout(Context context, NotificationContentModel contentModel, NotificationCompat.Builder builder) {

        // TODO THIS LAYOUT NEEDS TO BE IMPROVED

        NotificationCompat.InboxStyle inboxStyle = new NotificationCompat.InboxStyle();

        if (StringUtils.isNullOrEmpty(contentModel.body)) return false;

        List<String> lines = new ArrayList<>(Arrays.asList(contentModel.body.split("\\r?\\n")));

        if(ListUtils.isNullOrEmpty(lines)) return false;

        CharSequence summary;
        if (StringUtils.isNullOrEmpty(contentModel.summary)) {
            summary = "+ "+lines.size()+" more";
        }
        else {
            summary = HtmlUtils.fromHtml(contentModel.body);
        }
        inboxStyle.setSummaryText(summary);

        if (!StringUtils.isNullOrEmpty(contentModel.title)) {
            CharSequence contentTitle = HtmlUtils.fromHtml(contentModel.title);
            inboxStyle.setBigContentTitle(contentTitle);
        }

        if (contentModel.summary != null) {
            CharSequence summaryText = HtmlUtils.fromHtml(contentModel.summary);
            inboxStyle.setSummaryText(summaryText);
        }

        for (String line : lines) {
            inboxStyle.addLine(HtmlUtils.fromHtml(line));
        }

        builder.setStyle(inboxStyle);
        return true;
    }

    private static Thread builderLockControl;
    public static boolean builderIsLocked(){
        return builderLockControl != null;
    }
    public static void builderUnlockWait(){
        builderLockControl = null;
    }
    public static boolean builderLockWait(){
        Thread currentThread = Thread.currentThread();

        int retries = 50;
        do {
            retries--;

            if(builderLockControl == null){
                builderLockControl = currentThread;
            } else {
                try {
                    Thread.sleep(250);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        } while (retries > 0 || builderLockControl != currentThread);

        return retries > 0;
    }

    public static String getGroupKey(NotificationContentModel contentModel, NotificationChannelModel channelModel){
        return !StringUtils.isNullOrEmpty(contentModel.groupKey) ?
                contentModel.groupKey : channelModel.groupKey;
    }

    private static final ConcurrentHashMap<String, NotificationContentModel> messagingQueue = new ConcurrentHashMap<String, NotificationContentModel>();

    @SuppressWarnings("unchecked")
    private static Boolean setMessagingLayout(Context context, boolean isGrouping, NotificationContentModel contentModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) throws AwesomeNotificationException {
        String groupKey = getGroupKey(contentModel, channelModel);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N /*Android 7*/) {

            Notification currentNotification = null;
            if(!contentModel.isRefreshNotification){
                String messageQueueKey = groupKey + (isGrouping ? ".Gr" : "");

                List<Notification> notifications = getAllAndroidActiveNotificationsByGroupKey(context, groupKey);

                int messagingNotificationId = -1;
                String digestedGroupKey = StringUtils.digestString(groupKey);
                String digestedLayout = StringUtils.digestString(NotificationLayout.Messaging.toString());

                for (Notification notification : notifications) {
                    String layout = notification.extras.getString(Definitions.NOTIFICATION_LAYOUT);
                    if(digestedLayout.equals(layout)){
                        String extraGroupKey = notification.extras.getString(Definitions.NOTIFICATION_GROUP_KEY);
                        if(digestedGroupKey.equals(extraGroupKey)){
                            currentNotification = notification;
                            messagingNotificationId = notification.extras.getInt(
                                    Definitions.NOTIFICATION_ID);
                            break;
                        }
                    }
                }

                if(messagingNotificationId < 0){
                    messagingQueue.remove(messageQueueKey);
                }
                // For terminated app cases
                else if(!messagingQueue.containsKey(messageQueueKey) && currentNotification != null){
                    Serializable messagesData = currentNotification.extras.getSerializable(
                            Definitions.NOTIFICATION_MESSAGES);
                    if(messagesData != null ){
                        contentModel.messages = NotificationContentModel.mapToMessages((List<Map>) messagesData);
                    } else {
                        contentModel.messages = new ArrayList<>();
                    }
                    contentModel.id = currentNotification.extras.getInt(
                            Definitions.NOTIFICATION_ID);
                    messagingQueue.put(messageQueueKey, contentModel);
                }

                NotificationMessageModel currentMessage = new NotificationMessageModel(
                    contentModel.title,
                    contentModel.body,
                    contentModel.largeIcon
                );

                if(messagingQueue.containsKey(messageQueueKey)){
                    NotificationContentModel firstModel = messagingQueue.get(messageQueueKey);

                    contentModel.id = firstModel.id;
                    contentModel.messages = firstModel.messages;
                }

                if(contentModel.messages == null){
                    contentModel.messages = new ArrayList<>();
                }

                contentModel.messages.add(currentMessage);
                messagingQueue.put(messageQueueKey, contentModel);
            }

            NotificationCompat.MessagingStyle messagingStyle =
                new NotificationCompat.MessagingStyle(contentModel.summary);

            for(NotificationMessageModel message : contentModel.messages) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P /*Android 9*/) {

                    Person.Builder personBuilder =  new Person.Builder()
                            .setName(message.title);

                    if(!StringUtils.isNullOrEmpty(contentModel.largeIcon)){
                        Bitmap largeIcon = BitmapUtils.getBitmapFromSource(
                                context,
                                contentModel.largeIcon);
                        if(largeIcon != null)
                            personBuilder.setIcon(
                                IconCompat.createWithBitmap(largeIcon));
                    }

                    Person person = personBuilder.build();

                    messagingStyle.addMessage(
                            message.message, message.timestamp, person);
                } else {
                    messagingStyle.addMessage(
                            message.message, message.timestamp, message.title);
                }
            }

            if (
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.P /*Android 9*/ &&
                !StringUtils.isNullOrEmpty(contentModel.summary)
            ){
                messagingStyle.setConversationTitle(contentModel.summary);
                messagingStyle.setGroupConversation(isGrouping);
            }

            builder.setStyle((NotificationCompat.Style) messagingStyle);
        }
        else {
            if(StringUtils.isNullOrEmpty(groupKey)){
                builder.setGroup("Messaging."+groupKey);
            }
        }

        return true;
    }

    private static Boolean setMediaPlayerLayout(Context context, NotificationContentModel contentModel, List<NotificationButtonModel> actionButtons, NotificationCompat.Builder builder) {
        
        ArrayList<Integer> indexes = new ArrayList<>();
        for (int i = 0; i < actionButtons.size(); i++) {
            NotificationButtonModel b = actionButtons.get(i);
            if (b.showInCompactView) indexes.add(i);
        }

        int[] showInCompactView = toIntArray(indexes);
        builder.setStyle(
            new androidx.media.app.NotificationCompat.MediaStyle()
                        .setShowActionsInCompactView(showInCompactView)
                .setShowCancelButton(true)
                .setMediaSession(AwesomeNotificationsPlugin.mediaSession.getSessionToken())
        );

        if(!StringUtils.isNullOrEmpty(contentModel.summary)){
            CharSequence playerSumary = HtmlUtils.fromHtml(contentModel.summary);
            builder.setSubText(playerSumary);
        }

        builder.setShowWhen(false);

        return true;
    }

    private static void setProgressLayout(NotificationContentModel contentModel, NotificationCompat.Builder builder) {
        builder.setProgress(
                100,
                Math.max(0, Math.min(100, IntegerUtils.extractInteger(contentModel.progress, 0))),
                contentModel.progress == null
        );

        if(!StringUtils.isNullOrEmpty(contentModel.summary)){
            CharSequence progressSummary = HtmlUtils.fromHtml(contentModel.summary);
            builder.setSubText(progressSummary);
        }
    }

    public static NotificationManagerCompat getAndroidNotificationManager(Context context) {
        return NotificationManagerCompat.from(context);
    }

    private static int[] toIntArray(ArrayList<Integer> list) {
        if (list == null || list.size() <= 0) return new int[0];

        int[] result = new int[list.size()];
        for (int i = 0; i < list.size(); i++) {
            result[i] = list.get(i);
        }

        return result;
    }

}
