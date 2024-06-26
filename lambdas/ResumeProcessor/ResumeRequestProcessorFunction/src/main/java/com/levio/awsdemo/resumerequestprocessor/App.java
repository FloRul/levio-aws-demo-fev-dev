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

            String emailBody = "Resume response";

            String keyId = record.getBody();
            String transcription = s3Service.getFile("resume/transcription/" + keyId + ".txt");

            if (isUploadedFromSite(record)) {
                SQSEvent.MessageAttribute emailMessageAttribute = record.getMessageAttributes().get("Email");

                String sender = emailMessageAttribute.getStringValue();
                String subject = "Resume subject";

                processAndSendTranscriptionEmail(emailBody, keyId, transcription, sender, subject, keyId);
            } else {
                String email = s3Service.getFile("resume/email/" + keyId);
                try {
                    MimeMessage message = mailService.getMimeMessage(new ByteArrayInputStream(email.getBytes(StandardCharsets.UTF_8)));

                    String sender = ((InternetAddress) message.getFrom()[0]).getAddress();
                    String subject = message.getSubject();

                    List<Part> attachments = EmailUtils.extractAttachments(message);
                    String attachmentFilename = attachments.get(0).getFileName();

                    String filename = extractFileName(attachmentFilename) + "-" + keyId;
                    processAndSendTranscriptionEmail(emailBody, keyId, transcription, sender, subject, filename);
                } catch (MessagingException | IOException e) {
                    throw new RuntimeException(e);
                }
            }
        });

        return null;
    }

    private void processAndSendTranscriptionEmail(String emailBody, String keyId, String transcription, String sender, String subject, String filename) {
        String dialogueTxtUri = saveTranscriptionAsDialogue(transcription, filename);
        String resumeTxtUri = saveTranscriptionAsResume(transcription, filename);
        sendEmailWithAttachments(emailBody, sender, subject, dialogueTxtUri, resumeTxtUri, keyId);
    }

    private String saveTranscriptionAsDialogue(String transcription, String filename) {
        String fileKey = "resume/dialogue/" + "dialogue" + "-" + filename + ".txt";
        return s3Service.saveFile(fileKey, transcription.getBytes());
    }

    private String saveTranscriptionAsResume(String transcription, String filename) {
        String resume = claudeService.getResume(transcription);
        String resumeFileKey = "resume/" + "resume" + "-" + filename + ".txt";
        return s3Service.saveFile(resumeFileKey, resume.getBytes());
    }

    private void sendEmailWithAttachments(String emailBody, String sender, String subject, String dialogueTxtUri, String resumeTxtUri, String keyId) {
        sqsProducerService.send(emailBody, getMessageAttributes(sender, subject, dialogueTxtUri, resumeTxtUri), keyId);
    }

    private static boolean isUploadedFromSite(SQSEvent.SQSMessage record) {
        return record.getMessageAttributes().containsKey("Email");
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
