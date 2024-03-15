package com.levio.awsdemo.attachmentsaver.util;

import jakarta.mail.MessagingException;
import jakarta.mail.Multipart;
import jakarta.mail.Part;
import jakarta.mail.internet.MimeMessage;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class EmailUtils {
    public static List<Part> extractAttachments(MimeMessage message) throws MessagingException, IOException {
        Object content = message.getContent();

        List<Part> attachments = new ArrayList<>();

        if (content instanceof Multipart multipart) {
            for (int i = 0; i < multipart.getCount(); i++) {
                Part part = multipart.getBodyPart(i);
                if (Part.ATTACHMENT.equalsIgnoreCase(part.getDisposition())) {
                    attachments.add(part);
                }
            }
        }
        return attachments;
    }
}
