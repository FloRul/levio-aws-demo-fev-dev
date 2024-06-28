package com.levio.awsdemo.formrequestprocessor.service;


import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class FormFillRequestDTO {
    @JsonProperty("emailId")
    private String emailId;

    @JsonProperty("emailS3URI")
    private String emailS3URI;

    @JsonProperty("emailAttachmentS3URI")
    private String emailAttachmentS3URI;

}
