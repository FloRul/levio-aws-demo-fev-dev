package com.levio.awsdemo.transcriptionformatter;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.models.s3.S3EventNotification;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.joda.JodaModule;
import com.levio.awsdemo.transcriptionformatter.service.S3Service;
import com.levio.awsdemo.transcriptionformatter.service.TranscribeService;

public class App implements RequestHandler<S3EventNotification, Void> {
    private final ObjectMapper objectMapper = new ObjectMapper().registerModule(new JodaModule());

    private final S3Service s3Service;

    private final TranscribeService transcribeService;

    public App() {
        this.s3Service = new S3Service();
        this.transcribeService = new TranscribeService();
    }

    public App(S3Service s3Service, TranscribeService transcribeService) {
        this.s3Service = s3Service;
        this.transcribeService = transcribeService;
    }

    public Void handleRequest(final S3EventNotification input, final Context context) {
        try {
            String json = objectMapper.writeValueAsString(input);
            System.out.println(json);
        } catch (JsonProcessingException e) {
            throw new RuntimeException(e);
        }

        input.getRecords().forEach(s3EventNotificationRecord -> {
            String transcription = s3Service.getFile(s3EventNotificationRecord.getS3().getObject().getKey());
            String transcriptionFormatted = transcribeService.format(transcription);
            String key = s3EventNotificationRecord.getS3().getObject().getKey().replace(".json", ".txt");
            s3Service.saveFile(key, transcriptionFormatted.getBytes());
        });

        return null;
    }

}
