package com.levio.awsdemo.transcription.service;

import com.amazonaws.services.lambda.runtime.events.models.s3.S3EventNotification;
import software.amazon.awssdk.auth.credentials.AwsCredentialsProvider;
import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.transcribe.TranscribeClient;
import software.amazon.awssdk.services.transcribe.model.GetTranscriptionJobRequest;
import software.amazon.awssdk.services.transcribe.model.GetTranscriptionJobResponse;
import software.amazon.awssdk.services.transcribe.model.JobExecutionSettings;
import software.amazon.awssdk.services.transcribe.model.LanguageCode;
import software.amazon.awssdk.services.transcribe.model.Media;
import software.amazon.awssdk.services.transcribe.model.Settings;
import software.amazon.awssdk.services.transcribe.model.StartTranscriptionJobRequest;
import software.amazon.awssdk.services.transcribe.model.StartTranscriptionJobResponse;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class TranscribeService {

    private final String DATA_ACCESS_ROLE_ARN = System.getenv("DATA_ACCESS_ROLE_ARN");
    private final TranscribeClient client = TranscribeClient.builder()
            .credentialsProvider(getCredentials())
            .region(Region.US_EAST_1)
            .build();

    public void transcribe(S3EventNotification.S3Entity s3) {
        String filename = retrieveFileName(s3.getObject().getKey());
        System.out.println(filename);
        String transcriptionJobName = filename + "-transcription-job";
        String mediaType = retrieveExtension(s3.getObject().getKey());
        String s3FileUrl = "s3://" + s3.getBucket().getName() + "/" + s3.getObject().getKey();
        System.out.println(s3FileUrl);
        Media myMedia = Media.builder()
                .mediaFileUri(s3FileUrl)
                .build();

        StartTranscriptionJobRequest request = StartTranscriptionJobRequest.builder()
                .transcriptionJobName(transcriptionJobName)
                .identifyLanguage(true)
                .languageOptions(LanguageCode.EN_US, LanguageCode.FR_CA)
                .mediaFormat(mediaType)
                .media(myMedia)
                .outputBucketName(s3.getBucket().getName())
                .outputKey("resume/transcription/" + filename + ".json")
                .settings(Settings.builder()
                        .showSpeakerLabels(true)
                        .maxSpeakerLabels(3)
                        .build())
                .jobExecutionSettings(JobExecutionSettings.builder()
                        .allowDeferredExecution(true)
                        .dataAccessRoleArn(DATA_ACCESS_ROLE_ARN)
                        .build())
                .build();

        System.out.println(request);

        StartTranscriptionJobResponse startJobResponse = client.startTranscriptionJob(request);

        System.out.println("Start job response - Transcription job");
        System.out.println(startJobResponse.transcriptionJob());

        GetTranscriptionJobRequest getJobRequest = GetTranscriptionJobRequest.builder()
                .transcriptionJobName(transcriptionJobName)
                .build();

        GetTranscriptionJobResponse getJobResponse = client.getTranscriptionJob(getJobRequest);

        System.out.println("Get job response - Transcription job");
        System.out.println(getJobResponse.transcriptionJob());
    }

    private String retrieveFileName(String key) {
        Pattern pattern = Pattern.compile(".*/(.*?)\\..*");
        Matcher matcher = pattern.matcher(key);
        if (matcher.find()) {
            return matcher.group(1);
        }
        return null;
    }

    private String retrieveExtension(String key) {
        Pattern pattern = Pattern.compile("\\.([^.]+)$");
        Matcher matcher = pattern.matcher(key);
        if (matcher.find()) {
            return matcher.group(1);
        }
        return null;
    }

    private static AwsCredentialsProvider getCredentials() {
        return DefaultCredentialsProvider.create();
    }
}
