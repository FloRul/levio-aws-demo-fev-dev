package com.levio.awsdemo.formrequestprocessor;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.SQSEvent;
import com.levio.awsdemo.formrequestprocessor.service.ClaudeService;
import com.levio.awsdemo.formrequestprocessor.service.DocumentService;
import com.levio.awsdemo.formrequestprocessor.service.LambdaService;
import com.levio.awsdemo.formrequestprocessor.service.S3Service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.HashMap;
import java.util.Map;

public class App implements RequestHandler<SQSEvent, Void> {

    private final DocumentService documentService;

    private final ClaudeService claudeService;

    private final S3Service s3Service;

    private final HashMap<Integer, Map<String, String>> questionsMapper;

    public App() {
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
               ClaudeService claudeService,
               HashMap<Integer, Map<String, String>> questionsMapper) {
        this.s3Service = s3Service;
        this.documentService = documentService;
        this.claudeService = claudeService;
        this.questionsMapper = questionsMapper;
    }

    public Void handleRequest(final SQSEvent input, final Context context) {
        input.getRecords().forEach(record -> {
            System.out.println("Record: " + record);

            String keyId = record.getBody();

            InputStream fileInputStream = s3Service.getFile("formulaire/attachment/" + keyId + ".txt");
            try {
                byte[] fileByteArray = fileInputStream.readAllBytes();
                String content = new String(fileByteArray);
                questionsMapper.forEach((filePosition, questionAnswerMap) -> {
                    String answer = claudeService.getResponse(questionAnswerMap.get("question"), content);
                    questionAnswerMap.put("answer", answer);
                });
                ByteArrayOutputStream fileOutputStream = documentService.fillFile(questionsMapper);
                s3Service.saveFile("formulaire/" + keyId + ".docx", fileOutputStream.toByteArray());
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
        });
        return null;
    }
}
