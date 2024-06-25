package com.levio.awsdemo.resumerequestpreprocessor.service;

import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.MessageAttributeValue;
import software.amazon.awssdk.services.sqs.model.SendMessageRequest;

import java.util.Map;

public class SqsProducerService {
    private static final String QUEUE_URL = System.getenv("QUEUE_URL");
    private final SqsClient sqs = SqsClient.builder()
            .region(Region.US_EAST_1)
            .build();

    public void send(String keyId, Map<String, MessageAttributeValue> messageAttributes) {
        SendMessageRequest sendMessageRequest = SendMessageRequest.builder()
                .queueUrl(QUEUE_URL)
                .messageBody(keyId)
                .messageGroupId(keyId)
                .messageDeduplicationId(keyId)
                .messageAttributes(messageAttributes)
                .build();

        sqs.sendMessage(sendMessageRequest);
    }
}
