package com.levio.awsdemo.formrequestpreprocessor.service;

import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.SendMessageRequest;

import java.util.UUID;

public class SqsProducerService {
    private static final String QUEUE_URL = System.getenv("QUEUE_URL");
    private final SqsClient sqs = SqsClient.builder()
            .region(Region.US_EAST_1)
            .build();

    public void send(FormFillRequestDTO formFillRequest) {
        SendMessageRequest sendMessageRequest = SendMessageRequest.builder()
                .queueUrl(QUEUE_URL)
                .messageBody(formFillRequest.toJson())
                .messageGroupId(UUID.randomUUID().toString())
                .messageDeduplicationId(UUID.randomUUID().toString())
                .build();

        sqs.sendMessage(sendMessageRequest);
    }
}
