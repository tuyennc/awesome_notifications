package me.carda.awesome_notifications.notifications.models;

import android.content.Context;

import java.util.Map;
import java.util.HashMap;

import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.enumerators.NotificationActionType;
import me.carda.awesome_notifications.utils.StringUtils;
import me.carda.awesome_notifications.notifications.exceptions.AwesomeNotificationException;

public class NotificationButtonModel extends Model {

    public String key;
    public String icon;
    public String label;
    public Boolean enabled;
    public Boolean autoDismissible;
    public Boolean requireInputText;
    public NotificationActionType notificationActionType;

    public NotificationButtonModel(){}

    @Override
    public NotificationButtonModel fromMap(Map<String, Object> arguments) {

        key   = getValueOrDefault(arguments, Definitions.NOTIFICATION_BUTTON_KEY, String.class);
        icon  = getValueOrDefault(arguments, Definitions.NOTIFICATION_BUTTON_ICON, String.class);
        label = getValueOrDefault(arguments, Definitions.NOTIFICATION_BUTTON_LABEL, String.class);

        enabled = getValueOrDefault(arguments, Definitions.NOTIFICATION_ENABLED, Boolean.class);
        autoDismissible = getValueOrDefault(arguments, Definitions.NOTIFICATION_AUTO_DISMISSIBLE, Boolean.class);
        requireInputText = getValueOrDefault(arguments, Definitions.NOTIFICATION_REQUIRE_INPUT_TEXT, Boolean.class);

        notificationActionType = getEnumValueOrDefault(arguments, Definitions.NOTIFICATION_ACTION_TYPE,
                NotificationActionType.class, NotificationActionType.values());

        return this;
    }

    @Override
    public Map<String, Object> toMap() {
        Map<String, Object> returnedObject = new HashMap<>();

        returnedObject.put(Definitions.NOTIFICATION_BUTTON_KEY, key);
        returnedObject.put(Definitions.NOTIFICATION_BUTTON_ICON, icon);
        returnedObject.put(Definitions.NOTIFICATION_BUTTON_LABEL, label);

        returnedObject.put(Definitions.NOTIFICATION_ENABLED, enabled);
        returnedObject.put(Definitions.NOTIFICATION_AUTO_DISMISSIBLE, autoDismissible);
        returnedObject.put(Definitions.NOTIFICATION_REQUIRE_INPUT_TEXT, requireInputText);

        returnedObject.put(Definitions.NOTIFICATION_ACTION_TYPE,
            this.notificationActionType != null ? this.notificationActionType.toString() : NotificationActionType.BringToForeground.toString());

        return returnedObject;
    }

    @Override
    public String toJson() {
        return templateToJson();
    }

    @Override
    public NotificationButtonModel fromJson(String json){
        return (NotificationButtonModel) super.templateFromJson(json);
    }

    @Override
    public void validate(Context context) throws AwesomeNotificationException {
        if(StringUtils.isNullOrEmpty(key))
            throw new AwesomeNotificationException("Button action key cannot be null or empty");

        if(StringUtils.isNullOrEmpty(label))
            throw new AwesomeNotificationException("Button label cannot be null or empty");
    }
}
