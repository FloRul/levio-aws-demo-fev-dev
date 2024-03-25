package com.levio.awsdemo.formrequestprocessor.service;

import software.amazon.awssdk.core.ResponseBytes;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectResponse;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectResponse;

import java.io.InputStream;

public class S3Service {

    private static final String BUCKET_NAME = System.getenv("BUCKET_NAME");

    private final S3Client s3 = S3Client.builder()
            .region(Region.US_EAST_1)
            .build();
    public String getFile(String key) {
        ResponseBytes<GetObjectResponse> objectBytes = getObjectResponseBytes(key);
        return new String(objectBytes.asByteArray());
    }

    public InputStream getInputFileStream(String key) {
        ResponseBytes<GetObjectResponse> objectBytes = getObjectResponseBytes(key);
        return objectBytes.asInputStream();
    }

    private ResponseBytes<GetObjectResponse> getObjectResponseBytes(String key) {
        GetObjectRequest objectRequest = GetObjectRequest
                .builder()
                .key(key)
                .bucket(BUCKET_NAME)
                .build();

        return s3.getObjectAsBytes(objectRequest);
    }

    public String saveFile(String fileKey, byte[] fileContent) {
        PutObjectResponse objectResponse = s3.putObject(
                PutObjectRequest.builder()
                        .bucket(BUCKET_NAME)
                        .key(fileKey)
                        .build(),
                RequestBody.fromBytes(fileContent));
        if (objectResponse.sdkHttpResponse().isSuccessful()) {
            System.out.println("File " + fileKey + " created");
            return "s3://" + BUCKET_NAME + "/" + fileKey;
        }
        return null;
    }

}
