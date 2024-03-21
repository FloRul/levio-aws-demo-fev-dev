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
        String masterPrompt = input.getOrDefault("master_prompt", null);
        String prompt = input.getOrDefault("prompt", null);
        String text = input.getOrDefault("text", null);

        return bedrockService.getClaudeResponse(masterPrompt, prompt, text);
    }

}
