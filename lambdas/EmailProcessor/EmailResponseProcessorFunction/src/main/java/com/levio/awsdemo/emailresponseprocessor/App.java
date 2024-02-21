package com.levio.awsdemo.emailresponseprocessor;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.SQSEvent;
import com.levio.awsdemo.emailresponseprocessor.service.EmailService;

import java.io.IOException;

public class App implements RequestHandler<SQSEvent, Void> {

    private final EmailService emailService;

    public App() {
        this.emailService = new EmailService();
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

            if (!message.isEmpty() && sender != null && subject != null) {
                try {
                    emailService.send(message, sender.getStringValue(), subject.getStringValue());
                } catch (Exception e) {
                    throw new RuntimeException(e);
                }
            }
        });

        return null;
    }
}
