package com.levio.awsdemo.resumerequestpreprocessor.service;

import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.SendMessageRequest;

public class SqsProducerService {
    private static final String QUEUE_URL = System.getenv("QUEUE_URL");
    private final SqsClient sqs = SqsClient.builder()
            .region(Region.US_EAST_1)
            .build();

    public void send(String emailId) {
        SendMessageRequest sendMessageRequest = SendMessageRequest.builder()
                .queueUrl(QUEUE_URL)
                .messageBody(emailId)
                .messageGroupId(emailId)
                .messageDeduplicationId(emailId)
                .build();

        sqs.sendMessage(sendMessageRequest);
    }
}
