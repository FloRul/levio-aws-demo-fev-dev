FROM public.ecr.aws/lambda/python:3.11

COPY requirements.txt ${LAMBDA_TASK_ROOT}
COPY index.py ${LAMBDA_TASK_ROOT}

# tabula-py has a dependency on java
RUN yum -y install java-17-amazon-corretto-headless
RUN pip install -r requirements.txt 

CMD [ "index.lambda_handler" ]