package com.levio.awsdemo.formrequestpreprocessor;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.models.s3.S3EventNotification;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.joda.JodaModule;
import com.levio.awsdemo.formrequestpreprocessor.service.FormFillRequestDTO;
import com.levio.awsdemo.formrequestpreprocessor.service.SqsProducerService;

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

        input.getRecords().forEach(s3EventNotificationRecord -> {
            var key = s3EventNotificationRecord.getS3().getObject().getKey();
            var bucketName = s3EventNotificationRecord.getS3().getBucket().getName();
            String emailId = extractEmailId(key);
            var emailS3URI = "s3://" + bucketName + "/" + extractFormKey(key) + "/email/" + emailId;
            var emailAttachmentS3URI = "s3://" + bucketName + "/" + key;
            var formFillRequest = new FormFillRequestDTO(emailId, emailS3URI, emailAttachmentS3URI);
            System.out.print(formFillRequest);
            sqsProducerService.send(formFillRequest);
        });

        return null;
    }

    private String extractEmailId(String key) {
        int lastDotIndex = key.lastIndexOf('.');
        int lastSlashIndex = key.lastIndexOf('/', lastDotIndex - 1);
        return key.substring(lastSlashIndex + 1, lastDotIndex);
    }

    private String extractFormKey(String key) {
        return key.split("/")[0];
    }


}
