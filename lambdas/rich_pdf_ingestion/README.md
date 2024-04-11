# lambdas/rich_pdf_ingestion 
This lambda reacts to an S3 put notifications and extracts text, tables and images from a PDF to make ingestion by a LLM easier

## Input
S3 notififcation

## Output
None

## Environment Variables
- S3_EXTRACTED_FILES_FOLDER_URI: S3 folder URI to upload extracted files to