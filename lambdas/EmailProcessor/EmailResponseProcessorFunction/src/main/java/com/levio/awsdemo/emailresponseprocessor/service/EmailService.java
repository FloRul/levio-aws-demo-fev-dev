package com.levio.awsdemo.emailresponseprocessor.service;

import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.sesv2.SesV2Client;
import software.amazon.awssdk.services.sesv2.model.Body;
import software.amazon.awssdk.services.sesv2.model.Content;
import software.amazon.awssdk.services.sesv2.model.Destination;
import software.amazon.awssdk.services.sesv2.model.EmailContent;
import software.amazon.awssdk.services.sesv2.model.Message;
import software.amazon.awssdk.services.sesv2.model.SendEmailRequest;
import software.amazon.awssdk.services.sesv2.model.SesV2Exception;


public class EmailService {

    private static final String SENDER_EMAIL = System.getenv("SENDER_EMAIL");

    private final SesV2Client sesv2Client = SesV2Client.builder()
            .region(Region.US_EAST_1)
            .build();

    public void send(String message, String recipient, String subject) {
        Content content = Content.builder()
                .data(message)
                .build();

        Destination destination = Destination.builder()
                .toAddresses(recipient)
                .build();

        Content sub = Content.builder()
                .data(subject)
                .build();

        Body body = Body.builder()
                .html(content)
                .build();

        Message msg = Message.builder()
                .subject(sub)
                .body(body)
                .build();

        EmailContent emailContent = EmailContent.builder()
                .simple(msg)
                .build();

        SendEmailRequest emailRequest = SendEmailRequest.builder()
                .destination(destination)
                .content(emailContent)
                .fromEmailAddress(SENDER_EMAIL)
                .build();

        try {
            System.out.println("Attempting to send an email through Amazon SES");
            sesv2Client.sendEmail(emailRequest);
            System.out.println("Email was sent");
        } catch (SesV2Exception e) {
            System.err.println(e.awsErrorDetails().errorMessage());
            throw e;
        }
    }
}
