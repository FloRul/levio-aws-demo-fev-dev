# FormRequestProcessorFunction 
This lambda reacts to SQSEvent, retrieves the form to be filled and the prompts contained inside of it, fill the form using claude and emits an event when done

## Input
SQSEvent: [FormFillRequest](src/main/java/com/levio/awsdemo/formrequestprocessor/service/FormFillRequestDTO.java)

## Output
SQSEvent

## Environment Variables
- FUNCTION_NAME: the name of the lambda which will be called to invoke claude
- MASTER_PROMPT: the "system prompt" to give context to the interaction with claude
- BUCKET_NAME: the bucket to retrieve the form to fill fro
- QUEUE_URL: the queue to produce events to