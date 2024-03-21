package com.levio.awsdemo.formrequestprocessor.service;

import software.amazon.awssdk.core.SdkBytes;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.lambda.LambdaClient;
import software.amazon.awssdk.services.lambda.model.InvokeRequest;
import software.amazon.awssdk.services.lambda.model.InvokeResponse;

public class LambdaService {
    private final LambdaClient lambda = LambdaClient.builder()
            .region(Region.US_EAST_1)
            .build();

    public String invoke(String functionName, String payload) {
        InvokeRequest invokeRequest = InvokeRequest.builder()
                .functionName(functionName)
                .payload(SdkBytes.fromUtf8String(payload))
                .build();

        InvokeResponse invokeResponse = lambda.invoke(invokeRequest);

        return invokeResponse.payload().asUtf8String();
    }
}
