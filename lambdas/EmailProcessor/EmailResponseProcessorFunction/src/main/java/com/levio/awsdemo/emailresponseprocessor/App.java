package com.levio.awsdemo.emailresponseprocessor;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.SQSEvent;
import com.levio.awsdemo.emailresponseprocessor.service.EmailService;
import com.levio.awsdemo.emailresponseprocessor.service.S3Service;

import java.util.ArrayList;
import java.util.List;

public class App implements RequestHandler<SQSEvent, Void> {

    private final EmailService emailService;

    public App() {
        this.emailService = new EmailService(new S3Service());
    }

    public App(EmailService emailService) {
        this.emailService = emailService;
    }

    @Override
    public Void handleRequest(SQSEvent event, Context context) {

        event.getRecords().forEach(record -> {
            System.out.println("Record: " + record);
            String message = record.getBody();
            SQSEvent.MessageAttribute sender = record.getMessageAttributes().get("sender");
            SQSEvent.MessageAttribute subject = record.getMessageAttributes().get("subject");

            List<String> attachments = new ArrayList<>();
            record.getMessageAttributes().forEach((key, value) -> {
                if (key.startsWith("attachment")) {
                    attachments.add(value.getStringValue());
                }
            });

            if (!message.isEmpty() && sender != null && subject != null) {
                try {
                    emailService.send(message, sender.getStringValue(), subject.getStringValue(), attachments);
                } catch (Exception e) {
                    throw new RuntimeException(e);
                }
            }
        });

        return null;
    }
}
