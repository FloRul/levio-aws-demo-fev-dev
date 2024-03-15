package com.levio.awsdemo.transcription;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.models.s3.S3EventNotification;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.joda.JodaModule;
import com.levio.awsdemo.transcription.service.TranscribeService;

public class App implements RequestHandler<S3EventNotification, Void> {

    private final ObjectMapper objectMapper = new ObjectMapper().registerModule(new JodaModule());

    private final TranscribeService transcribeService;

    public App(TranscribeService transcribeService) {
        this.transcribeService = transcribeService;
    }

    public App() {
        this.transcribeService = new TranscribeService();
    }

    public Void handleRequest(final S3EventNotification input, final Context context) {
        System.out.println(input);
        try {
            String json = objectMapper.writeValueAsString(input);
            System.out.println(json);
            input.getRecords().forEach(s3EventNotificationRecord -> transcribeService.transcribe(s3EventNotificationRecord.getS3()));

        } catch (JsonProcessingException e) {
            throw new RuntimeException(e);
        }
        return null;
    }
}
