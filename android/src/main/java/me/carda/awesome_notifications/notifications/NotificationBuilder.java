package me.carda.awesome_notifications.notifications;

import android.app.Notification;
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
import android.os.Handler;
import android.os.Looper;
import android.preference.PreferenceManager;
import android.service.notification.StatusBarNotification;

import com.github.arturogutierrez.BadgesNotSupportedException;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import androidx.annotation.NonNull;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;
import androidx.core.app.RemoteInput;

import me.carda.awesome_notifications.AwesomeNotificationsPlugin;
import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.broadcastReceivers.DismissedNotificationReceiver;
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
import com.github.arturogutierrez.Badges;

public class NotificationBuilder {

    public static String TAG = "NotificationBuilder";

    public Notification createNotification(Context context, NotificationModel notificationModel) throws AwesomeNotificationException {
        return createNotification(context, notificationModel, false);
    }

    public Notification createNotification(Context context, NotificationModel notificationModel, boolean isSummary) throws AwesomeNotificationException {

        Intent intent = buildNotificationIntentFromModel(
            context,
            Definitions.SELECT_NOTIFICATION,
                notificationModel
        );

        Intent deleteIntent = buildNotificationIntentFromModel(
            context,
            Definitions.DISMISSED_NOTIFICATION,
                notificationModel,
            DismissedNotificationReceiver.class
        );

        PendingIntent pendingIntent =
            notificationModel.content.notificationActionType == NotificationActionType.BringToForeground ?
                PendingIntent.getActivity(
                        context,
                        notificationModel.content.id,
                        intent,
                        PendingIntent.FLAG_UPDATE_CURRENT
                ) :
                PendingIntent.getBroadcast(
                        context,
                        notificationModel.content.id,
                        intent,
                        PendingIntent.FLAG_UPDATE_CURRENT
                );

        PendingIntent pendingDeleteIntent = PendingIntent.getBroadcast(
            context,
            notificationModel.content.id,
            deleteIntent,
            PendingIntent.FLAG_UPDATE_CURRENT
        );

        NotificationCompat.Builder builder = getNotificationBuilderFromModel(context, notificationModel, pendingIntent, pendingDeleteIntent, isSummary);

        return builder.build();
    }

    public Intent buildNotificationIntentFromModel(Context context, String ActionReference, NotificationModel notificationModel){

        Class<?> targetClass =
                notificationModel.content.notificationActionType == NotificationActionType.BringToForeground ?
                        getNotificationTargetActivityClass(context) :
                        SilentActionReceiver.class;

        return buildNotificationIntentFromModel(context, ActionReference, notificationModel, targetClass);
    }

