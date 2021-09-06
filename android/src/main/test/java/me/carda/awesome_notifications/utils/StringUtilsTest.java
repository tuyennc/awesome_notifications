package android.src.main.test.java.me.carda.awesome_notifications.utils;

import com.google.common.reflect.TypeToken;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;

import me.carda.push_notifications.notifications.models.NotificationChannelModel;

import static org.junit.Assert.*;

public class StringUtilsTest {

    @Before
    public void setUp() throws Exception {
    }

    @After
    public void tearDown() throws Exception {
    }

    @Test
    public void md5Digest() {
        String reference = "teste1";
        String digested1 = StringUtils.digestString(reference);
        String digested2 = StringUtils.digestString2(reference);

        assertEquals(digested1, digested2);
    }
}