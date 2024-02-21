package com.levio.awsdemo.emailrequestprocessor.service;

import com.levio.awsdemo.emailrequestprocessor.client.SaasClient;
import lombok.RequiredArgsConstructor;

import java.io.IOException;

@RequiredArgsConstructor
public class SaasService {
    private final SaasClient saasClient;

    public String getInference(String message) throws IOException {
        return saasClient.getInference(message);
    }
}