    public Intent buildNotificationIntentFromModel(Context context, String ActionReference, NotificationModel notificationModel, Class<?> targetClass){
        Intent intent = new Intent(context, targetClass);

        intent.setAction(ActionReference);

        String jsonData = notificationModel.toJson();
        intent.putExtra(Definitions.NOTIFICATION_JSON, jsonData);
        intent.putExtra(Definitions.NOTIFICATION_ID, notificationModel.content.id);
        intent.putExtra(Definitions.NOTIFICATION_AUTO_DISMISSIBLE, notificationModel.content.autoDismissible);
        intent.putExtra(Definitions.NOTIFICATION_ACTION_TYPE, notificationModel.content.notificationActionType.toString());

        return intent;
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

            actionModel.actionLifeCycle = AwesomeNotificationsPlugin.appLifeCycle;

            if (isButtonAction){
                actionModel.actionKey = intent.getStringExtra(Definitions.NOTIFICATION_BUTTON_KEY);
                if(intent.getBooleanExtra(Definitions.NOTIFICATION_REQUIRE_INPUT_TEXT, false)){
                    actionModel.actionInput = getButtonInputText(intent, intent.getStringExtra(Definitions.NOTIFICATION_BUTTON_KEY));
                    if(StringUtils.isNullOrEmpty(actionModel.actionInput))
                        actionModel.actionInput = intent.getStringExtra(Definitions.NOTIFICATION_INPUT_TEXT);
                    intent.putExtra(Definitions.NOTIFICATION_INPUT_TEXT, actionModel.actionInput);
                }
            }

            if(StringUtils.isNullOrEmpty(actionModel.displayedDate)){
                actionModel.displayedDate = DateUtils.getUTCDate();
            }
            actionModel.actionDate = DateUtils.getUTCDate();

            return actionModel;
        }
        return null;
    }

    public static void finalizeNotificationIntent(Context context, NotificationModel notificationModel, Intent intent){

        int notificationId = intent.getIntExtra(Definitions.NOTIFICATION_ID, -1);

        if (intent.getBooleanExtra(Definitions.NOTIFICATION_AUTO_DISMISSIBLE, notificationId >= 0)) {

            // "IT WORKS" to cancel notification remote inputs since Android 9, but is not the correct way to do
            // https://stackoverflow.com/questions/54219914/cancel-notification-with-remoteinput-not-working/56867575#56867575
            if(intent.getBooleanExtra(Definitions.NOTIFICATION_REQUIRE_INPUT_TEXT, false) && Build.VERSION.SDK_INT >= 28){
                try {
                    Intent it = new Intent(Intent.ACTION_CLOSE_SYSTEM_DIALOGS);
                    context.sendBroadcast(it);

                    notificationId = notificationModel.content.id;
                    NotificationSender.send(context, notificationModel);

                    int finalNotificationId = notificationId;
                    new Handler(Looper.getMainLooper()).postDelayed(new Runnable() {
                        @Override
                        public void run() {
                            NotificationSender.dismissNotification(context, finalNotificationId);
                        }
                    }, 500);
                } catch (Exception e) {
                    NotificationSender.dismissNotification(context, notificationId);
                    e.printStackTrace();
                }
            }
            else {
                NotificationSender.dismissNotification(context, notificationId);
            }
        }
    }

    private static String getButtonInputText(Intent intent, String buttonKey) {
        Bundle remoteInput = RemoteInput.getResultsFromIntent(intent);
        if (remoteInput != null) {
            return remoteInput.getCharSequence(buttonKey).toString();
        }
        return null;
    }

    private NotificationCompat.Builder getNotificationBuilderFromModel(Context context, NotificationModel notificationModel, PendingIntent pendingIntent, PendingIntent deleteIntent, boolean isSummary) throws AwesomeNotificationException {

        NotificationChannelModel channel = ChannelManager.getChannelByKey(context, notificationModel.content.channelKey);

        if(channel == null) throw new AwesomeNotificationException("Channel '"+ notificationModel.content.channelKey+"' does not exist or is disabled");

        NotificationCompat.Builder builder = new NotificationCompat.Builder(context, notificationModel.content.channelKey);

        setGrouping(context, notificationModel, channel, builder);

        setVisibility(context, notificationModel, channel, builder);
        setShowWhen(notificationModel, builder);

        setLayout(context, notificationModel, builder);

        createActionButtons(context, notificationModel, builder);

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

        setSmallIcon(context, notificationModel, channel, builder);
        setLargeIcon(context, notificationModel, builder);
        setLayoutColor(context, notificationModel, channel, builder);

        if(!isSummary)
            setBadge(context, channel, builder);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            builder.setChannelId(channel.getChannelKey());

        builder.setContentIntent(pendingIntent);
        if(!isSummary){
            builder.setDeleteIntent(deleteIntent);
        }

        return builder;
    }

    private void setShowWhen(NotificationModel notificationModel, NotificationCompat.Builder builder) {
        builder.setShowWhen(BooleanUtils.getValueOrDefault(notificationModel.content.showWhen, true));
    }

    private Integer getBackgroundColor(NotificationModel notificationModel, NotificationChannelModel channel, NotificationCompat.Builder builder){
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

    private Integer getLayoutColor(NotificationModel notificationModel, NotificationChannelModel channel){
        Integer layoutColorValue;
        layoutColorValue = IntegerUtils.extractInteger(notificationModel.content.color, channel.defaultColor);
        layoutColorValue = IntegerUtils.extractInteger(layoutColorValue, Color.BLACK);
        return layoutColorValue;
    }

    private void setImportance(NotificationChannelModel channel, NotificationCompat.Builder builder) {
        // Conversion to Priority
        int priorityValue = Math.min(Math.max(IntegerUtils.extractInteger(channel.importance) -2,-2),2);
        builder.setPriority(priorityValue);
    }

    private void setOnlyAlertOnce(NotificationModel notificationModel, NotificationChannelModel channel, NotificationCompat.Builder builder) {
        boolean onlyAlertOnceValue = BooleanUtils.getValue(notificationModel.content.notificationLayout == NotificationLayout.ProgressBar || channel.onlyAlertOnce);
        builder.setOnlyAlertOnce(onlyAlertOnceValue);
    }

    private void setLockedNotification(NotificationModel notificationModel, NotificationChannelModel channel, NotificationCompat.Builder builder) {
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

    private void setTicker(NotificationModel notificationModel, NotificationCompat.Builder builder) {
        String tickerValue;
        tickerValue = StringUtils.getValueOrDefault(notificationModel.content.ticker, null);
        tickerValue = StringUtils.getValueOrDefault(tickerValue, notificationModel.content.summary);
        tickerValue = StringUtils.getValueOrDefault(tickerValue, notificationModel.content.body);
        builder.setTicker(tickerValue);
    }

    private void setBadge(Context context, NotificationChannelModel channelModel, NotificationCompat.Builder builder){
        if(BooleanUtils.getValue(channelModel.channelShowBadge)){
            incrementGlobalBadgeCounter(context, channelModel);
            builder.setNumber(1);
        }
    }

    private void setAutoDismissible(NotificationModel notificationModel, NotificationCompat.Builder builder) {
        builder.setAutoCancel(BooleanUtils.getValueOrDefault(notificationModel.content.autoDismissible, true));
    }

    private void setBody(NotificationModel notificationModel, NotificationCompat.Builder builder) {
        builder.setContentText(HtmlUtils.fromHtml(notificationModel.content.body));
    }

    private void setTitle(NotificationModel notificationModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {
        if(notificationModel.content.title != null){
            builder.setContentTitle(HtmlUtils.fromHtml(notificationModel.content.title));
        }
    }

    private void setVibrationPattern(NotificationChannelModel channelModel, NotificationCompat.Builder builder) {
        if (BooleanUtils.getValue(channelModel.enableVibration)) {
            if (channelModel.vibrationPattern != null && channelModel.vibrationPattern.length > 0) {
                builder.setVibrate(channelModel.vibrationPattern);
            }
        } else {
            builder.setVibrate(new long[]{0});
        }
    }

    private void setLights(NotificationChannelModel channelModel, NotificationCompat.Builder builder) {
        if (BooleanUtils.getValue(channelModel.enableLights)) {
            Integer ledColorValue = IntegerUtils.extractInteger(channelModel.ledColor, Color.WHITE);
            Integer ledOnMsValue = IntegerUtils.extractInteger(channelModel.ledOnMs, 300);
            Integer ledOffMsValue = IntegerUtils.extractInteger(channelModel.ledOffMs, 700);
            builder.setLights(ledColorValue, ledOnMsValue, ledOffMsValue);
        }
    }

    private void setVisibility(Context context, NotificationModel notificationModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {

        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {

            Integer visibilityIndex;
            visibilityIndex = IntegerUtils.extractInteger(notificationModel.content.privacy, channelModel.defaultPrivacy.ordinal());
            visibilityIndex = IntegerUtils.extractInteger(visibilityIndex, NotificationPrivacy.Public);

            builder.setVisibility(visibilityIndex - 1);
        }
    }

    private void setLayoutColor(Context context, NotificationModel notificationModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {

        if(notificationModel.content.backgroundColor == null){
            builder.setColor(getLayoutColor(notificationModel, channelModel));
        } else {
            builder.setColor(getBackgroundColor(notificationModel, channelModel, builder));
        }
    }

    private void setLargeIcon(Context context, NotificationModel notificationModel, NotificationCompat.Builder builder) {
        if (!StringUtils.isNullOrEmpty(notificationModel.content.largeIcon)) {
            Bitmap largeIcon = BitmapUtils.getBitmapFromSource(context, notificationModel.content.largeIcon);
            if(largeIcon != null){
                builder.setLargeIcon(largeIcon);
            }
        }
    }

    public static String getBadgeKey(Context context, String channelKey){
        return "count_key"+(channelKey == null ? "_total" : channelKey);
    }

    public static int getGlobalBadgeCounter(Context context, String channelKey){
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(context);

        // Read previous value. If not found, use 0 as default value.
        return prefs.getInt(getBadgeKey(context, channelKey), 0);
    }

    public static void setGlobalBadgeCounter(Context context, String channelKey, int count){
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(context);
        SharedPreferences.Editor editor = prefs.edit();

        try {

            editor.putInt(getBadgeKey(context, channelKey), count);
            Badges.setBadge(context, count);

        } catch (BadgesNotSupportedException ignored) {
        }

        editor.apply();
    }

    public static void resetGlobalBadgeCounter(Context context, String channelKey){
        setGlobalBadgeCounter(context, channelKey, 0 );
    }

    public static int incrementGlobalBadgeCounter(Context context, NotificationChannelModel channelModel){

        int totalAmount = getGlobalBadgeCounter(context, null);
        setGlobalBadgeCounter(context, null, ++totalAmount);

        return totalAmount;
    }

    public Class getNotificationTargetActivityClass(Context context) {
        String packageName = context.getPackageName();
        Intent launchIntent = context.getPackageManager().getLaunchIntentForPackage(packageName);
        String className = launchIntent.getComponent().getClassName();
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
    public void createActionButtons(Context context, NotificationModel notificationModel, NotificationCompat.Builder builder) {

        if(ListUtils.isNullOrEmpty(notificationModel.actionButtons)) return;

        for(NotificationButtonModel buttonProperties : notificationModel.actionButtons) {

            Class<?> targetClass =
                    buttonProperties.notificationActionType == NotificationActionType.BringToForeground ?
                        getNotificationTargetActivityClass(context) :
                        SilentActionReceiver.class;

            Intent actionIntent = buildNotificationIntentFromModel(
                context,
                Definitions.NOTIFICATION_BUTTON_ACTION_PREFIX + "_" + buttonProperties.key,
                    notificationModel,
                targetClass
            );

            actionIntent.putExtra(Definitions.NOTIFICATION_BUTTON_KEY, buttonProperties.key);
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
                        .build();

                builder.addAction( replyAction );

            } else {

                builder.addAction(iconResource, buttonProperties.label, actionPendingIntent);
            }
        }
    }

    private void setSound(Context context, NotificationModel notificationModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {

        Uri uri = null;

        if (BooleanUtils.getValue(channelModel.playSound)) {
            uri = ChannelManager.retrieveSoundResourceUri(context, channelModel.defaultRingtoneType, channelModel.soundSource);
        }

        builder.setSound(uri);
    }

    private void setSmallIcon(Context context, NotificationModel notificationModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {
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

    private void setGrouping(Context context, NotificationModel notificationModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {

        if (!StringUtils.isNullOrEmpty(channelModel.groupKey)) {
            builder.setGroup(channelModel.groupKey);

            if(notificationModel.groupSummary) {
                builder.setGroupSummary(true);
            }
            else {
                boolean grouped = true;
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {

                    NotificationManager manager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
                    StatusBarNotification[] currentActiveNotifications = manager.getActiveNotifications();

                    for (StatusBarNotification activeNotification : currentActiveNotifications) {
                        if (activeNotification.getGroupKey().contains("g:"+channelModel.groupKey)) {
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
    }

    private void setLayout(Context context, NotificationModel notificationModel, NotificationCompat.Builder builder) {

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
                if(setMessagingLayout(context, notificationModel.content, builder)) return;
                break;

            case MediaPlayer:
                if(setMediaPlayerLayout(context, notificationModel.content, builder)) return;
                break;

            case ProgressBar:
                setProgressLayout(notificationModel, builder);
                break;

            case Default:
            default:
                break;
        }
    }

    private Boolean setBigPictureLayout(Context context, NotificationContentModel contentModel, NotificationCompat.Builder builder) {

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

    private Boolean setBigTextStyle(Context context, NotificationContentModel contentModel, NotificationCompat.Builder builder) {

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

    private Boolean setInboxLayout(Context context, NotificationContentModel contentModel, NotificationCompat.Builder builder) {

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

    private Boolean setMessagingLayout(Context context, NotificationContentModel contentModel, NotificationCompat.Builder builder) {
        //TODO MISSING IMPLEMENTATION
        return true;
    }

    private Boolean setMediaPlayerLayout(Context context, NotificationContentModel contentModel, NotificationCompat.Builder builder) {

        builder.setStyle(
            new androidx.media.app.NotificationCompat.MediaStyle()
                .setShowActionsInCompactView(1,2,3)
                .setShowCancelButton(true)
                .setMediaSession(AwesomeNotificationsPlugin.mediaSession.getSessionToken())
        );

        if(!StringUtils.isNullOrEmpty(contentModel.summary)){
            builder.setSubText(contentModel.summary);
        }

        builder.setShowWhen(false);

        return true;
    }

    private void setProgressLayout(NotificationModel notificationModel, NotificationCompat.Builder builder) {
        builder.setProgress(
                100,
                Math.max(0, Math.min(100, IntegerUtils.extractInteger(notificationModel.content.progress, 0))),
                notificationModel.content.progress == null
        );
    }

}
