package com.levio.awsdemo.attachmentsaver;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.models.s3.S3EventNotification;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.joda.JodaModule;
import com.levio.awsdemo.attachmentsaver.service.S3Service;
import jakarta.mail.MessagingException;
import jakarta.mail.Part;

import java.io.IOException;
import java.util.List;

public class App implements RequestHandler<S3EventNotification, Void> {

    private final ObjectMapper objectMapper = new ObjectMapper().registerModule(new JodaModule());

    private final S3Service s3Service;

    public App() {
        this.s3Service = new S3Service();
    }

    public App(S3Service s3Service) {
        this.s3Service = s3Service;
    }

    public Void handleRequest(final S3EventNotification input, final Context context) {
        try {
            String json = objectMapper.writeValueAsString(input);
            System.out.println(json);
        } catch (JsonProcessingException e) {
            throw new RuntimeException(e);
        }

        input.getRecords().forEach(s3EventNotificationRecord -> {
            try {
                List<Part> attachments = s3Service.getAttachments(s3EventNotificationRecord.getS3());
                attachments.forEach(part -> {
                    try {
                        s3Service.saveAttachment(part, s3EventNotificationRecord.getS3());
                    } catch (MessagingException | IOException e) {
                        throw new RuntimeException(e);
                    }
                });
            } catch (MessagingException | IOException e) {
                throw new RuntimeException(e);
            }
        });

        return null;
    }
}
