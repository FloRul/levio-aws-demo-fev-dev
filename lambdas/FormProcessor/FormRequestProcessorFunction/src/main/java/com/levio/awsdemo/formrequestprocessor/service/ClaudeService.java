package com.levio.awsdemo.formrequestprocessor.service;

import lombok.RequiredArgsConstructor;
import org.json.JSONObject;

@RequiredArgsConstructor
public class ClaudeService {
    private static final String FUNCTION_NAME = System.getenv("FUNCTION_NAME");
    private static final String MASTER_PROMPT = System.getenv("MASTER_PROMPT");

    private final LambdaService lambdaService;

    public String getResponse(String question, String content, String prompt) {
        JSONObject payload = new JSONObject()
                .put("master_prompt", prompt != null ? prompt : MASTER_PROMPT)
                .put("prompt", question)
                .put("text", content);

        return lambdaService.invoke(FUNCTION_NAME, payload.toString());
    }
}
