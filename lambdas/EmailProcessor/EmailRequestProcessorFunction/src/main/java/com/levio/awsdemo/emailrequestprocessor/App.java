package com.levio.awsdemo.emailrequestprocessor;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.SQSEvent;
import com.levio.awsdemo.emailrequestprocessor.client.SaasClient;
import com.levio.awsdemo.emailrequestprocessor.service.SaasService;
import com.levio.awsdemo.emailrequestprocessor.service.SqsProducerService;

import java.io.IOException;

public class App implements RequestHandler<SQSEvent, Void> {

    private final SaasService saasService;
    private final SqsProducerService sqsProducerService;

    public App() {
        this.saasService = new SaasService(new SaasClient());
        this.sqsProducerService = new SqsProducerService();
    }

    public App(SaasService saasService, SqsProducerService sqsProducerService) {
        this.saasService = saasService;
        this.sqsProducerService = sqsProducerService;
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
                    String response = saasService.getInference(message);
                    System.out.println("Response: " + response);
                    sqsProducerService.send(response, record.getMessageAttributes(), record.getMessageId());
                } catch (IOException e) {
                    throw new RuntimeException(e);
                }
            }
        });

        return null;
    }
}
