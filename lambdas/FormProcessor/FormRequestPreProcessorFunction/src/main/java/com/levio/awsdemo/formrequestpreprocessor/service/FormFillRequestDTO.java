package com.levio.awsdemo.formrequestpreprocessor.service;

public class FormFillRequestDTO {
    String emailId;
    String formKey;


    public FormFillRequestDTO(String emailId, String formKey) {
        this.emailId = emailId;
        this.formKey = formKey;
    }

    public String toJson() {
        return "{" +
                "\"emailId\":\"" + emailId + "\"," +
                "\"formKey\":\"" + formKey + "\"" +
                "}";
    }
}
