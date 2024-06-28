package com.levio.awsdemo.formrequestpreprocessor.service;

public class FormFillRequestDTO {
    private final String emailId;

    private final String emailS3URI;

    private final String emailAttachmentS3URI;

    public FormFillRequestDTO(String emailId, String emailS3URI, String emailAttachmentS3URI) {
        this.emailId = emailId;
        this.emailS3URI = emailS3URI;
        this.emailAttachmentS3URI = emailAttachmentS3URI;
    }

    public String toJson() {
        return "{" +
                "\"emailId\":\"" + emailId + "\"," +
                "\"emailS3URI\":\"" + emailS3URI + "\"," +
                "\"emailAttachmentS3URI\":\"" + emailAttachmentS3URI + "\"" +
                "}";
    }
}
