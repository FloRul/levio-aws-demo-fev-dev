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
    String attachmentKey;

    public FormFillRequestDTO(String emailId, String formKey, String attachmentKey) {
        this.emailId = emailId;
        this.formKey = formKey;
        this.attachmentKey = attachmentKey;
    }

    public String toJson() {
        return "{" +
                "\"emailId\":\"" + emailId + "\"," +
                "\"formKey\":\"" + formKey + "\"," +
                "\"attachmentKey\":\"" + attachmentKey + "\"" +
                "}";
    }
}
