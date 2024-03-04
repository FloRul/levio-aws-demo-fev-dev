package com.levio.awsdemo.emailrequestpreprocessor.service;

import jakarta.mail.MessagingException;
import jakarta.mail.Session;
import jakarta.mail.internet.MimeMessage;
import jakarta.mail.internet.MimeMultipart;
import software.amazon.awssdk.core.ResponseBytes;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectResponse;

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

public class S3Service {

    private final S3Client s3 = S3Client.builder()
            .region(Region.US_EAST_1)
            .build();

    public String getEmailBodyFromEmailObject(String bucketName, String keyName) throws MessagingException, IOException {
        GetObjectRequest objectRequest = GetObjectRequest
                .builder()
                .key(keyName)
                .bucket(bucketName)
                .build();

        ResponseBytes<GetObjectResponse> objectBytes = s3.getObjectAsBytes(objectRequest);
        System.out.println(new String(objectBytes.asByteArray()));
        InputStream inputStream = objectBytes.asInputStream();

        Properties props = new Properties();
        Session session = Session.getDefaultInstance(props, null);

        MimeMessage message = new MimeMessage(session, inputStream);

        Object content = message.getContent();

        return getEmailBodyFromContent(content);
    }

    private String getEmailBodyFromContent(Object content) throws MessagingException, IOException {
        if (content instanceof String) {
            return (String) content;
        } else if (content instanceof MimeMultipart multipart) {
            return getEmailBodyFromContent(multipart.getBodyPart(0).getContent());
        }
        return null;
    }
}
