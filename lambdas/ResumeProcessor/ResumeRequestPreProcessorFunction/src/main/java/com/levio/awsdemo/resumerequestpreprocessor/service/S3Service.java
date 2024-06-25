package com.levio.awsdemo.resumerequestpreprocessor.service;

import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.HeadObjectRequest;
import software.amazon.awssdk.services.s3.model.HeadObjectResponse;

public class S3Service {

    private static final String BUCKET_NAME = System.getenv("BUCKET_NAME");

    private final S3Client s3 = S3Client.builder()
            .region(Region.US_EAST_1)
            .build();

    public String getEmailMetadata(String key) {
        HeadObjectRequest objectRequest = HeadObjectRequest
                .builder()
                .key(key)
                .bucket(BUCKET_NAME)
                .build();
        HeadObjectResponse objectHead = s3.headObject(objectRequest);

        return objectHead.metadata().get("email");
    }

}
