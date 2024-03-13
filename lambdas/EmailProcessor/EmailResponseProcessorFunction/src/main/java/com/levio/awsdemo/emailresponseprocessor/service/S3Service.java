package com.levio.awsdemo.emailresponseprocessor.service;

import software.amazon.awssdk.core.ResponseBytes;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectResponse;

import java.io.InputStream;

public class S3Service {

    private final S3Client s3 = S3Client.builder()
            .region(Region.US_EAST_1)
            .build();

    public InputStream getFile(String uri) {
        GetObjectRequest objectRequest = GetObjectRequest
                .builder()
                .key(extractKey(uri))
                .bucket(extractBucket(uri))
                .build();

        ResponseBytes<GetObjectResponse> objectBytes = s3.getObjectAsBytes(objectRequest);
        return objectBytes.asInputStream();
    }

    private String extractBucket(String uri) {
        int endIndex = uri.indexOf("/", 5);
        return uri.substring(5, endIndex);
    }

    private String extractKey(String uri) {
        int startIndex = uri.indexOf("/", 5);
        return uri.substring(startIndex + 1);
    }

}
