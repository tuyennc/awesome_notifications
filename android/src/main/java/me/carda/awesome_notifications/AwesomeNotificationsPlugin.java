package me.carda.awesome_notifications;

import android.app.Application;
import android.app.Application.ActivityLifecycleCallbacks;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import android.support.v4.media.session.MediaSessionCompat;
import io.flutter.Log;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import androidx.annotation.NonNull;
import androidx.core.app.NotificationManagerCompat;
import androidx.lifecycle.*;
import androidx.localbroadcastmanager.content.LocalBroadcastManager;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;

import android.app.Activity;

import me.carda.awesome_notifications.background.DartBackgroundService;
import me.carda.awesome_notifications.notifications.BitmapResourceDecoder;
import me.carda.awesome_notifications.notifications.models.DefaultsModel;
import me.carda.awesome_notifications.notifications.models.NotificationCalendarModel;
import me.carda.awesome_notifications.notifications.models.NotificationIntervalModel;
import me.carda.awesome_notifications.notifications.models.NotificationScheduleModel;
import me.carda.awesome_notifications.notifications.models.NotificationModel;
import me.carda.awesome_notifications.notifications.enumerators.MediaSource;
import me.carda.awesome_notifications.notifications.enumerators.NotificationLifeCycle;
import me.carda.awesome_notifications.notifications.enumerators.NotificationSource;
import me.carda.awesome_notifications.notifications.exceptions.AwesomeNotificationException;

import me.carda.awesome_notifications.notifications.NotificationBuilder;

import me.carda.awesome_notifications.notifications.managers.ChannelManager;
import me.carda.awesome_notifications.notifications.managers.CreatedManager;
import me.carda.awesome_notifications.notifications.managers.DefaultsManager;
import me.carda.awesome_notifications.notifications.managers.DismissedManager;
import me.carda.awesome_notifications.notifications.managers.DisplayedManager;

import me.carda.awesome_notifications.notifications.managers.ScheduleManager;
import me.carda.awesome_notifications.notifications.models.NotificationChannelModel;
import me.carda.awesome_notifications.notifications.models.returnedData.ActionReceived;
import me.carda.awesome_notifications.notifications.models.returnedData.NotificationReceived;

import me.carda.awesome_notifications.notifications.NotificationSender;
import me.carda.awesome_notifications.notifications.NotificationScheduler;

import me.carda.awesome_notifications.services.ForegroundService;
import me.carda.awesome_notifications.utils.BooleanUtils;
import me.carda.awesome_notifications.utils.DateUtils;
import me.carda.awesome_notifications.utils.JsonUtils;
import me.carda.awesome_notifications.utils.ListUtils;
import me.carda.awesome_notifications.utils.MapUtils;
import me.carda.awesome_notifications.utils.MediaUtils;
import me.carda.awesome_notifications.utils.StringUtils;

import static me.carda.awesome_notifications.Definitions.ACTION_HANDLE;
import static me.carda.awesome_notifications.Definitions.NOTIFICATION_CHANNEL_KEY;
import static me.carda.awesome_notifications.Definitions.NOTIFICATION_RECEIVED_ACTION;

