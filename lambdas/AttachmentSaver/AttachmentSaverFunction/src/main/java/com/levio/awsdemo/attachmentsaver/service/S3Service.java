package com.levio.awsdemo.attachmentsaver.service;

import java.io.IOException;
import java.io.InputStream;
import java.util.List;
import java.util.Properties;

import com.amazonaws.services.lambda.runtime.events.models.s3.S3EventNotification;
import com.levio.awsdemo.attachmentsaver.util.EmailUtils;

import jakarta.mail.MessagingException;
import jakarta.mail.Part;
import jakarta.mail.Session;
import jakarta.mail.internet.MimeMessage;
import software.amazon.awssdk.core.ResponseBytes;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectResponse;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectResponse;

public class S3Service {

    private final S3Client s3 = S3Client.builder()
            .region(Region.US_EAST_1)
            .build();

    public List<Part> getAttachments(S3EventNotification.S3Entity s3Entity) throws MessagingException, IOException {
        GetObjectRequest objectRequest = GetObjectRequest
                .builder()
                .key(s3Entity.getObject().getKey())
                .bucket(s3Entity.getBucket().getName())
                .build();

        ResponseBytes<GetObjectResponse> objectBytes = s3.getObjectAsBytes(objectRequest);
        System.out.println(new String(objectBytes.asByteArray()));
        InputStream inputStream = objectBytes.asInputStream();

        Properties props = new Properties();
        Session session = Session.getDefaultInstance(props, null);

        MimeMessage message = new MimeMessage(session, inputStream);

        return EmailUtils.extractAttachments(message);
    }

    public PutObjectResponse saveAttachment(Part part, S3EventNotification.S3Entity s3Entity) throws MessagingException, IOException {
        try (InputStream inputStream = part.getInputStream()) {
            String key = getKey(part, s3Entity);
            var attachment =  RequestBody.fromBytes(inputStream.readAllBytes());
            var putRequest =  PutObjectRequest.builder()
                .bucket(s3Entity.getBucket().getName())
                .key(key)
                .build();
            PutObjectResponse objectResponse = s3.putObject(putRequest, attachment);
            if (objectResponse.sdkHttpResponse().isSuccessful()) {
                System.out.println("File " + key + " created" );
            }

            return objectResponse;
        }
    }

    private String getKey(Part part, S3EventNotification.S3Entity s3Entity) throws MessagingException {
        return extractKeyPath(s3Entity.getObject().getKey()) +
                "attachment/" +
                getEmailId(s3Entity.getObject().getKey()) +
                extractFileExtension(part.getFileName());
    }

    private String extractFileExtension(String fileName) {
        return "." + fileName.substring(fileName.lastIndexOf(".") + 1);
    }

    private String extractKeyPath(String path) {
        int lastIndex = path.lastIndexOf("/");
        lastIndex = path.substring(0, lastIndex).lastIndexOf("/");
        return path.substring(0, lastIndex) + "/";
    }

    private String getEmailId(String path) {
        String[] parts = path.split("/");
        return parts[parts.length - 1];
    }

}
