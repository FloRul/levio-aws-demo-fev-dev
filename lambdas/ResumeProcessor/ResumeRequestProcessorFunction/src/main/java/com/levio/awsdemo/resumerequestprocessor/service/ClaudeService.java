package com.levio.awsdemo.resumerequestprocessor.service;

import lombok.RequiredArgsConstructor;
import org.json.JSONObject;

@RequiredArgsConstructor
public class ClaudeService {
    private static final String FUNCTION_NAME = System.getenv("FUNCTION_NAME");
    private static final String DIALOGUE_PROMPT = System.getenv("DIALOGUE_PROMPT");
    private static final String RESUME_PROMPT = System.getenv("RESUME_PROMPT");

    private final LambdaService lambdaService;

    public String getDialogue(String transcription) {
        JSONObject payload = new JSONObject()
                .put("prompt", DIALOGUE_PROMPT)
                .put("text", transcription);

        return lambdaService.invoke(FUNCTION_NAME, payload.toString());
    }

    public String getResume(String dialogue) {
        JSONObject payload = new JSONObject()
                .put("prompt", RESUME_PROMPT)
                .put("text", dialogue);

        return lambdaService.invoke(FUNCTION_NAME, payload.toString());
    }
}
