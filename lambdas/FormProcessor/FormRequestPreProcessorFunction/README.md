# FormRequestPreProcessorFunction 
This lambda reacts to S3EventNotification, extracts the email ID and the object key of the form to be filled and emits an SQS notifcation.

## Input
S3EventNotification

## Output
SQS notifcation:
```
# Message body
{emailId: ..., formKey: ..., formS3URI: ...}
```

## Environment Variables
- FORM_S3_KEY: s3 object key of the form to be filled