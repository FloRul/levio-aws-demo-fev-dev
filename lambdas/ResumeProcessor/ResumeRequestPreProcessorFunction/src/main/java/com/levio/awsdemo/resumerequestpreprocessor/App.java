package com.levio.awsdemo.resumerequestpreprocessor;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.models.s3.S3EventNotification;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.joda.JodaModule;
import com.levio.awsdemo.resumerequestpreprocessor.service.S3Service;
import com.levio.awsdemo.resumerequestpreprocessor.service.SqsProducerService;
import software.amazon.awssdk.services.sqs.model.MessageAttributeValue;

import java.util.Map;

public class App implements RequestHandler<S3EventNotification, Void> {
    private final ObjectMapper objectMapper = new ObjectMapper().registerModule(new JodaModule());

    private final SqsProducerService sqsProducerService;

    private final S3Service s3Service;

    public App() {
        this.sqsProducerService = new SqsProducerService();
        this.s3Service = new S3Service();
    }

    public App(SqsProducerService sqsProducerService, S3Service s3Service) {
        this.sqsProducerService = sqsProducerService;
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
            String key = s3EventNotificationRecord.getS3().getObject().getKey();
            String keyId = extractKeyIdFromKey(key);
            String email = s3Service.getEmailMetadata("resume/attachment/" + keyId + ".mp3");
            Map<String, MessageAttributeValue> messageAttributes = null;
            if (email != null) {
                messageAttributes = Map.of(
                        "Email", MessageAttributeValue.builder()
                                .dataType("String")
                                .stringValue(email)
                                .build()
                );
            }
            sqsProducerService.send(keyId, messageAttributes);
        });

        return null;
    }

    private String extractKeyIdFromKey(String key) {
        int lastDotIndex = key.lastIndexOf('.');
        int lastSlashIndex = key.lastIndexOf('/', lastDotIndex - 1);
        return key.substring(lastSlashIndex + 1, lastDotIndex);
    }
}
