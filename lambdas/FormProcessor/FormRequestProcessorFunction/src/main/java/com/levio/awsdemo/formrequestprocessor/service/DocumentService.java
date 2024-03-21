package com.levio.awsdemo.formrequestprocessor.service;

import lombok.RequiredArgsConstructor;
import org.apache.poi.xwpf.usermodel.XWPFDocument;
import org.apache.poi.xwpf.usermodel.XWPFParagraph;
import org.apache.poi.xwpf.usermodel.XWPFRun;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

@RequiredArgsConstructor
public class DocumentService {

    private final static String STANDARD_FORM_FILE_KEY = "formulaire/standard/formulaire.docx";

    private final S3Service s3Service;

    public HashMap<Integer, Map<String, String>> retrieveQuestionsMapper() throws IOException {
        HashMap<Integer, Map<String, String>> questionsMapper = new HashMap<>();

        InputStream fileInputStream = s3Service.getFile(STANDARD_FORM_FILE_KEY);
        try (XWPFDocument document = new XWPFDocument(fileInputStream)) {

            List<XWPFParagraph> paragraphs = document.getParagraphs();

            for (XWPFParagraph paragraph : paragraphs) {
                String text = paragraph.getText();

                if (text.startsWith("P :")) {
                    String question = text.substring("P :".length()).trim();
                    int position = document.getPosOfParagraph(paragraph);

                    HashMap<String, String> questionAnswer = new HashMap<>();
                    questionAnswer.put("question", question);

                    questionsMapper.put(position, questionAnswer);
                }
            }

        }
        return questionsMapper;
    }

    public ByteArrayOutputStream fillFile(HashMap<Integer, Map<String, String>> questionsMapper) throws IOException {
        InputStream fileInputStream = s3Service.getFile(STANDARD_FORM_FILE_KEY);
        try (XWPFDocument document = new XWPFDocument(fileInputStream)) {

            questionsMapper.entrySet().stream()
                    .sorted(Comparator.comparingInt(Map.Entry::getKey))
                    .forEach(positionQuestionAnswerMapper -> {
                        int filePosition = positionQuestionAnswerMapper.getKey();
                        Map<String, String> questionAnswerMap = positionQuestionAnswerMapper.getValue();

                        XWPFParagraph answerParagraph = document.getParagraphs().get(filePosition);
                        XWPFRun run = answerParagraph.createRun();
                        run.setText("A: " + questionAnswerMap.get("answer"));

//                        document.setParagraph(answerParagraph, filePosition + 1);
                    });
            ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
            document.write(outputStream);
            return outputStream;
        }
    }
}
