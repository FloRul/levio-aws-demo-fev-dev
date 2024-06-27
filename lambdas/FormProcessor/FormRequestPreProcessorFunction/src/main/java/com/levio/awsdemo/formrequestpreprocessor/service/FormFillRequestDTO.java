package com.levio.awsdemo.formrequestpreprocessor.service;

public class FormFillRequestDTO {
    /**
     * The ID of the email which initiated the request
     */
    String emailId;

    /**
     * The key to the form to be filled
     */
    String formKey;

    /**
     * The key to the attachment to parse
     */
    String formS3URI;

    public FormFillRequestDTO(String emailId, String formKey, String formS3ObjectKey) {
        this.emailId = emailId;
        this.formKey = formKey;
        this.formS3URI = formS3ObjectKey;
    }

    public String toJson() {
        return "{" +
                "\"emailId\":\"" + emailId + "\"," +
                "\"formKey\":\"" + formKey + "\"," +
                "\"formS3URI\":\"" + formS3URI + "\"" +
                "}";
    }
}
