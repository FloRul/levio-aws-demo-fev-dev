package com.levio.awsdemo.attachmentsaver;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.models.s3.S3EventNotification;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.joda.JodaModule;
import com.levio.awsdemo.attachmentsaver.service.S3Service;

import jakarta.mail.MessagingException;
import jakarta.mail.Part;
import software.amazon.awssdk.services.s3.model.PutObjectResponse;

public class App implements RequestHandler<S3EventNotification, String> {

    private final ObjectMapper objectMapper = new ObjectMapper().registerModule(new JodaModule());

    private final S3Service s3Service;

    public App() {
        this.s3Service = new S3Service();
    }

    public App(S3Service s3Service) {
        this.s3Service = s3Service;
    }

    public String handleRequest(final S3EventNotification input, final Context context) {
        List<PutObjectResponse> responses = new ArrayList<>();

        input.getRecords().forEach(s3EventNotificationRecord -> {
            try {
                List<Part> attachments = s3Service.getAttachments(s3EventNotificationRecord.getS3());
                attachments.forEach(part -> {
                    try {
                        var response = s3Service.saveAttachment(part, s3EventNotificationRecord.getS3());
                        responses.add(response);
                    } catch (MessagingException | IOException e) {
                        throw new RuntimeException(e);
                    }
                });
            } catch (MessagingException | IOException e) {
                throw new RuntimeException(e);
            }
        });

        try {
            var response = objectMapper.writeValueAsString(
                new Response(200, responses.stream().map(PutObjectResponse::toString).toList())
            );
            System.out.println(response);
            return response;

        } catch (JsonProcessingException e) {
            e.printStackTrace();
            new Response(400, List.of("Error processing request"));
        }
        return null;
    }
}


class Response {
    private int statusCode;
    private List<String> responses;

    public Response(int statusCode, List<String> responses) {
        this.statusCode = statusCode;
        this.responses = responses;
    }

    public int getStatusCode() {
        return statusCode;
    }

    public void setStatusCode(int statusCode) {
        this.statusCode = statusCode;
    }

    public List<String> getResponses() {
        return responses;
    }

    public void setResponses(List<String> responses) {
        this.responses = responses;
    }
}