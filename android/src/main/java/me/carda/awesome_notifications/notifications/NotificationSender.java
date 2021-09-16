package me.carda.awesome_notifications.notifications;

import android.annotation.SuppressLint;
import android.app.Notification;
import android.app.NotificationManager;
import android.content.Context;
import android.os.AsyncTask;
import android.os.Build;
import android.service.notification.StatusBarNotification;

import java.util.List;

import androidx.annotation.RequiresApi;
import androidx.core.app.NotificationManagerCompat;

import me.carda.awesome_notifications.AwesomeNotificationsPlugin;
import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.enumerators.NotificationLifeCycle;
import me.carda.awesome_notifications.notifications.enumerators.NotificationSource;
import me.carda.awesome_notifications.notifications.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.notifications.managers.CreatedManager;
import me.carda.awesome_notifications.notifications.managers.DismissedManager;
import me.carda.awesome_notifications.notifications.managers.DisplayedManager;
import me.carda.awesome_notifications.notifications.models.NotificationModel;
import me.carda.awesome_notifications.notifications.models.returnedData.ActionReceived;
import me.carda.awesome_notifications.notifications.models.returnedData.NotificationReceived;
import me.carda.awesome_notifications.utils.DateUtils;
import me.carda.awesome_notifications.utils.StringUtils;

public class NotificationSender extends AsyncTask<String, Void, NotificationReceived> {

    public static String TAG = "NotificationSender";

    @SuppressLint("StaticFieldLeak")
    private Context context;
    private NotificationSource createdSource;
    private NotificationLifeCycle appLifeCycle;
    private NotificationModel notificationModel;

    private Boolean created = false;
    private Boolean displayed = false;

    public static void send(
            Context context,
            NotificationModel notificationModel
    ) throws AwesomeNotificationException {

        NotificationSender.send(
                context,
                notificationModel.content.createdSource,
                notificationModel
        );
    }

    public static void send(
        Context context,
        NotificationSource createdSource,
        NotificationModel notificationModel
    ) throws AwesomeNotificationException {

        if (notificationModel == null ){
            throw new AwesomeNotificationException("Notification cannot be empty or null");
        }

        NotificationLifeCycle appLifeCycle;
        if(AwesomeNotificationsPlugin.appLifeCycle != NotificationLifeCycle.AppKilled){
            appLifeCycle = AwesomeNotificationsPlugin.getApplicationLifeCycle();
        }
        else {
            appLifeCycle = NotificationLifeCycle.AppKilled;
        }

        notificationModel.validate(context);

        new NotificationSender(
            context,
            appLifeCycle,
            createdSource,
                notificationModel
        ).execute();
    }

    private NotificationSender(
            Context context,
            NotificationLifeCycle appLifeCycle,
            NotificationSource createdSource,
            NotificationModel notificationModel
    ){
        this.context = context;
        this.createdSource = createdSource;
        this.appLifeCycle = appLifeCycle;
        this.notificationModel = notificationModel;
    }

    /// AsyncTask METHODS BEGIN *********************************

