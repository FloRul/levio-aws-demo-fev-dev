package com.levio.awsdemo.resume.service;

import org.json.JSONArray;
import org.json.JSONObject;
import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider;
import software.amazon.awssdk.core.SdkBytes;
import software.amazon.awssdk.http.SdkHttpClient;
import software.amazon.awssdk.http.apache.ApacheHttpClient;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.bedrockruntime.BedrockRuntimeClient;
import software.amazon.awssdk.services.bedrockruntime.model.InvokeModelRequest;
import software.amazon.awssdk.services.bedrockruntime.model.InvokeModelResponse;
import software.amazon.awssdk.services.bedrockruntime.model.ThrottlingException;

import java.time.Duration;

public class BedrockService {

    private final SdkHttpClient httpClient = ApacheHttpClient.builder()
            .connectionTimeout(Duration.ofMinutes(5))
            .socketTimeout(Duration.ofMinutes(5))
            .build();
    private final BedrockRuntimeClient client = BedrockRuntimeClient.builder()
            .region(Region.US_EAST_1)
            .credentialsProvider(DefaultCredentialsProvider.create())
            .httpClient(httpClient)
            .build();

    private static final String PROMPT = System.getenv("PROMPT");

    public String getClaudeResponse(String masterPrompt, String prompt, String text) {
        JSONObject content = new JSONObject()
                .put("type", "text")
                .put("text", retrievePrompt(prompt, text));

        JSONObject message = new JSONObject()
                .put("role", "user")
                .put("content", new JSONArray().put(content));

        JSONObject payload = new JSONObject()
                .put("anthropic_version", "bedrock-2023-05-31")
                .put("max_tokens", 4096)
                .put("system", masterPrompt != null ? masterPrompt : prompt != null ? prompt : PROMPT)
                .put("messages", new JSONArray().put(message));

        System.out.println("Payload: " + payload);

        InvokeModelRequest request = InvokeModelRequest.builder()
                .body(SdkBytes.fromUtf8String(payload.toString()))
                .modelId("anthropic.claude-3-sonnet-20240229-v1:0")
                .contentType("application/json")
                .accept("application/json")
                .build();

        System.out.println("Request: " + request);

        String response = null;
        boolean success = false;
        while (!success) {
            try {
                InvokeModelResponse invokeModelResponse = client.invokeModel(request);

                JSONObject responseBody = new JSONObject(invokeModelResponse.body().asUtf8String());

                System.out.println("Response: " + responseBody);

                response = responseBody.getJSONArray("content").getJSONObject(0).getString("text");
                success = true;
            } catch (ThrottlingException e) {
                System.out.println("Too many requests, waiting 30 seconds before retrying...");
                try {
                    Thread.sleep(30000);
                } catch (InterruptedException ie) {
                    Thread.currentThread().interrupt();
                    throw new RuntimeException("Thread interrupted while waiting to retry", ie);
                }
            } catch (Exception e) {
                throw new RuntimeException("An unexpected error occurred", e);
            }
        }
        return response;
    }

    private String retrievePrompt(String prompt, String text) {
        String document = "";
        if (text != null) {
            document = "<document>" + text + "</document>";
        }

        if (prompt != null) {
            return prompt + document;
        }
        return PROMPT;
    }
}
