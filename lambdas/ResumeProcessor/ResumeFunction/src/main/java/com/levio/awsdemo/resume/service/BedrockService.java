package com.levio.awsdemo.resume.service;

import org.json.JSONArray;
import org.json.JSONObject;
import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider;
import software.amazon.awssdk.core.SdkBytes;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.bedrockruntime.BedrockRuntimeClient;
import software.amazon.awssdk.services.bedrockruntime.model.InvokeModelRequest;
import software.amazon.awssdk.services.bedrockruntime.model.InvokeModelResponse;

public class BedrockService {

    private final BedrockRuntimeClient client = BedrockRuntimeClient.builder()
            .region(Region.US_EAST_1)
            .credentialsProvider(DefaultCredentialsProvider.create())
            .build();

    private static final String PROMPT = System.getenv("PROMPT");

    public String getClaudeResponse(String prompt, String text) {
        JSONObject content = new JSONObject()
                .put("type", "text")
                .put("text", text);

        JSONObject message = new JSONObject()
                .put("role", "user")
                .put("content", new JSONArray().put(content));

        JSONObject payload = new JSONObject()
                .put("anthropic_version", "bedrock-2023-05-31")
                .put("max_tokens", 4096)
                .put("system", prompt != null ? prompt : PROMPT)
                .put("messages", new JSONArray().put(message));

        System.out.println("Payload: " + payload);

        InvokeModelRequest request = InvokeModelRequest.builder()
                .body(SdkBytes.fromUtf8String(payload.toString()))
                .modelId("anthropic.claude-3-sonnet-20240229-v1:0")
                .contentType("application/json")
                .accept("application/json")
                .build();

        System.out.println("Request: " + request);

        InvokeModelResponse response = client.invokeModel(request);

        JSONObject responseBody = new JSONObject(response.body().asUtf8String());

        System.out.println("Response: " + response.body().asUtf8String());

        return responseBody
                .getJSONArray("content").getJSONObject(0).getString("text");
    }
}
