FROM public.ecr.aws/lambda/python:3.11

# Copy requirements.txt
COPY requirements.txt ${LAMBDA_TASK_ROOT}

# Install the specified packages
# tabula-py has a dependency on java
RUN yum -y install java-17-amazon-corretto-headless && pip install -r requirements.txt 

# Copy function code
COPY index.py ${LAMBDA_TASK_ROOT}

# Set the CMD to your handler (could also be done as a parameter override outside of the Dockerfile)
CMD [ "index.lambda_handler" ]