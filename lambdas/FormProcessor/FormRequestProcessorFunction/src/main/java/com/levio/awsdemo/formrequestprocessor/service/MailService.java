package com.levio.awsdemo.formrequestprocessor.service;

import jakarta.mail.MessagingException;
import jakarta.mail.Session;
import jakarta.mail.internet.MimeMessage;

import java.io.InputStream;
import java.util.Properties;

public class MailService {

    public MimeMessage getMimeMessage(InputStream inputStream) throws MessagingException {
        Properties props = new Properties();
        Session session = Session.getDefaultInstance(props, null);

        return new MimeMessage(session, inputStream);
    }
}
