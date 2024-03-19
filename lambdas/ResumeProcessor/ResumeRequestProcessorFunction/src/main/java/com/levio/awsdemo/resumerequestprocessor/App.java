package com.levio.awsdemo.resumerequestprocessor;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.SQSEvent;
import com.levio.awsdemo.resumerequestprocessor.service.ClaudeService;
import com.levio.awsdemo.resumerequestprocessor.service.LambdaService;
import com.levio.awsdemo.resumerequestprocessor.service.MailService;
import com.levio.awsdemo.resumerequestprocessor.service.S3Service;
import com.levio.awsdemo.resumerequestprocessor.service.SqsProducerService;
import com.levio.awsdemo.resumerequestprocessor.util.EmailUtils;
import jakarta.mail.MessagingException;
import jakarta.mail.Part;
import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeMessage;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class App implements RequestHandler<SQSEvent, Void> {
    private final S3Service s3Service;

    private final ClaudeService claudeService;

    private final SqsProducerService sqsProducerService;

    private final MailService mailService;

    public App() {
        this.s3Service = new S3Service();
        this.claudeService = new ClaudeService(new LambdaService());
        this.sqsProducerService = new SqsProducerService();
        this.mailService = new MailService();
    }

    public App(S3Service s3Service, ClaudeService claudeService, SqsProducerService sqsProducerService, MailService mailService) {
        this.s3Service = s3Service;
        this.claudeService = claudeService;
        this.sqsProducerService = sqsProducerService;
        this.mailService = mailService;
    }

    public Void handleRequest(final SQSEvent input, final Context context) {
        input.getRecords().forEach(record -> {
            System.out.println("Record: " + record);

            String keyId = record.getBody();

            String email = s3Service.getFile("resume/email/" + keyId);
            try {
                MimeMessage message = mailService.getMimeMessage(new ByteArrayInputStream(email.getBytes(StandardCharsets.UTF_8)));
                String emailBody = "Resume response";
                String sender = ((InternetAddress) message.getFrom()[0]).getAddress();
                String subject = message.getSubject();

                List<Part> attachments = EmailUtils.extractAttachments(message);
                String attachmentFilename = attachments.get(0).getFileName();

                String transcription = s3Service.getFile("resume/transcription/" + keyId + ".txt");

                String dialogue = claudeService.getDialogue(transcription);
                String filename = extractFileName(attachmentFilename) + "-" + keyId;
                String dialogueTxtUri = s3Service.saveFile("resume/dialogue/" + filename + ".txt", dialogue.getBytes());
                String resume = claudeService.getResume(dialogue);
                String resumeTxtUri = s3Service.saveFile("resume/" + filename + ".txt", resume.getBytes());

                sqsProducerService.send(emailBody, getMessageAttributes(sender, subject, dialogueTxtUri, resumeTxtUri), keyId);
            } catch (MessagingException | IOException e) {
                throw new RuntimeException(e);
            }
        });

        return null;
    }

    private String extractFileName(String fileName) {
        return fileName.substring(0, fileName.lastIndexOf("."));
    }

    private static Map<String, SQSEvent.MessageAttribute> getMessageAttributes(String sender, String subject, String... attachmentsUri) {
        Map<String, SQSEvent.MessageAttribute> messageAttributes = new HashMap<>();

        SQSEvent.MessageAttribute senderAttribute = new SQSEvent.MessageAttribute();
        senderAttribute.setStringValue(sender);
        senderAttribute.setDataType("String");
        messageAttributes.put("sender", senderAttribute);

        SQSEvent.MessageAttribute subjectAttribute = new SQSEvent.MessageAttribute();
        subjectAttribute.setStringValue(subject);
        subjectAttribute.setDataType("String");
        messageAttributes.put("subject", subjectAttribute);

        for (int i = 0; i < attachmentsUri.length; i++) {
            SQSEvent.MessageAttribute attachmentAttribute = new SQSEvent.MessageAttribute();
            attachmentAttribute.setStringValue(attachmentsUri[i]);
            attachmentAttribute.setDataType("String");
            messageAttributes.put("attachment" + i, attachmentAttribute);
        }

        return messageAttributes;
    }
}
