package com.levio.awsdemo.resumerequestprocessor.service;

import com.amazonaws.services.lambda.runtime.events.SQSEvent;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.MessageAttributeValue;
import software.amazon.awssdk.services.sqs.model.SendMessageRequest;

import java.util.HashMap;
import java.util.Map;

public class SqsProducerService {
    private static final String QUEUE_URL = System.getenv("QUEUE_URL");
    private final SqsClient sqs = SqsClient.builder()
            .region(Region.US_EAST_1)
            .build();

    public void send(String message, Map<String, SQSEvent.MessageAttribute> messageAttributes, String messageId) {
        Map<String, MessageAttributeValue> messageAttributeValues = new HashMap<>();
        messageAttributes.forEach((key, value) -> {
            MessageAttributeValue mav = MessageAttributeValue.builder()
                    .stringValue(value.getStringValue())
                    .dataType(value.getDataType())
                    .build();
            messageAttributeValues.put(key, mav);
        });

        SendMessageRequest sendMessageRequest = SendMessageRequest.builder()
                .queueUrl(QUEUE_URL)
                .messageBody(message)
                .messageAttributes(messageAttributeValues)
                .messageGroupId(messageAttributes.get("sender").getStringValue())
                .messageDeduplicationId(messageId)
                .build();

        sqs.sendMessage(sendMessageRequest);
    }
}
