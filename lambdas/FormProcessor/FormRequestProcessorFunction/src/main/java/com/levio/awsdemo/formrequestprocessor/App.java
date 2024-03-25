package com.levio.awsdemo.formrequestprocessor;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.SQSEvent;
import com.levio.awsdemo.formrequestprocessor.service.ClaudeService;
import com.levio.awsdemo.formrequestprocessor.service.DocumentService;
import com.levio.awsdemo.formrequestprocessor.service.LambdaService;
import com.levio.awsdemo.formrequestprocessor.service.MailService;
import com.levio.awsdemo.formrequestprocessor.service.S3Service;
import com.levio.awsdemo.formrequestprocessor.service.SqsProducerService;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeMessage;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

public class App implements RequestHandler<SQSEvent, Void> {

    private final DocumentService documentService;

    private final ClaudeService claudeService;

    private final S3Service s3Service;

    private final SqsProducerService sqsProducerService;

    private final MailService mailService;

    private final HashMap<Integer, Map<String, String>> questionsMapper;

    public App() {
        this.mailService = new MailService();
        this.sqsProducerService = new SqsProducerService();
        this.s3Service = new S3Service();
        this.documentService = new DocumentService(s3Service);
        this.claudeService = new ClaudeService(new LambdaService());
        try {
            this.questionsMapper = documentService.retrieveQuestionsMapper();
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    public App(S3Service s3Service,
               DocumentService documentService,
               ClaudeService claudeService, SqsProducerService sqsProducerService, MailService mailService,
               HashMap<Integer, Map<String, String>> questionsMapper) {
        this.s3Service = s3Service;
        this.documentService = documentService;
        this.claudeService = claudeService;
        this.sqsProducerService = sqsProducerService;
        this.mailService = mailService;
        this.questionsMapper = questionsMapper;
    }

    public Void handleRequest(final SQSEvent input, final Context context) {
        input.getRecords().forEach(record -> {
            System.out.println("Record: " + record);

            String keyId = record.getBody();

            String email = s3Service.getFile("formulaire/email/" + keyId);
            try {
                MimeMessage message = mailService.getMimeMessage(new ByteArrayInputStream(email.getBytes(StandardCharsets.UTF_8)));
                String emailBody = "Formulaire response";
                String sender = ((InternetAddress) message.getFrom()[0]).getAddress();
                String subject = message.getSubject();

                String content = s3Service.getFile("formulaire/attachment/" + keyId + ".txt");
                questionsMapper.entrySet().parallelStream()
                        .forEach(positionQuestionAnswerMapper -> {
                            Map<String, String> questionAnswerMap = positionQuestionAnswerMapper.getValue();
                            String answer = claudeService.getResponse(questionAnswerMap.get("question"), content);
                            questionAnswerMap.put("answer", answer);
                        });
                ByteArrayOutputStream fileOutputStream = documentService.fillFile(questionsMapper);
                String formDocxUri = s3Service.saveFile("formulaire/" + keyId + ".docx", fileOutputStream.toByteArray());
                sqsProducerService.send(emailBody, getMessageAttributes(sender, subject, formDocxUri), keyId);
            } catch (IOException | MessagingException e) {
                throw new RuntimeException(e);
            }
        });
        return null;
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
