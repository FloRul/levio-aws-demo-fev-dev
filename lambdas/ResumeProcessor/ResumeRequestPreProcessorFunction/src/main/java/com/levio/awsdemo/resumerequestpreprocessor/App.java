package com.levio.awsdemo.resumerequestpreprocessor;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.models.s3.S3EventNotification;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.joda.JodaModule;
import com.levio.awsdemo.resumerequestpreprocessor.service.SqsProducerService;

public class App implements RequestHandler<S3EventNotification, Void> {
    private final ObjectMapper objectMapper = new ObjectMapper().registerModule(new JodaModule());

    private final SqsProducerService sqsProducerService;

    public App() {
        this.sqsProducerService = new SqsProducerService();
    }

    public App(SqsProducerService sqsProducerService) {
        this.sqsProducerService = sqsProducerService;
    }

    public Void handleRequest(final S3EventNotification input, final Context context) {
        try {
            String json = objectMapper.writeValueAsString(input);
            System.out.println(json);
        } catch (JsonProcessingException e) {
            throw new RuntimeException(e);
        }

        input.getRecords().forEach(s3EventNotificationRecord ->
                sqsProducerService.send(extractEmailId(s3EventNotificationRecord.getS3().getObject().getKey()))
        );

        return null;
    }

    private String extractEmailId(String key) {
        int lastDotIndex = key.lastIndexOf('.');
        int lastSlashIndex = key.lastIndexOf('/', lastDotIndex - 1);
        return key.substring(lastSlashIndex + 1, lastDotIndex);
    }
}
