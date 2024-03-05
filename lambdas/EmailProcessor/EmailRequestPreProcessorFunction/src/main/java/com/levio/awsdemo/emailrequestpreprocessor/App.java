package com.levio.awsdemo.emailrequestpreprocessor;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.SQSEvent;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.levio.awsdemo.emailrequestpreprocessor.service.S3Service;
import com.levio.awsdemo.emailrequestpreprocessor.service.SqsProducerService;
import jakarta.mail.MessagingException;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

public class App implements RequestHandler<Map<Object, Object>, Void> {

    private static final String BUCKET_NAME = System.getenv("BUCKET_NAME");
    private static final String KEY_PREFIX = System.getenv("KEY_PREFIX");
    private final ObjectMapper objectMapper = new ObjectMapper();

    private final S3Service s3Service;

    private final SqsProducerService sqsProducerService;

    public App() {
        this.s3Service = new S3Service();
        this.sqsProducerService = new SqsProducerService();
    }

    public App(S3Service s3Service, SqsProducerService sqsProducerService) {
        this.s3Service = s3Service;
        this.sqsProducerService = sqsProducerService;
    }

    public Void handleRequest(final Map<Object, Object> input, final Context context) {
        try {
            String json = objectMapper.writeValueAsString(input);
            System.out.println(json);
        } catch (JsonProcessingException e) {
            throw new RuntimeException(e);
        }

        ArrayList<Object> records = (ArrayList<Object>) input.get("Records");

        Map<Object, Object> firstRecord = (Map<Object, Object>) records.get(0);

        Map<Object, Object> ses = (Map<Object, Object>) firstRecord.get("ses");

        Map<Object, Object> mail = (Map<Object, Object>) ses.get("mail");

        Map<Object, Object> commonHeaders = (Map<Object, Object>) mail.get("commonHeaders");

        String messageId = (String) mail.get("messageId");
        String sender = (String) mail.get("source");
        String subject = (String) commonHeaders.get("subject");

        String keyName = KEY_PREFIX.isEmpty() ? messageId : KEY_PREFIX + "/" + messageId;

        try {
            String emailBody = s3Service.getEmailBodyFromEmailObject(BUCKET_NAME, keyName);
            System.out.println("email body: " + emailBody);
            sqsProducerService.send(emailBody, getMessageAttributes(sender, subject), messageId);
        } catch (MessagingException | IOException e) {
            throw new RuntimeException(e);
        }
        return null;
    }

    private static Map<String, SQSEvent.MessageAttribute> getMessageAttributes(String sender, String subject) {
        Map<String, SQSEvent.MessageAttribute> messageAttributes = new HashMap<>();

        SQSEvent.MessageAttribute senderAttribute = new SQSEvent.MessageAttribute();
        senderAttribute.setStringValue(sender);
        senderAttribute.setDataType("String");
        messageAttributes.put("sender", senderAttribute);

        SQSEvent.MessageAttribute subjectAttribute = new SQSEvent.MessageAttribute();
        subjectAttribute.setStringValue(subject);
        subjectAttribute.setDataType("String");
        messageAttributes.put("subject", subjectAttribute);

        return messageAttributes;
    }

}