/** AwesomeNotificationsPlugin **/
public class AwesomeNotificationsPlugin
        extends BroadcastReceiver
        implements FlutterPlugin, MethodCallHandler, PluginRegistry.NewIntentListener, ActivityAware, ActivityLifecycleCallbacks {

    public static Boolean debug = false;

    public static Result pendingAuthorizationReturn;
    public static String lastChannelKeyRequested = null;
    public static Boolean hasGoneToAuthorizationPage = false;

    private static String mainTargetClassName;
    public static NotificationLifeCycle appLifeCycle = NotificationLifeCycle.AppKilled;

    private static final String TAG = "AwesomeNotificationsPlugin";

    private static boolean isInitialized = false;

    private Activity initialActivity;
    private MethodChannel pluginChannel;
    private Context applicationContext;
    private IntentFilter intentFilter;

    public static MediaSessionCompat mediaSession;

    public static String getMainTargetClassName() {
        return mainTargetClassName;
    }

    @Override
    public boolean onNewIntent(Intent intent){
        return receiveNotificationAction(intent);
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {

        AttachAwesomeNotificationsPlugin(
            //applicationContext != null ? applicationContext :
                flutterPluginBinding.getApplicationContext(),
            //pluginChannel != null ? pluginChannel :
                new MethodChannel(
                    flutterPluginBinding.getBinaryMessenger(),
                    Definitions.CHANNEL_FLUTTER_PLUGIN
                ));
    }

    private void AttachAwesomeNotificationsPlugin(Context context, MethodChannel channel) {

        applicationContext = context;

        pluginChannel = channel;
        pluginChannel.setMethodCallHandler(this);

        NotificationScheduler.refreshScheduleNotifications(context);

        if(AwesomeNotificationsPlugin.debug)
            Log.d(TAG, "Awesome Notifications attached for Android "+Build.VERSION.SDK_INT);
    }

    private void detachAwesomeNotificationsPlugin(Context context) {

        pluginChannel.setMethodCallHandler(null);
        pluginChannel = null;

        if(intentFilter != null) {
            LocalBroadcastManager manager = LocalBroadcastManager.getInstance(context);
            manager.unregisterReceiver(this);
            intentFilter = null;
        }

        mediaSession = null;

        if (AwesomeNotificationsPlugin.debug)
            Log.d(TAG, "Awesome Notifications detached from Android " + Build.VERSION.SDK_INT);
    }

    @Override
    public void onActivityCreated(Activity activity, Bundle savedInstanceState) {
    }

    @Override
    public void onActivityStarted(Activity activity) {

        Context globalContext = activity.getApplicationContext();

        if(intentFilter == null){

            intentFilter = new IntentFilter();

            intentFilter.addAction(Definitions.BROADCAST_CREATED_NOTIFICATION);
            intentFilter.addAction(Definitions.BROADCAST_DISPLAYED_NOTIFICATION);
            intentFilter.addAction(Definitions.BROADCAST_DISMISSED_NOTIFICATION);
            intentFilter.addAction(Definitions.BROADCAST_KEEP_ON_TOP);

            intentFilter.addAction(Definitions.BROADCAST_SILENT_ACTION);

            LocalBroadcastManager manager = LocalBroadcastManager.getInstance(globalContext);
            manager.registerReceiver(this, intentFilter);
            
            mediaSession = new MediaSessionCompat(globalContext, "PUSH_MEDIA");

            Log.d(TAG, "Awesome Notifications broadcasters initialized");
        }

        getApplicationLifeCycle();
    }

    @Override
    public void onActivityResumed(Activity activity) {
        if(hasGoneToAuthorizationPage){
            hasGoneToAuthorizationPage = false;
            pendingAuthorizationReturn.success(isNotificationEnabled(applicationContext, lastChannelKeyRequested));
        }
    }

    @Override
    public void onActivityPaused(Activity activity) {
        getApplicationLifeCycle();
    }

    @Override
    public void onActivityStopped(Activity activity) {
        getApplicationLifeCycle();
    }

    @Override
    public void onActivitySaveInstanceState(Activity activity, Bundle outState) {
    }

    @Override
    public void onActivityDestroyed(Activity activity) {
        getApplicationLifeCycle();
    }

    @Override
    public void onAttachedToActivity(ActivityPluginBinding activityPluginBinding) {
        initialActivity = activityPluginBinding.getActivity();
        activityPluginBinding.addOnNewIntentListener(this);

        Application application = initialActivity.getApplication();
        application.registerActivityLifecycleCallbacks(this);

        if(AwesomeNotificationsPlugin.debug)
            Log.d(TAG, "Notification Lifecycle: (onAttachedToActivity)" + appLifeCycle.toString());
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        detachAwesomeNotificationsPlugin(
                binding.getApplicationContext());
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        if(AwesomeNotificationsPlugin.debug)
            Log.d(TAG, "Notification Lifecycle: (onDetachedFromActivityForConfigChanges)" + appLifeCycle.toString());
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding activityPluginBinding) {
        if(AwesomeNotificationsPlugin.debug)
            Log.d(TAG, "Notification Lifecycle: (onReattachedToActivityForConfigChanges)" + appLifeCycle.toString());
    }

    @Override
    public void onDetachedFromActivity() {
        if(AwesomeNotificationsPlugin.debug)
            Log.d(TAG, "Notification Lifecycle: (onDetachedFromActivity)" + appLifeCycle.toString());
    }

    // BroadcastReceiver by other classes.
    @Override
    public void onReceive(Context context, Intent intent) {
        getApplicationLifeCycle();

        String action = intent.getAction();
        switch (action){

            case Definitions.BROADCAST_CREATED_NOTIFICATION:
                onBroadcastNotificationCreated(intent);
                return;

            case Definitions.BROADCAST_DISPLAYED_NOTIFICATION:
                onBroadcastNotificationDisplayed(intent);
                return;

            case Definitions.BROADCAST_DISMISSED_NOTIFICATION:
                onBroadcastNotificationDismissed(intent);
                return;

            case Definitions.BROADCAST_SILENT_ACTION:
                onBroadcastSilentActionNotification(intent);
                return;

            case Definitions.BROADCAST_KEEP_ON_TOP:
                onBroadcastKeepOnTopActionNotification(intent);
                return;

            case Definitions.BROADCAST_MEDIA_BUTTON:
                onBroadcastMediaButton(intent);
                return;

            default:
                if(AwesomeNotificationsPlugin.debug)
                    Log.d(TAG, "Received unknown action: "+(
                        StringUtils.isNullOrEmpty(action) ? "empty" : action));
        }
    }

    private void onBroadcastNotificationCreated(Intent intent) {

        try {
            Serializable serializable = intent.getSerializableExtra(Definitions.EXTRA_BROADCAST_MESSAGE);

            @SuppressWarnings("unchecked")
            Map<String, Object> content = (serializable instanceof Map ? (Map<String, Object>)serializable : null);
            if(content == null) return;

            NotificationReceived received = new NotificationReceived().fromMap(content);
            received.validate(applicationContext);

            CreatedManager.removeCreated(applicationContext, received.id);
            CreatedManager.commitChanges(applicationContext);

            pluginChannel.invokeMethod(Definitions.CHANNEL_METHOD_NOTIFICATION_CREATED, content);
            
            if(AwesomeNotificationsPlugin.debug)
                Log.d(TAG, "Notification created");

        } catch (Exception e) {
            if(AwesomeNotificationsPlugin.debug)
                Log.d(TAG, String.format("%s", e.getMessage()));
            e.printStackTrace();
        }
    }

    private void onBroadcastKeepOnTopActionNotification(Intent intent) {
        try {

            Serializable serializable = intent.getSerializableExtra(Definitions.EXTRA_BROADCAST_MESSAGE);
            pluginChannel.invokeMethod(Definitions.CHANNEL_METHOD_RECEIVED_ACTION, serializable);

            if(AwesomeNotificationsPlugin.debug)
                Log.d(TAG, "Notification action received");

        } catch (Exception e) {
            if(AwesomeNotificationsPlugin.debug)
                Log.d(TAG, String.format("%s", e.getMessage()));
            e.printStackTrace();
        }
    }

    private void onBroadcastSilentActionNotification(Intent intent) {
        try {

            Serializable serializable = intent.getSerializableExtra(Definitions.EXTRA_BROADCAST_MESSAGE);
            Map<String, Object> dataMap = new HashMap<>();

            dataMap.put(ACTION_HANDLE, DartBackgroundService.getSilentCallbackDispatcher(applicationContext));
            dataMap.put(NOTIFICATION_RECEIVED_ACTION, serializable);

            pluginChannel.invokeMethod(Definitions.CHANNEL_METHOD_SILENT_ACTION, dataMap);

            if(AwesomeNotificationsPlugin.debug)
                Log.d(TAG, "Notification silent action received");

        } catch (Exception e) {
            if(AwesomeNotificationsPlugin.debug)
                Log.d(TAG, String.format("%s", e.getMessage()));
            e.printStackTrace();
        }
    }

    private void onBroadcastMediaButton(Intent intent) {
        try {

            Serializable serializable = intent.getSerializableExtra(Definitions.EXTRA_BROADCAST_MESSAGE);
            pluginChannel.invokeMethod(Definitions.CHANNEL_METHOD_MEDIA_BUTTON, serializable);

            if(AwesomeNotificationsPlugin.debug)
                Log.d(TAG, "Notification action received");

        } catch (Exception e) {
            if(AwesomeNotificationsPlugin.debug)
                Log.d(TAG, String.format("%s", e.getMessage()));
            e.printStackTrace();
        }
    }

    private void onBroadcastNotificationDisplayed(Intent intent) {
        try {

            Serializable serializable = intent.getSerializableExtra(Definitions.EXTRA_BROADCAST_MESSAGE);

            @SuppressWarnings("unchecked")
            Map<String, Object> content = (serializable instanceof Map ? (Map<String, Object>)serializable : null);
            if(content == null) return;

            NotificationReceived received = new NotificationReceived().fromMap(content);
            received.validate(applicationContext);

            DisplayedManager.removeDisplayed(applicationContext, received.id);
            DisplayedManager.commitChanges(applicationContext);

            pluginChannel.invokeMethod(Definitions.CHANNEL_METHOD_NOTIFICATION_DISPLAYED, content);

            if(AwesomeNotificationsPlugin.debug)
                Log.d(TAG, "Notification displayed");

        } catch (Exception e) {
            if(AwesomeNotificationsPlugin.debug)
                Log.d(TAG, String.format("%s", e.getMessage()));
            e.printStackTrace();
        }
    }

    private void onBroadcastNotificationDismissed(Intent intent) {
        try {

            Serializable serializable = intent.getSerializableExtra(Definitions.EXTRA_BROADCAST_MESSAGE);

            @SuppressWarnings("unchecked")
            Map<String, Object> content = (serializable instanceof Map ? (Map<String, Object>)serializable : null);
            if(content == null) return;

            ActionReceived received = new ActionReceived().fromMap(content);
            received.validate(applicationContext);

            DismissedManager.removeDismissed(applicationContext, received.id);
            DisplayedManager.commitChanges(applicationContext);

            pluginChannel.invokeMethod(Definitions.CHANNEL_METHOD_NOTIFICATION_DISMISSED, content);

            if(AwesomeNotificationsPlugin.debug)
                Log.d(TAG, "Notification dismissed");

        } catch (Exception e) {
            if(AwesomeNotificationsPlugin.debug)
                Log.d(TAG, String.format("%s", e.getMessage()));
            e.printStackTrace();
        }
    }

    private void recoverNotificationCreated(Context context) {
        List<NotificationReceived> lostCreated = CreatedManager.listCreated(context);

        if(lostCreated != null) {
            for (NotificationReceived created : lostCreated) {
                try {

                    created.validate(applicationContext);
                    pluginChannel.invokeMethod(Definitions.CHANNEL_METHOD_NOTIFICATION_CREATED, created.toMap());
                    CreatedManager.removeCreated(context, created.id);
                    CreatedManager.commitChanges(context);

                } catch (AwesomeNotificationException e) {
                    if(AwesomeNotificationsPlugin.debug)
                        Log.d(TAG, String.format("%s", e.getMessage()));
                    e.printStackTrace();
                }
            }
        }
    }

    private void recoverNotificationDisplayed(Context context) {
        List<NotificationReceived> lostDisplayed = DisplayedManager.listDisplayed(context);

        if(lostDisplayed != null) {
            for (NotificationReceived displayed : lostDisplayed) {
                try {

                    displayed.validate(applicationContext);
                    pluginChannel.invokeMethod(Definitions.CHANNEL_METHOD_NOTIFICATION_DISPLAYED, displayed.toMap());
                    DisplayedManager.removeDisplayed(context, displayed.id);
                    DisplayedManager.commitChanges(context);

                } catch (AwesomeNotificationException e) {
                    if(AwesomeNotificationsPlugin.debug)
                        Log.d(TAG, String.format("%s", e.getMessage()));
                    e.printStackTrace();
                }
            }
        }
    }

    private void recoverNotificationDismissed(Context context) {
        List<ActionReceived> lostDismissed = DismissedManager.listDismissed(context);

        if(lostDismissed != null) {
            for (ActionReceived received : lostDismissed) {
                try {

                    received.validate(applicationContext);
                    pluginChannel.invokeMethod(Definitions.CHANNEL_METHOD_NOTIFICATION_DISMISSED, received.toMap());
                    DismissedManager.removeDismissed(context, received.id);
                    DismissedManager.commitChanges(context);

                } catch (AwesomeNotificationException e) {
                    if(AwesomeNotificationsPlugin.debug)
                        Log.d(TAG, String.format("%s", e.getMessage()));
                    e.printStackTrace();
                }
            }
        }
    }

    @Override
    public void onMethodCall(@NonNull final MethodCall call, @NonNull final Result result) {

        getApplicationLifeCycle();

        try {

            switch (call.method){

                case Definitions.CHANNEL_METHOD_INITIALIZE:
                    channelMethodInitialize(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_SET_ACTION_HANDLE:
                    channelMethodSetActionHandle(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_GET_DRAWABLE_DATA:
                    channelMethodGetDrawableData(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_IS_NOTIFICATION_ALLOWED:
                    channelIsNotificationAllowed(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_SHOW_NOTIFICATION_PAGE:
                    channelShowNotificationPage(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_REQUEST_NOTIFICATIONS:
                    channelRequestNotification(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_CREATE_NOTIFICATION:
                    channelMethodCreateNotification(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_LIST_ALL_SCHEDULES:
                    channelMethodListAllSchedules(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_GET_NEXT_DATE:
                    channelMethodGetNextDate(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_GET_LOCAL_TIMEZONE_IDENTIFIER:
                    channelMethodGetLocalTimeZone(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_GET_UTC_TIMEZONE_IDENTIFIER:
                    channelMethodGetUtcTimeZone(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_SET_NOTIFICATION_CHANNEL:
                    channelMethodSetChannel(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_REMOVE_NOTIFICATION_CHANNEL:
                    channelMethodRemoveChannel(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_GET_BADGE_COUNT:
                    channelMethodGetBadgeCounter(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_SET_BADGE_COUNT:
                    channelMethodSetBadgeCounter(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_RESET_BADGE:
                    channelMethodResetBadge(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_DISMISS_NOTIFICATION:
                    channelMethodDismissNotification(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_DISMISS_NOTIFICATIONS_BY_CHANNEL_KEY:
                    channelMethodDismissNotificationsByChannelKey(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_CANCEL_SCHEDULES_BY_CHANNEL_KEY:
                    channelMethodCancelSchedulesByChannelKey(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_CANCEL_NOTIFICATIONS_BY_CHANNEL_KEY:
                    channelMethodCancelNotificationsByChannelKey(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_CANCEL_NOTIFICATION:
                    channelMethodCancelNotification(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_CANCEL_SCHEDULE:
                    channelMethodCancelSchedule(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_DISMISS_ALL_NOTIFICATIONS:
                    channelMethodDismissAllNotifications(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_CANCEL_ALL_SCHEDULES:
                    channelMethodCancelAllSchedules(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_CANCEL_ALL_NOTIFICATIONS:
                    channelMethodCancelAllNotifications(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_START_FOREGROUND:
                    channelMethodStartForeground(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_STOP_FOREGROUND:
                    channelMethodStopForeground(call, result);
                    return;

                default:
                    result.notImplemented();
            }

        } catch (Exception e) {
            if(AwesomeNotificationsPlugin.debug)
                Log.d(TAG, String.format("%s", e.getMessage()));

            result.error(call.method, e.getMessage(), e);
            e.printStackTrace();
        }
    }
    private void channelMethodStartForeground(MethodCall call, Result result) throws Exception {

        // We don't do any checks here if the notification channel belonging to the notification is disabled
        // because for an foreground service, it doesn't matter
        Map<String, Object> notificationData = call.<Map<String, Object>>argument(Definitions.FOREGROUND_NOTIFICATION_DATA);
        Integer startType = call.<Integer>argument(Definitions.FOREGROUND_START_TYPE);
        Boolean hasForegroundServiceType = call.<Boolean>argument(Definitions.FOREGROUND_HAS_FOREGROUND);
        Integer foregroundServiceType = call.<Integer>argument(Definitions.FOREGROUND_SERVICE_TYPE);

        if (notificationData != null && startType != null && hasForegroundServiceType != null && foregroundServiceType != null) {
            ForegroundService.StartParameter parameter =
                    new ForegroundService.StartParameter(notificationData, startType, hasForegroundServiceType, foregroundServiceType);
            Intent intent = new Intent(applicationContext, ForegroundService.class);
            intent.putExtra(ForegroundService.StartParameter.EXTRA, parameter);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                applicationContext.startForegroundService(intent);
            } else {
                applicationContext.startService(intent);
            }
            result.success(null);
        } else {
            throw new IllegalArgumentException("An argument passed to startForeground is missing or invalid");
        }
    }

    private void channelMethodStopForeground(MethodCall call, Result result) {
        applicationContext.stopService(new Intent(applicationContext, ForegroundService.class));
        result.success(null);
    }

    private void channelMethodGetDrawableData(@NonNull MethodCall call, Result result) throws Exception {

        String bitmapReference = call.arguments();

        BitmapResourceDecoder bitmapResourceDecoder = new BitmapResourceDecoder(
            applicationContext,
            result,
            bitmapReference
        );

        bitmapResourceDecoder.execute();
    }

    private void channelMethodListAllSchedules(MethodCall call, Result result) throws Exception {
        List<NotificationModel> activeSchedules = ScheduleManager.listSchedules(applicationContext);
        List<Map<String, Object>> listSerialized = new ArrayList<>();

        if(activeSchedules != null){
            for(NotificationModel notificationModel : activeSchedules){
                Map<String, Object> serialized = notificationModel.toMap();
                listSerialized.add(serialized);
            }
        }

        result.success(listSerialized);
    }

    private void channelMethodGetNextDate(@NonNull MethodCall call, Result result) throws Exception {

        @SuppressWarnings("unchecked")
        Map<String, Object> data = MapUtils.extractArgument(call.arguments(), Map.class).orNull();

        assert data != null;

        @SuppressWarnings("unchecked")
        Map<String, Object> scheduleData = (Map<String, Object>) data.get(Definitions.NOTIFICATION_SCHEDULE);
        String fixedDateString = (String) data.get(Definitions.NOTIFICATION_INITIAL_FIXED_DATE);

        assert scheduleData != null;
        NotificationScheduleModel scheduleModel;
        if(scheduleData.containsKey(Definitions.NOTIFICATION_SCHEDULE_INTERVAL)){
            scheduleModel = new NotificationIntervalModel().fromMap(scheduleData);
        }
        else {
            scheduleModel = new NotificationCalendarModel().fromMap(scheduleData);
        }

        if(scheduleModel != null) {

            Date fixedDate = null;

            if (!StringUtils.isNullOrEmpty(fixedDateString))
                fixedDate = DateUtils.stringToDate(fixedDateString, scheduleModel.timeZone);

            Calendar nextValidDate = scheduleModel.getNextValidDate(fixedDate);

            String finalValidDateString = null;
            if (nextValidDate != null)
                finalValidDateString = DateUtils.dateToString(nextValidDate.getTime(), scheduleModel.timeZone);

            result.success(finalValidDateString);
            return;
        }

        result.success(null);
    }

    private void channelMethodGetLocalTimeZone(MethodCall call, @NonNull Result result) throws Exception {
        result.success(DateUtils.localTimeZone.getID());
    }

    private void channelMethodGetUtcTimeZone(MethodCall call, @NonNull Result result) throws Exception {
        result.success(DateUtils.utcTimeZone.getID());
    }

    private void channelMethodSetChannel(@NonNull MethodCall call, Result result) throws Exception {

        @SuppressWarnings("unchecked")
        Map<String, Object> channelData = MapUtils.extractArgument(call.arguments(), Map.class).orNull();
        assert channelData != null;

        NotificationChannelModel channelModel = new NotificationChannelModel().fromMap(channelData);
        Boolean forceUpdate = BooleanUtils.getValue((Boolean) channelData.get(Definitions.CHANNEL_FORCE_UPDATE));

        if(channelModel == null){
            throw new AwesomeNotificationException("Channel is invalid");
        } else {

            ChannelManager.saveChannel(applicationContext, channelModel, forceUpdate);
            result.success(true);

            ChannelManager.commitChanges(applicationContext);
        }
    }

    private void channelMethodRemoveChannel(@NonNull MethodCall call, Result result) throws Exception {
        String channelKey = call.arguments();

        if(StringUtils.isNullOrEmpty(channelKey)){
            throw new AwesomeNotificationException("Empty channel key");
        } else {
            Boolean removed = ChannelManager.removeChannel(applicationContext, channelKey);

            if (removed) {
                if(AwesomeNotificationsPlugin.debug)
                    Log.d(TAG, "Channel removed");
                result.success(true);
            }
            else {
                if(AwesomeNotificationsPlugin.debug)
                    Log.d(TAG, "Channel '"+channelKey+"' not found");
                result.success(false);
            }

            ChannelManager.commitChanges(applicationContext);
        }
    }

    private void channelMethodGetBadgeCounter(@NonNull MethodCall call, Result result) throws Exception {
        String channelKey = call.arguments();
        Integer badgeCount = NotificationBuilder.getGlobalBadgeCounter(applicationContext, channelKey);

        // Android resets badges automatically when all notifications are cleared
        result.success(badgeCount);
    }

    private void channelMethodSetBadgeCounter(@NonNull MethodCall call, Result result) throws Exception {
        @SuppressWarnings("unchecked")
        Map<String, Object> data = MapUtils.extractArgument(call.arguments(), Map.class).orNull();
        Integer count = (Integer) data.get(Definitions.NOTIFICATION_CHANNEL_SHOW_BADGE);
        String channelKey = (String) data.get(NOTIFICATION_CHANNEL_KEY);

        if(count == null || count < 0)
            throw new AwesomeNotificationException("Invalid Badge");

        // Android resets badges automatically when all notifications are cleared
        NotificationBuilder.setGlobalBadgeCounter(applicationContext, channelKey, count);
        result.success(true);
    }

    private void channelMethodResetBadge(@NonNull MethodCall call, @NonNull Result result) throws Exception {
        String channelKey = call.arguments();
        NotificationBuilder.resetGlobalBadgeCounter(applicationContext, channelKey);
        result.success(null);
    }

    private void channelMethodCancelSchedule(@NonNull MethodCall call, Result result) throws Exception {

        Integer notificationId = call.arguments();
        if(notificationId == null || notificationId < 0)
            throw new AwesomeNotificationException("Invalid notification id");

        NotificationScheduler.cancelSchedule(applicationContext, notificationId);

        if(AwesomeNotificationsPlugin.debug)
            Log.d(TAG, "Schedule id "+notificationId+" cancelled");

        result.success(true);
    }

    private void channelMethodCancelAllSchedules(MethodCall call, Result result) throws Exception {

        NotificationScheduler.cancelAllSchedules(applicationContext);
        if(AwesomeNotificationsPlugin.debug)
            Log.d(TAG, "All notifications scheduled was cancelled");

        result.success(true);
    }

    private void channelMethodDismissNotification(@NonNull MethodCall call, Result result) throws Exception {

        Integer notificationId = call.arguments();
        if(notificationId == null || notificationId < 0)
            throw new AwesomeNotificationException("Invalid notification id");

        NotificationSender.dismissNotification(applicationContext, notificationId);

        if(AwesomeNotificationsPlugin.debug)
            Log.d(TAG, "Notification id "+notificationId+" dismissed");

        result.success(true);
    }

    private void channelMethodDismissNotificationsByChannelKey(@NonNull MethodCall call, Result result) throws Exception {

        String channelKey = call.arguments();
        if(StringUtils.isNullOrEmpty(channelKey))
            throw new AwesomeNotificationException("Invalid channel key");

        NotificationSender.dismissNotificationsByChannelKey(applicationContext, channelKey);

        if(AwesomeNotificationsPlugin.debug)
            Log.d(TAG, "Notifications from channel "+channelKey+" dismissed");

        result.success(true);
    }

    private void channelMethodCancelSchedulesByChannelKey(@NonNull MethodCall call, Result result) throws Exception {

        String channelKey = call.arguments();
        if(StringUtils.isNullOrEmpty(channelKey))
            throw new AwesomeNotificationException("Invalid channel key");

        NotificationScheduler.cancelSchedulesByChannelKey(applicationContext, channelKey);

        if(AwesomeNotificationsPlugin.debug)
            Log.d(TAG, "Scheduled Notifications from channel "+channelKey+" canceled");

        result.success(true);
    }

    private void channelMethodCancelNotificationsByChannelKey(@NonNull MethodCall call, Result result) throws Exception {

        String channelKey = call.arguments();
        if(StringUtils.isNullOrEmpty(channelKey))
            throw new AwesomeNotificationException("Invalid channel key");

        NotificationSender.dismissNotificationsByChannelKey(applicationContext, channelKey);
        NotificationScheduler.cancelSchedulesByChannelKey(applicationContext, channelKey);

        if(AwesomeNotificationsPlugin.debug)
            Log.d(TAG, "Notifications and schedules from channel "+channelKey+" canceled");

        result.success(true);
    }

    private void channelMethodCancelNotification(@NonNull MethodCall call, Result result) throws Exception {

        Integer notificationId = call.arguments();
        if(notificationId == null || notificationId < 0)
            throw new AwesomeNotificationException("Invalid notification id");

        NotificationScheduler.cancelSchedule(applicationContext, notificationId);
        NotificationSender.dismissNotification(applicationContext, notificationId);

        if(AwesomeNotificationsPlugin.debug)
            Log.d(TAG, "Notification id "+notificationId+" cancelled");

        result.success(true);
    }

    private void channelMethodDismissAllNotifications(MethodCall call, Result result) throws Exception {

        NotificationSender.dismissAllNotifications(applicationContext);
        if(AwesomeNotificationsPlugin.debug)
            Log.d(TAG, "All notifications was dismissed");

        result.success(true);
    }


    private void channelMethodCancelAllNotifications(MethodCall call, Result result) throws Exception {

        NotificationScheduler.cancelAllSchedules(applicationContext);
        NotificationSender.dismissAllNotifications(applicationContext);

        if(AwesomeNotificationsPlugin.debug)
            Log.d(TAG, "All notifications was cancelled");

        result.success(true);
    }

    private void channelIsNotificationAllowed(@NonNull MethodCall call, Result result) throws Exception {

        String channelKey = null;
        Map<String, Object> argumentsData = call.arguments();

        if(argumentsData != null){
            Object object = argumentsData.get(NOTIFICATION_CHANNEL_KEY);
            if(object != null)
                channelKey = (String) argumentsData.get(NOTIFICATION_CHANNEL_KEY);
        }

        result.success(isNotificationEnabled(applicationContext, channelKey));
    }

    private void channelShowNotificationPage(MethodCall call, @NonNull Result result) throws Exception {
        showNotificationConfigPage();
        result.success(null);
    }

    private void showNotificationConfigPage(){

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {

            final Intent intent = new Intent();

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                intent.setAction(Settings.ACTION_APP_NOTIFICATION_SETTINGS);
                intent.putExtra(Settings.EXTRA_APP_PACKAGE, applicationContext.getPackageName());
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP){
                intent.setAction("android.settings.APP_NOTIFICATION_SETTINGS");
                intent.putExtra("app_package", applicationContext.getPackageName());
                intent.putExtra("app_uid", applicationContext.getApplicationInfo().uid);
            } else {
                intent.setAction(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
                intent.addCategory(Intent.CATEGORY_DEFAULT);
                intent.setData(Uri.parse("package:" + applicationContext.getPackageName()));
            }

            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            applicationContext.startActivity(intent);
        }
    }

    private void channelRequestNotification(@NonNull MethodCall call, Result result) throws Exception {

        Map<String, Object> argumentsData = call.arguments();
        String channelKey = null;

        if(argumentsData != null){
            channelKey = (String) argumentsData.get(NOTIFICATION_CHANNEL_KEY);
        }

        if (isNotificationEnabled(applicationContext, channelKey)){
            result.success(true);
            return;
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {

            // Necessary to return the call only after the app goes to foreground on next time
            pendingAuthorizationReturn = result;
            hasGoneToAuthorizationPage = true;
            lastChannelKeyRequested = channelKey;

            showNotificationConfigPage();
        }
        else {
            channelIsNotificationAllowed(call, result);
        }
    }

    private void channelMethodCreateNotification(@NonNull MethodCall call, Result result) throws Exception {

        Map<String, Object> pushData = call.arguments();
        NotificationModel notificationModel = new NotificationModel().fromMap(pushData);

        if(notificationModel == null){
            throw new AwesomeNotificationException("Invalid parameters");
        }

        if(!isNotificationEnabled(applicationContext, null)){
            throw new AwesomeNotificationException("Notifications are disabled");
        }

        if(!isChannelEnabled(applicationContext, notificationModel.content.channelKey)){
            throw new AwesomeNotificationException("The notification channel '"+ notificationModel.content.channelKey+"' does not exist or is disabled");
        }

        if(notificationModel.schedule == null){

            NotificationSender.send(
                    applicationContext,
                    NotificationSource.Local,
                    notificationModel
            );
        }
        else {

            NotificationScheduler.schedule(
                    applicationContext,
                    NotificationSource.Local,
                    notificationModel
            );
        }

        result.success(true);
    }

    public static Boolean isNotificationEnabled(Context context, String channelKey){
        boolean isGloballyEnable = NotificationManagerCompat.from(context).areNotificationsEnabled();
        if (isGloballyEnable && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if(!StringUtils.isNullOrEmpty(channelKey)) {
                return isChannelEnabled(context, channelKey);
            }
        }
        return isGloballyEnable;
    }

    @NonNull
    public static Boolean isChannelEnabled(Context context, String channelKey){

        if(StringUtils.isNullOrEmpty(channelKey)){
            return false;
        }

        NotificationChannelModel channelModel = ChannelManager.getChannelByKey(context, channelKey);

        if(channelModel == null){
            return false;
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel androidChannel = ChannelManager.getAndroidChannel(context, channelModel);
            return (androidChannel != null && androidChannel.getImportance() != NotificationManager.IMPORTANCE_NONE);
        }

        return true;
    }

    @SuppressWarnings("unchecked")
    private void channelMethodInitialize(@NonNull MethodCall call, Result result) throws Exception {
        List<Object> channelsData;

        // Avoid double initialization
        if(isInitialized) {
            result.success(false);
            return;
        }

        Map<String, Object> platformParameters = call.arguments();

        Object callbackDartObj = platformParameters.get(Definitions.DART_BG_HANDLE);
        Object object = platformParameters.get(Definitions.INITIALIZE_DEBUG_MODE);
        String defaultIconPath = (String) platformParameters.get(Definitions.INITIALIZE_DEFAULT_ICON);
        channelsData = (List<Object>) platformParameters.get(Definitions.INITIALIZE_CHANNELS);

        debug = object != null && (boolean) object;
        long dartCallback = callbackDartObj == null ? 0L :(Long) callbackDartObj;

        setDefaultConfigurations(
            applicationContext,
            defaultIconPath,
            dartCallback,
            channelsData
        );

        if(AwesomeNotificationsPlugin.debug)
            Log.d(TAG, "Awesome Notifications service initialized");

        if(AwesomeNotificationsPlugin.debug && dartCallback == 0L)
            Log.e(TAG, "Attention: there is no valid dart reverse method to receive silent action data");

        isInitialized = true;
        result.success(true);
    }

    @SuppressWarnings("unchecked")
    private void channelMethodSetActionHandle(@NonNull MethodCall call, Result result) throws Exception {
        Map<String, Object> platformParameters = call.arguments();
        Object callbackActionObj = platformParameters.get(ACTION_HANDLE);

        long silentCallback = callbackActionObj == null ? 0L : (Long) callbackActionObj;

        setActionHandleDefaults(
            applicationContext,
            silentCallback
        );

        if(AwesomeNotificationsPlugin.debug && silentCallback == 0L){
            Log.e(TAG, "Attention: there is no valid static method to receive action data");
            result.success(false);
        }
        else {
            result.success(true);
        }
    }

    private boolean setDefaultConfigurations(Context context, String defaultIcon, long dartCallback, List<Object> channelsData) throws Exception {

        setDefaults(context, defaultIcon, dartCallback);
        setChannels(context, channelsData);

        recoverNotificationCreated(context);
        recoverNotificationDisplayed(context);
        recoverNotificationDismissed(context);

        captureNotificationActionOnLaunch();
        return true;
    }

    private void setChannels(Context context, List<Object> channelsData) throws Exception {
        if(ListUtils.isNullOrEmpty(channelsData)) return;

        List<NotificationChannelModel> channels = new ArrayList<>();
        boolean forceUpdate = false;

        for(Object channelDataObject : channelsData){
            if(channelDataObject instanceof Map<?,?>){
                @SuppressWarnings("unchecked")
                Map<String, Object> channelData = (Map<String, Object>) channelDataObject;
                NotificationChannelModel channelModel = new NotificationChannelModel().fromMap(channelData);
                forceUpdate = BooleanUtils.getValue((Boolean) channelData.get(Definitions.CHANNEL_FORCE_UPDATE));

                if(channelModel != null){
                    channels.add(channelModel);
                } else {
                    throw new AwesomeNotificationException("Invalid channel: "+JsonUtils.toJson(channelData));
                }
            }
        }

        for(NotificationChannelModel channelModel : channels){
            ChannelManager.saveChannel(context, channelModel, forceUpdate);
        }

        ChannelManager.commitChanges(context);
    }

    private void setDefaults(Context context, String defaultIcon, long dartCallbackHandle) {

        if (MediaUtils.getMediaSourceType(defaultIcon) != MediaSource.Resource) {
            defaultIcon = null;
        }

        DefaultsManager.saveDefault(context, new DefaultsModel(defaultIcon, dartCallbackHandle));
        DefaultsManager.commitChanges(context);
    }

    private void setActionHandleDefaults(Context context, long silentCallbackHandle) {
        DefaultsModel defaults = DefaultsManager.getDefaultByKey(context);
        defaults.silentDataCallback = silentCallbackHandle;
        DefaultsManager.saveDefault(context, defaults);
        DefaultsManager.commitChanges(context);
    }

    private static boolean hasInitialized = false;
    public static NotificationLifeCycle getApplicationLifeCycle(){

        Lifecycle.State state = ProcessLifecycleOwner.get().getLifecycle().getCurrentState();

        switch (state){
            case CREATED:
                appLifeCycle = hasInitialized ?
                        NotificationLifeCycle.Background :
                        NotificationLifeCycle.AppKilled;
                break;
            case INITIALIZED:
            case STARTED:
                hasInitialized = true;
                appLifeCycle = NotificationLifeCycle.Background;
                break;
            case RESUMED:
                hasInitialized = true;
                appLifeCycle = NotificationLifeCycle.Foreground;
                break;
            case DESTROYED:
                hasInitialized = false;
                appLifeCycle = NotificationLifeCycle.AppKilled;
                break;
        }

        return appLifeCycle;
    }

    private void captureNotificationActionOnLaunch() {

        if(initialActivity == null){ return; }

        Intent intent = initialActivity.getIntent();
        if(intent == null){ return; }

        String actionName = intent.getAction();
        if(actionName != null){

            Boolean isStandardAction = Definitions.SELECT_NOTIFICATION.equals(actionName);
            Boolean isButtonAction = actionName.startsWith(Definitions.NOTIFICATION_BUTTON_ACTION_PREFIX);

            if(isStandardAction || isButtonAction){
                receiveNotificationAction(intent, NotificationLifeCycle.AppKilled);
            }
        }
    }

    @NonNull
    private Boolean receiveNotificationAction(Intent intent) {
        return receiveNotificationAction(intent, getApplicationLifeCycle());
    }

    @NonNull
    private Boolean receiveNotificationAction(Intent intent, NotificationLifeCycle appLifeCycle) {

        NotificationModel notificationModel = NotificationBuilder.buildNotificationModelFromIntent(intent);
        ActionReceived actionModel = NotificationBuilder.buildNotificationActionFromNotificationModel(applicationContext, notificationModel, intent);
        NotificationBuilder.finalizeNotificationIntent(applicationContext, notificationModel, intent);

        if(NotificationBuilder.notificationIntentDisabledAction(intent)){
            return true;
        }

        if (actionModel != null) {

            actionModel.actionDate = DateUtils.getUTCDate();
            actionModel.actionLifeCycle = appLifeCycle;

            Map<String, Object> returnObject = actionModel.toMap();

            pluginChannel.invokeMethod(Definitions.CHANNEL_METHOD_RECEIVED_ACTION, returnObject);

            if(AwesomeNotificationsPlugin.debug)
                Log.d(TAG, "Notification action received");
        }
        return true;
    }
}
