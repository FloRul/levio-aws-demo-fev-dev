package com.levio.awsdemo.formrequestprocessor.service;


import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class FormFillRequestDTO {
    @JsonProperty("emailId") // Map JSON property to field
    private String emailId;

    @JsonProperty("formKey") // Map JSON property to field
    private String formKey;

    @JsonProperty("formS3URI")
    private String formS3URI;
}
