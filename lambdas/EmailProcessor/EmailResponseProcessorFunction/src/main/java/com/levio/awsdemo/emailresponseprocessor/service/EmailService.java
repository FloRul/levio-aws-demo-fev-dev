package com.levio.awsdemo.emailresponseprocessor.service;

import jakarta.activation.DataHandler;
import jakarta.activation.DataSource;
import jakarta.mail.Message;
import jakarta.mail.MessagingException;
import jakarta.mail.Session;
import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeBodyPart;
import jakarta.mail.internet.MimeMessage;
import jakarta.mail.internet.MimeMultipart;
import jakarta.mail.util.ByteArrayDataSource;
import lombok.RequiredArgsConstructor;
import software.amazon.awssdk.core.SdkBytes;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.sesv2.SesV2Client;
import software.amazon.awssdk.services.sesv2.model.Destination;
import software.amazon.awssdk.services.sesv2.model.EmailContent;
import software.amazon.awssdk.services.sesv2.model.RawMessage;
import software.amazon.awssdk.services.sesv2.model.SendEmailRequest;
import software.amazon.awssdk.services.sesv2.model.SesV2Exception;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.ByteBuffer;
import java.util.List;
import java.util.Properties;

@RequiredArgsConstructor
public class EmailService {

    private static final String SENDER_EMAIL = System.getenv("SENDER_EMAIL");

    private final SesV2Client sesv2Client = SesV2Client.builder()
            .region(Region.US_EAST_1)
            .build();

    private final S3Service s3Service;

    public void send(String message, String recipient, String subject, List<String> attachments) throws MessagingException, IOException {
        Session session = Session.getDefaultInstance(new Properties());

        MimeMessage mimeMessage = new MimeMessage(session);

        mimeMessage.setSubject(subject, "UTF-8");
        mimeMessage.setFrom(new InternetAddress(SENDER_EMAIL));
        mimeMessage.setRecipients(Message.RecipientType.TO, InternetAddress.parse(recipient));

        MimeMultipart messageBody = new MimeMultipart("alternative");

        MimeBodyPart wrap = new MimeBodyPart();

        MimeBodyPart bodyPart = new MimeBodyPart();
        bodyPart.setContent(message, "text/html; charset=UTF-8");

        messageBody.addBodyPart(bodyPart);

        wrap.setContent(messageBody);

        MimeMultipart mimeMultipart = new MimeMultipart("mixed");

        mimeMultipart.addBodyPart(wrap);

        for (String attachment : attachments) {
            MimeBodyPart att = new MimeBodyPart();

            InputStream inputStream = s3Service.getFile(attachment);
            byte[] byteArray = inputStream.readAllBytes();

            DataSource dataSource = new ByteArrayDataSource(byteArray, "application/octet-stream");
            att.setDataHandler(new DataHandler(dataSource));
            att.setFileName(extractFilename(attachment));

            mimeMultipart.addBodyPart(att);
        }

        mimeMessage.setContent(mimeMultipart);

        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        mimeMessage.writeTo(outputStream);

        RawMessage rawMsg = RawMessage.builder()
                .data(SdkBytes.fromByteBuffer(ByteBuffer.wrap(outputStream.toByteArray())))
                .build();

        Destination destination = Destination.builder()
                .toAddresses(recipient)
                .build();

        EmailContent emailContent = EmailContent.builder()
                .raw(rawMsg)
                .build();

        SendEmailRequest emailRequest = SendEmailRequest.builder()
                .destination(destination)
                .content(emailContent)
                .fromEmailAddress(SENDER_EMAIL)
                .build();

        try {
            System.out.println("Attempting to send an email through Amazon SES");
            sesv2Client.sendEmail(emailRequest);
            System.out.println("Email was sent");
        } catch (SesV2Exception e) {
            System.err.println(e.awsErrorDetails().errorMessage());
            throw e;
        }
    }

    private String extractFilename(String attachment) {
        String[] parts = attachment.split("/");
        return parts[parts.length - 1];
    }
}