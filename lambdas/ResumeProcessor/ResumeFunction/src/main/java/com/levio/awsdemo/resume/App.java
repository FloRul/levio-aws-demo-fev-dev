package com.levio.awsdemo.resume;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.levio.awsdemo.resume.service.BedrockService;

import java.util.Map;

public class App implements RequestHandler<Map<String, String>, String> {

    private final BedrockService bedrockService;

    public App() {
        this.bedrockService = new BedrockService();
    }

    public App(BedrockService bedrockService) {
        this.bedrockService = bedrockService;
    }

    public String handleRequest(final Map<String, String> input, final Context context) {
        String prompt = input.get("prompt");
        String text = input.get("text");

        return bedrockService.getClaudeResponse(prompt, text);
    }

}