    @Override
    protected NotificationReceived doInBackground(String... parameters) {

        try {

            if (notificationModel != null){

                NotificationReceived receivedNotification = null;

                if(createdSource == null)
                    createdSource = NotificationSource.Local;

                if(notificationModel.content.createdLifeCycle == null){
                    notificationModel.content.createdDate = DateUtils.getUTCDate();
                    notificationModel.content.createdSource = createdSource;
                    notificationModel.content.createdLifeCycle = appLifeCycle;
                    created = true;
                }

                if (
                    !StringUtils.isNullOrEmpty(notificationModel.content.title) ||
                    !StringUtils.isNullOrEmpty(notificationModel.content.body)
                ){

                    notificationModel.content.displayedLifeCycle = appLifeCycle;
                    notificationModel.content.displayedDate = DateUtils.getUTCDate();

                    notificationModel = showNotification(context, notificationModel);

                    // Only save DisplayedMethods if pushNotification was created and displayed successfully
                    if(notificationModel != null){
                        displayed = true;

                        receivedNotification = new NotificationReceived(notificationModel.content);

                        receivedNotification.displayedLifeCycle = receivedNotification.displayedLifeCycle == null ?
                                appLifeCycle : receivedNotification.displayedLifeCycle;
                    }

                } else {
                    receivedNotification = new NotificationReceived(notificationModel.content);
                }

                return receivedNotification;
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        notificationModel = null;
        return null;
    }

    @Override
    protected void onPostExecute(NotificationReceived receivedNotification) {

        // Only broadcast if pushNotification is valid
        if(notificationModel != null){

            if(created){
                CreatedManager.saveCreated(context, receivedNotification);
                CreatedManager.commitChanges(context);
                NotificationGateKeeper.broadcastNotificationCreated(
                        context,
                        receivedNotification
                );
            }

            if(displayed){
                DisplayedManager.saveDisplayed(context, receivedNotification);
                DisplayedManager.commitChanges(context);
                NotificationGateKeeper.broadcastNotificationDisplayed(
                    context,
                    receivedNotification
                );
            }
        }
    }

    /// AsyncTask METHODS END *********************************

    private NotificationModel _buildSummaryGroupNotification(NotificationModel original){

        NotificationModel pushSummary = notificationModel.ClonePush();
        pushSummary.content.generateNextRandomId();
        pushSummary.groupSummary = true;

        return  pushSummary;
    }

    private boolean executionLocked = false;
    public NotificationModel showNotification(Context context, NotificationModel notificationModel) {

        try {

            NotificationLifeCycle lifeCycle = AwesomeNotificationsPlugin.getApplicationLifeCycle();

            if(
                (lifeCycle == NotificationLifeCycle.AppKilled) ||
                (lifeCycle == NotificationLifeCycle.Foreground && notificationModel.content.displayOnForeground) ||
                (lifeCycle == NotificationLifeCycle.Background && notificationModel.content.displayOnBackground)
            ){
//                if(notificationModel.content.notificationLayout == NotificationLayout.Messaging){
//                    if(!NotificationBuilder.builderLockWait()){
//                        throw new AwesomeNotificationException("MessagingLayout was not available to use");
//                    }
//                    executionLocked = true;
//                }

                Notification notification = NotificationBuilder.createNotification(context, notificationModel);

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);

                    if(notificationModel.groupSummary){
                        NotificationModel pushSummary = _buildSummaryGroupNotification(notificationModel);
                        Notification summaryNotification = NotificationBuilder.createNotification(context, pushSummary, true);
                        notificationManager.notify(pushSummary.content.id, summaryNotification);
                    }

                    notificationManager.notify(notificationModel.content.id, notification);
                }
                else {
                    NotificationManagerCompat notificationManagerCompat = NotificationBuilder.getAndroidNotificationManager(context);
                    notificationManagerCompat.notify(notificationModel.content.id.toString(), notificationModel.content.id, notification);
                }

                if(executionLocked){
                    executionLocked = false;
                    NotificationBuilder.builderUnlockWait();
                }
            }

            return notificationModel;

        } catch (Exception e) {
            e.printStackTrace();

            if(executionLocked){
                executionLocked = false;
                NotificationBuilder.builderUnlockWait();
            }
        }
        return null;
    }

    public static void dismissNotification(Context context, Integer id) {
        if(context != null){

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                NotificationManagerCompat notificationManager = NotificationBuilder.getAndroidNotificationManager(context);

                // Necessary to remove the first notification marked as group description;
                dismissOrphanGroupDescription(context, notificationManager, id);

                notificationManager.cancel(id.toString(), id);
                notificationManager.cancel(id);
            }
            else {
                NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
                notificationManager.cancel(id.toString(), id);
                notificationManager.cancel(id);
            }
        }
    }

    public static void dismissNotificationsByChannelKey(Context context, String channelKey) {
        List<Notification> notificationList = NotificationBuilder.getAllAndroidActiveNotifications(context, channelKey);

        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.KITKAT) {
            for(Notification notification : notificationList){
                int id = notification.extras.getInt(Definitions.NOTIFICATION_ID);
                NotificationSender.dismissNotification(context, id);
            }
        }
    }

    public static boolean dismissAllNotifications(Context context) {

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationManagerCompat notificationManager = NotificationBuilder.getAndroidNotificationManager(context);
            notificationManager.cancelAll();
        }
        else {
            NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
            notificationManager.cancelAll();
        }

        return true;
    }

    public static void sendDismissedNotification(Context context, ActionReceived actionReceived){

        if (actionReceived != null){

            actionReceived.dismissedLifeCycle = AwesomeNotificationsPlugin.getApplicationLifeCycle();
            actionReceived.dismissedDate = DateUtils.getUTCDate();

            DismissedManager.saveDismissed(context, actionReceived);
            DismissedManager.commitChanges(context);

            try {

                NotificationGateKeeper.broadcastNotificationDismissed(
                    context,
                    actionReceived
                );

            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    /// fix to canceling a automatic generated summary notification
    /// https://github.com/rafaelsetragni/awesome_notifications/issues/69
    @RequiresApi(api = Build.VERSION_CODES.M)
    private static void dismissOrphanGroupDescription(Context context, NotificationManagerCompat notificationManager, int id){

        NotificationManager manager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
        StatusBarNotification[] currentActiveNotifications = manager.getActiveNotifications();

        if(currentActiveNotifications != null)
            for (StatusBarNotification activeNotification : currentActiveNotifications) {
                if(activeNotification.getId() == id){
                    String groupKey = activeNotification.getGroupKey();
                    if(!StringUtils.isNullOrEmpty(groupKey)) {
                        int otherId = 0, count = 0;
                        for (StatusBarNotification otherNotification : currentActiveNotifications) {
                            if(otherNotification.getGroupKey().equals(groupKey)) {
                                count++;
                                if(otherNotification.getId() != id)
                                    otherId = otherNotification.getId();
                            }
                        }
                        if(count <= 2){
                            notificationManager.cancel(Integer.toString(otherId), otherId);
                            notificationManager.cancel(otherId);
                            break;
                        }
                    }
                    break;
                }
            }
    }

}
